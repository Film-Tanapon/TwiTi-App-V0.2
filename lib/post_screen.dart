import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'drawer.dart';
import 'search_screen.dart';
import 'notification_screen.dart';
import 'chat_list_screen.dart';
import 'comment_screen.dart';

// ==========================================
// 1. PostScreen
// ==========================================
class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  int myUserId = 0;
  String myName = "Loading...";
  String myHandle = "...";
  String myEmail = "...";
  int myFollowing = 0;
  int myFollowers = 0;

  // 🔴 จุดที่แก้ 1: เพิ่มตัวแปรเก็บสถานะ Like (ใสไว้ใต้ followers)
  final Set<int> _likedPostIds = {};
  final Set<int> _repostedIds = {};
  final Set<int> _bookmarkedIds = {};

  Stream? _broadcastStream;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true; 

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _tweetyYellow = const Color(0xFFFFF100);
  
  Uint8List? _imageBytes; 
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? idStr = await _storage.read(key: 'user_id');
    String? name = await _storage.read(key: 'username');
    String? emailStr = await _storage.read(key: 'email');
    String? handleStr = await _storage.read(key: 'handle');
    String? followingStr = await _storage.read(key: 'following');
    String? followersStr = await _storage.read(key: 'followers');

    if (mounted) {
      setState(() {
        myUserId = idStr != null ? int.parse(idStr) : 0;
        myName = name ?? "Tweety User";
        myHandle = handleStr ?? "tweety_official";
        myEmail = emailStr ?? "user@example.com";
        myFollowing = followingStr != null ? int.parse(followingStr) : 0;
        myFollowers = followersStr != null ? int.parse(followersStr) : 0;
      });
    }

    _connectToServer();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _pickImage(StateSetter setSheetState) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); 
      setSheetState(() {
        _imageBytes = bytes;
      });
      setState(() {}); 
    }
  }

  void _connectToServer() async {
    try {
      final wsUrl = Uri.parse('wss://tweety-server.onrender.com/ws'); 
      _channel = WebSocketChannel.connect(wsUrl);
      print('✅ Connected to WebSocket Server on Render');

      final regMsg = {
        'action': 'register_connection',
        'user_id': myUserId,
      };
      _channel!.sink.add(jsonEncode(regMsg));

      _broadcastStream = _channel!.stream.asBroadcastStream();
      _broadcastStream!.listen(
        (message) {
          if (_isLoading) setState(() => _isLoading = false);
          _handleIncomingData(message.toString());
        },
        onError: (error) => print('❌ WebSocket Error: $error'),
        onDone: () => print('⚠️ WebSocket Closed'),
      );
    } catch (e) {
      print('❌ Connection Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleIncomingData(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      
      if (decoded['action'] == 'new_post') {
        final postData = decoded['data'];
        if (postData['parent_post_id'] == null) {
          setState(() {
            _messages.insert(0, postData);
          });
        }
      } 
      else if (decoded['action'] == 'new_comment') {
        final commentData = decoded['data'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${commentData['username']} ได้ตอบกลับโพสต์!")),
        );
      }
    } catch (e) {
      print('JSON Parse Error: $e');
    }
  }

  // 🔴 จุดที่แก้ 2: เพิ่มฟังก์ชันส่ง Like ไป Server (ใส่ไว้ก่อน sendMessage)
  void _toggleLike(int postId) {
    setState(() {
      if (_likedPostIds.contains(postId)) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
    });

    final msg = {
      'action': 'toggle_like',
      'user_id': myUserId,
      'post_id': postId,
    };

    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      print('Like Error: $e');
    }
  }

  //Repost
  void _toggleRepost(int postId) {
    setState(() {
      if (_repostedIds.contains(postId)) {
        _repostedIds.remove(postId);
      } else {
        _repostedIds.add(postId);
      }
    });

    final msg = {
      'action': 'toggle_repost', // ตรวจสอบกับ Backend ว่าใช้ชื่อ action นี้หรือไม่
      'user_id': myUserId,
      'post_id': postId,
    };

    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      print('Repost Error: $e');
    }
  }

  void _toggleBookmark(int postId) {
    setState(() {
      if (_bookmarkedIds.contains(postId)) {
        _bookmarkedIds.remove(postId);
      } else {
        _bookmarkedIds.add(postId);
      }
    });

    final msg = {
      'action': 'toggle_bookmark', // ชื่อ action สำหรับ Backend
      'user_id': myUserId,
      'post_id': postId,
    };

    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      print('Bookmark Error: $e');
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty && _imageBytes == null) return;
    
    final msg = {
      'action': 'create_post',
      'user_id': myUserId,
      'username': myName,
      'content': _textController.text.trim(),
      'image_urls': [],
    };

    try {
      _channel!.sink.add(jsonEncode(msg));
      setState(() {
        _textController.clear();
        _imageBytes = null;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งโพสต์สำเร็จ!')));
    } catch (e) {
      print('Send Error: $e');
    }
  }

  void _sendComment(int postId) {
    if (_textController.text.trim().isEmpty && _imageBytes == null) return;

    final msg = {
      'action': 'create_comment',
      'user_id': myUserId,
      'post_id': postId,
      'content': _textController.text.trim(),
      'image_urls': [],
    };

    try {
      _channel!.sink.add(jsonEncode(msg));
      _textController.clear();
      _imageBytes = null;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งคอมเม้นท์สำเร็จ!')));
    } catch (e) {
      print('Send Comment Error: $e');
    }
  }

  void _showCommentBottomSheet(Map<String, dynamic> parentPost) {
    _imageBytes = null;
    _textController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( 
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.black))),
                    const Text('Reply', style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () => _sendComment(parentPost['post_id'] ?? 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tweetyYellow, foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Reply', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 45),
                          const Text("Replying to ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text("@${parentPost['username'] ?? 'User'}", style: const TextStyle(color: Colors.blue, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              decoration: const InputDecoration(hintText: "Post your reply", border: InputBorder.none),
                              autofocus: true,
                            ),
                          ),
                        ],
                      ),
                      if (_imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 5, top: 5,
                                child: GestureDetector(
                                  onTap: () { setSheetState(() => _imageBytes = null); setState(() {}); },
                                  child: const CircleAvatar(backgroundColor: Colors.black54, radius: 15, child: Icon(Icons.close, size: 18, color: Colors.white)),
                                ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.image_outlined, color: Colors.blue), onPressed: () => _pickImage(setSheetState)),
                      IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.poll_outlined, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.location_on_outlined, color: Colors.blue), onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _showPostBottomSheet() {
    _imageBytes = null; 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( 
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.black))),
                    ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tweetyYellow, foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              decoration: const InputDecoration(hintText: "What's happening?", border: InputBorder.none),
                              autofocus: true,
                            ),
                          ),
                        ],
                      ),
                      if (_imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 5, top: 5,
                                child: GestureDetector(
                                  onTap: () { setSheetState(() => _imageBytes = null); setState(() {}); },
                                  child: const CircleAvatar(backgroundColor: Colors.black54, radius: 15, child: Icon(Icons.close, size: 18, color: Colors.white)),
                                ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.image_outlined, color: Colors.blue), onPressed: () => _pickImage(setSheetState)),
                      IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.poll_outlined, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.location_on_outlined, color: Colors.blue), onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(username: myName, handle: myHandle, email: myEmail, following: myFollowing, followers: myFollowers),
      appBar: AppBar(
        backgroundColor: _tweetyYellow, elevation: 1,
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.person_outline, size: 28), onPressed: () => Scaffold.of(context).openDrawer())),
        centerTitle: true,
        title: Image.asset('assets/images/twity.png', height: 40, fit: BoxFit.contain),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text("ยังไม่มีโพสต์ ลองสร้างโพสต์แรกดูสิ!", style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    String formattedDate = '';
                    if (msg['created_at'] != null) {
                      try {
                        DateTime parsedDate = DateTime.parse(msg['created_at']).toLocal();
                        formattedDate = DateFormat('dd MMM, HH:mm').format(parsedDate);
                      } catch (e) { formattedDate = 'Unknown Time'; }
                    }
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(msg['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CommentScreen(
                                              postData: msg,
                                              tweetyYellow: _tweetyYellow,
                                              channel: _channel,
                                              broadcastStream: _broadcastStream,
                                              myUserId: myUserId,
                                            ),
                                          ),
                                        );
                                      }, 
                                    ),
                                    // 🔴 จุดที่แก้ 3: เปลี่ยนจาก Icon เป็น IconButton เพื่อให้กด Like ได้
                                    IconButton(
                                      icon: Icon(
                                        _likedPostIds.contains(msg['post_id']) 
                                            ? Icons.favorite 
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: _likedPostIds.contains(msg['post_id']) 
                                            ? Colors.red 
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _toggleLike(msg['post_id'] ?? 0),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.repeat,
                                        size: 20,
                                        color: _repostedIds.contains(msg['post_id'])
                                            ? Colors.green // เปลี่ยนเป็นสีเขียวเมื่อ Repost (แบบ X/Twitter)
                                            : Colors.grey,
                                      ),
                                      onPressed: () =>
                                          _toggleRepost(msg['post_id'] ?? 0),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _bookmarkedIds.contains(msg['post_id']) 
                                            ? Icons.bookmark 
                                            : Icons.bookmark_border,
                                        size: 20,
                                        color: _bookmarkedIds.contains(msg['post_id']) 
                                            ? Colors.blue // เปลี่ยนเป็นสีน้ำเงินเมื่อบันทึกแล้ว
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _toggleBookmark(msg['post_id'] ?? 0),
                                    ),
                                    const Icon(Icons.ios_share, size: 20, color: Colors.grey),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: _tweetyYellow, border: const Border(top: BorderSide(color: Colors.black12, width: 0.5))),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, size: 30), onPressed: () {}),
            IconButton(icon: const Icon(Icons.search, size: 30), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()))),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 32), onPressed: _showPostBottomSheet),
            IconButton(icon: const Icon(Icons.notifications_outlined, size: 30), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))),
            IconButton(icon: const Icon(Icons.mail_outline, size: 30), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen()))),
          ],
        ),
      ),
    );
  }
}