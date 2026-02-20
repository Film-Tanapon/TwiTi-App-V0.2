import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async'; // 🟢 อย่าลืม import async เพื่อใช้ StreamSubscription

class CommentScreen extends StatefulWidget {
  final Map<String, dynamic> postData;
  final Color tweetyYellow;
  final WebSocketChannel? channel;
  final Stream? broadcastStream;
  final int myUserId;

  const CommentScreen({
    super.key,
    required this.postData,
    required this.tweetyYellow,
    this.channel,
    required this.myUserId,
    this.broadcastStream,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  // 🟢 1. สร้างตัวแปร State เก็บรายการคอมเมนต์
  List<dynamic> _comments = [];
  StreamSubscription? _streamSubscription;
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();

    _requestOldComments();
    
    // 🟢 2. ดึงคอมเมนต์เก่ามาใส่ไว้ใน State ตอนเปิดหน้าจอ
    _comments = List.from(widget.postData['comments'] ?? []);

    // 🟢 3. ดักฟัง Backend ว่ามีคอมเมนต์ใหม่เด้งเข้ามาไหม
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    }
  }

  void _requestOldComments() {
    int currentPostId = widget.postData['post_id'] ?? widget.postData['id'] ?? 0;
    final msg = {
      'action': 'get_comments',
      'post_id': currentPostId,
    };
    widget.channel?.sink.add(jsonEncode(msg));
  }

  // 🟢 4. ฟังก์ชันจัดการข้อมูลที่รับมาจาก Backend
  void _handleIncomingData(String jsonStr) {
    if (!mounted) return;

    try {
      final decoded = jsonDecode(jsonStr);
      
      // 🟢 3. รอรับคอมเมนต์เก่าที่ Backend ส่งกลับมาให้
      if (decoded['action'] == 'load_comments') {
        setState(() {
          _comments = decoded['data'] ?? [];
          _isLoadingComments = false;
        });
      }
      // ดักฟังคอมเมนต์ใหม่ (Real-time) เหมือนเดิม
      else if (decoded['action'] == 'new_comment' || (decoded['action'] == 'new_post' && decoded['data']['parent_post_id'] != null)) {
        final newCommentData = decoded['data'];
        int currentPostId = widget.postData['post_id'] ?? widget.postData['id'] ?? 0;
        int targetPostId = newCommentData['post_id'] ?? newCommentData['parent_post_id'] ?? 0;

        if (currentPostId == targetPostId) {
          setState(() {
            _comments.add(newCommentData);
          });
        }
      }
    } catch (e) {
      print('JSON Parse Error: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // 🟢 5. ปิดการดักฟังเมื่อออกจาหน้าจอ ป้องกันแอปค้าง
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    final msg = {
      'action': 'create_comment',
      'user_id': widget.myUserId,
      'post_id': widget.postData['post_id'] ?? widget.postData['id'] ?? 0,
      'content': _commentController.text.trim(),
      'image_urls': [],
    };

    try {
      widget.channel?.sink.add(jsonEncode(msg)); 
      _commentController.clear();
      FocusScope.of(context).unfocus(); // เอาคีย์บอร์ดลงหลังส่งเสร็จ
    } catch (e) {
      print('Send Comment Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Post Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: widget.tweetyYellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.postData['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(widget.postData['content'] ?? '', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          Expanded(
            child: _isLoadingComments 
              ? const Center(child: CircularProgressIndicator()) // 🟢 แสดงหมุนๆ ตอนรอโหลด
              : _comments.isEmpty 
                ? const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final cmt = _comments[index];
                      return ListTile(
                        leading: const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 15)),
                        title: Text(cmt['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(cmt['content'] ?? ''),
                      );
                    },
                  ),
          ),

          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              left: 10, right: 10, top: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white, 
              border: Border(top: BorderSide(color: Colors.grey.shade300))
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendComment,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}