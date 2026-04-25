import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';

// Import หน้าจออื่นๆ ของคุณ
import 'sign_in_screen.dart';
import 'drawer.dart';
import 'post_screen.dart';
import 'comment_screen.dart';
import 'notification_screen.dart';
import 'chat_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // --- 🛠️ Configuration & State ---
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  WebSocketChannel? _channel;
  Stream? _broadcastStream;
  Uint8List? _imageBytes;

  int myUserId = 0;
  String myName = "Loading...";
  String myHandle = "...";
  String myEmail = "...";
  int myFollowing = 0;
  int myFollowers = 0;

  final List<String> _searchHistory = [];
  final Color tweetyYellow = const Color(0xFFFFF100);

  bool _isLoading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _userResults = [];
  final List<Map<String, dynamic>> _postResults = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- 🔒 Data Loading & WebSocket ---
  Future<void> _loadUserData() async {
    final results = await Future.wait([
      _storage.read(key: 'user_id'),
      _storage.read(key: 'username'),
      _storage.read(key: 'email'),
      _storage.read(key: 'handle'),
      _storage.read(key: 'following'),
      _storage.read(key: 'followers'),
    ]);

    if (mounted) {
      setState(() {
        myUserId = int.tryParse(results[0] ?? '0') ?? 0;
        myName = results[1] ?? "Tweety User";
        myEmail = results[2] ?? "user@example.com";
        myHandle = results[3] ?? "tweety_official";
        myFollowing = int.tryParse(results[4] ?? '0') ?? 0;
        myFollowers = int.tryParse(results[5] ?? '0') ?? 0;
      });
      _connectToServer();
    }
  }

  void _connectToServer() async {
    try {
      final wsUrl = Uri.parse('ws://localhost:3000/ws');
      _channel = WebSocketChannel.connect(wsUrl);
      debugPrint('✅ Connected to WebSocket Server on Render');

      final regMsg = {'action': 'register_connection', 'user_id': myUserId};
      _channel!.sink.add(jsonEncode(regMsg));

      _broadcastStream = _channel!.stream.asBroadcastStream();
      _broadcastStream!.listen(
        (message) {
          _handleIncomingData(message.toString());
        },
        onError: (error) => debugPrint('❌ WebSocket Error: $error'),
        onDone: () => debugPrint('⚠️ WebSocket Closed'),
      );
    } catch (e) {
      debugPrint('❌ Connection Error: $e');
    }
  }

  void _handleIncomingData(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      final action = decoded['action'];
      final data = decoded['data'];

      setState(() {
        if (action == 'new_post' && data['parent_post_id'] == null) {
          _postResults.insert(0, Map<String, dynamic>.from(data));
        }
        // 🟢 เปลี่ยนมาเช็คและอัปเดตที่ _postResults แทน
        if (action == 'update_post_stats') {
          int index = _postResults.indexWhere(
            (m) => m['post_id'] == data['post_id'],
          );
          if (index != -1) {
            _postResults[index]['likes_count'] = data['likes_count'];
            _postResults[index]['reposts_count'] = data['reposts_count'];
          }
        }
      });
    } catch (e) {
      debugPrint('JSON Parse Error: $e');
    }
  }

  void _toggleLike(int postId) {
    int index = _postResults.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isLiked = _postResults[index]['is_liked'] ?? false;
      if (isLiked) {
        _postResults[index]['is_liked'] = false;
        _postResults[index]['likes_count'] =
            (_postResults[index]['likes_count'] ?? 1) - 1;
      } else {
        _postResults[index]['is_liked'] = true;
        _postResults[index]['likes_count'] =
            (_postResults[index]['likes_count'] ?? 0) + 1;
      }
    });

    _channel!.sink.add(
      jsonEncode({
        'action': 'toggle_like',
        'user_id': myUserId,
        'post_id': postId,
      }),
    );
  }

  void _toggleRepost(int postId) {
    int index = _postResults.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isReposted = _postResults[index]['is_reposted'] ?? false;
      if (isReposted) {
        _postResults[index]['is_reposted'] = false;
        _postResults[index]['reposts_count'] =
            (_postResults[index]['reposts_count'] ?? 1) - 1;
      } else {
        _postResults[index]['is_reposted'] = true;
        _postResults[index]['reposts_count'] =
            (_postResults[index]['reposts_count'] ?? 0) + 1;
      }
    });

    _channel!.sink.add(
      jsonEncode({
        'action': 'toggle_repost',
        'user_id': myUserId,
        'post_id': postId,
      }),
    );
  }

  void _toggleBookmark(int postId) {
    int index = _postResults.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isBookmarked = _postResults[index]['is_bookmarked'] ?? false;
      _postResults[index]['is_bookmarked'] = !isBookmarked;
    });

    _channel!.sink.add(
      jsonEncode({
        'action': 'toggle_bookmark',
        'user_id': myUserId,
        'post_id': postId,
      }),
    );
  }

  // --- 📸 Post Logic (เหมือน PostScreen) ---
  Future<void> _pickImage(StateSetter setSheetState) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setSheetState(() => _imageBytes = bytes);
    }
  }

  void _sendPost() {
    if (_postController.text.trim().isEmpty && _imageBytes == null) return;

    final msg = {
      'action': 'create_post',
      'user_id': myUserId,
      'username': myName,
      'content': _postController.text.trim(),
      'image_urls': [], // ถ้ามี Logic อัปโหลดรูปใส่ที่นี่
    };

    _channel?.sink.add(jsonEncode(msg));
    _postController.clear();
    _imageBytes = null;
    Navigator.pop(context);
  }

  void _showPostBottomSheet() {
    _imageBytes = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _sendPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tweetyYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          TextField(
                            controller: _postController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "What's happening?",
                              border: InputBorder.none,
                            ),
                            autofocus: true,
                          ),
                          if (_imageBytes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: GestureDetector(
                                      onTap: () => setSheetState(
                                        () => _imageBytes = null,
                                      ),
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        radius: 15,
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.image_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () => _pickImage(setSheetState),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.gif_box_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.poll_outlined, color: Colors.blue),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 🔍 Search Logic ---
  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    if (!_searchHistory.contains(keyword)) _searchHistory.insert(0, keyword);

    try {
      String baseUrl = kIsWeb
          ? 'http://localhost:3000'
          : (Platform.isAndroid
                ? 'http://10.0.2.2:3000'
                : 'http://localhost:3000');
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/search?q=${Uri.encodeComponent(keyword)}&userID=$myUserId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userResults = List<Map<String, dynamic>>.from(data['users'] ?? []);
          _postResults.clear();
          for (var post in data['posts'] ?? []) {
            _postResults.add(Map<String, dynamic>.from(post));
          }
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 🖥️ UI Builders ---
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final myUserId = userProvider.userId ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(
        userId: myUserId, 
        username: myName,
        handle: myHandle, 
        email: myEmail,
        following: 120,
        followers: 5500,
        // เพิ่มฟังก์ชันสลับบัญชีที่นี่
        onSwitchAccount: (targetAccount) async {
          const storage = FlutterSecureStorage();
          // 1. บันทึกข้อมูลบัญชีใหม่ลงใน Storage
          await storage.write(key: 'user_id', value: targetAccount['user_id']);
          await storage.write(key: 'username', value: targetAccount['username']);
          await storage.write(key: 'email', value: targetAccount['email']);
          await storage.write(key: 'handle', value: targetAccount['handle']);
          await storage.write(key: 'following', value: targetAccount['following']);
          await storage.write(key: 'followers', value: targetAccount['followers']);

          // 2. ดีดกลับไปหน้า SignIn เพื่อเริ่มต้นโหลดข้อมูลใหม่ทั้งหมด (แก้ Error)
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
              (route) => false,
            );
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: tweetyYellow,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => _performSearch(value.trim()),
            onChanged: (value) {
              if (value.isEmpty) setState(() => _hasSearched = false);
            },
            decoration: const InputDecoration(
              hintText: 'Search TwiTi...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (!_hasSearched ? _buildDefaultBody() : _buildSearchResults()),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      children: [
        if (_userResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _userResults.length,
              itemBuilder: (context, index) {
                final user = _userResults[index];
                return GestureDetector(
                  onTap: () {
                    // เมื่อกด ให้ไปยังหน้า ProfileScreen พร้อมส่งข้อมูลของ user คนนี้ไป
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          targetUserId: user['id'] ?? 0,
                          username: user['username'] ?? 'Unknown User',
                          handle:
                              user['handle'] ?? user['username'] ?? 'unknown',
                          // หมายเหตุ: เช็คชื่อ Key ของ API คุณด้วยว่าใช้คำว่าอะไร
                          // (เช่น following, following_count) ในที่นี้ใส่ fallback เป็น 0 ไว้กันแอปเด้ง
                          following:
                              user['following'] ?? user['following_count'] ?? 0,
                          followers:
                              user['followers'] ?? user['followers_count'] ?? 0,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              (user['profile_image_url'] ?? '').isNotEmpty
                              ? NetworkImage(user['profile_image_url'])
                              : null,
                          child: (user['profile_image_url'] ?? '').isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        Text(
                          user['username'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 4, color: Colors.black12),
        ],
        if (_postResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Posts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _postResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final post = _postResults[index];
              String formattedDate = '';
              if (post['created_at'] != null) {
                try {
                  DateTime parsedDate = DateTime.parse(
                    post['created_at'],
                  ).toLocal();
                  formattedDate = DateFormat(
                    'dd MMM, HH:mm',
                  ).format(parsedDate);
                } catch (e) {
                  formattedDate = 'Unknown Time';
                }
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ กดรูปโปรไฟล์ → ไปหน้า ProfileScreen ของเจ้าของโพสต์
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              targetUserId: post['user_id'] ?? 0,
                              username: post['username'] ?? '',
                              handle: post['username'] ?? '',
                              following: 0,
                              followers: 0,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.black,
                        backgroundImage:
                            (post['profile_image_url'] ?? '').isNotEmpty
                            ? NetworkImage(post['profile_image_url'])
                            : null,
                        child: (post['profile_image_url'] ?? '').isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post['username'] ?? 'User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['content'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentScreen(
                                        postData: post,
                                        tweetyYellow: tweetyYellow,
                                        channel: _channel,
                                        broadcastStream: _broadcastStream,
                                        myUserId: myUserId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // 🔴 จุดที่แก้ 3: เปลี่ยนจาก Icon เป็น IconButton เพื่อให้กด Like ได้
                              Row(
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      (post['is_liked'] == true)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: (post['is_liked'] == true)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () =>
                                        _toggleLike(post['post_id'] ?? 0),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${post['likes_count'] ?? 0}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.repeat,
                                      size: 20,
                                      color: (post['is_reposted'] == true)
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: () =>
                                        _toggleRepost(post['post_id'] ?? 0),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${post['reposts_count'] ?? 0}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  (post['is_bookmarked'] == true)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20,
                                  color: (post['is_bookmarked'] == true)
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () =>
                                    _toggleBookmark(post['post_id'] ?? 0),
                              ),

                              //Share icon ยังไม่เป็น Button
                              const Icon(
                                Icons.ios_share,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultBody() {
    return ListView(
      children: [
        if (_searchHistory.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Recent Search",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          for (var item in _searchHistory.take(3))
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(item),
              onTap: () => _performSearch(item),
            ),
        ],
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Trends for you",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (int i = 1; i <= 5; i++)
          ListTile(
            title: Text(
              "#Trend_Topic_$i",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("1,234 Posts"),
            trailing: const Icon(Icons.more_horiz),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: tweetyYellow,
        border: const Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 28),
            onPressed: () => Navigator.pushReplacement(
              // แนะนำให้ใช้ pushReplacement สำหรับเมนูด้านล่าง
              context,
              MaterialPageRoute(builder: (context) => const PostScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Colors.black),
            onPressed: () {}, // อยู่หน้านี้อยู่แล้ว ไม่ต้อง push ใหม่
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 30),
            onPressed: _showPostBottomSheet,
          ),

          // 🔴 แก้ไขปุ่ม Notification ส่งค่าไปให้ครบ
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationScreen(
                  myUserId: myUserId,
                  channel: _channel,
                  broadcastStream: _broadcastStream,
                ),
              ),
            ),
          ),

          // 🔴 แก้ไขปุ่ม Mail ส่งค่าไปให้ครบเช่นกัน
          IconButton(
            icon: const Icon(Icons.mail_outline, size: 28),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatListScreen(
                  myUserId: myUserId,
                  channel: _channel,
                  broadcastStream: _broadcastStream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _postController.dispose();
    super.dispose();
  }
}
