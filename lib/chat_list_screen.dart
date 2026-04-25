import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'chat_room_screen.dart';
import 'search_screen.dart';
import 'notification_screen.dart';
import 'post_utils.dart';
import 'drawer.dart';
import 'sign_in_screen.dart';

/// แปลง ISO8601 timestamp ให้เป็นข้อความเวลาที่อ่านง่าย
String _formatTime(String? isoTime) {
  if (isoTime == null || isoTime.isEmpty) return '';
  try {
    final dt = DateTime.parse(isoTime).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24 && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  } catch (_) {
    return isoTime;
  }
}

class ChatListScreen extends StatefulWidget {
  // 🟢 1. รับค่า Channel, Stream และ myUserId เพื่อให้ดึงข้อมูลจาก Backend ได้
  final WebSocketChannel? channel;
  final Stream? broadcastStream;
  final int myUserId;

  const ChatListScreen({
    super.key,
    this.channel,
    this.broadcastStream,
    required this.myUserId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // ข้อมูลจำลองสำหรับ Drawer (ในอนาคตดึงจาก Backend ได้)
  String myName = "TwiTi User";
  String myHandle = "TwiTi_official";
  String myEmail = "user@example.com";
  int myFollowing = 120;
  int myFollowers = 5500;

  // 🟢 2. สร้าง State สำหรับเก็บรายการแชทและสถานะการโหลด
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  StreamSubscription? _streamSubscription;

  // 🟢 แก้ไขเฉพาะส่วน initState และเพิ่มฟังก์ชันดึง Mock Data
  @override
  void initState() {
    super.initState();

    // ขอข้อมูล chat list จาก backend
    _requestChatList();

    // เริ่มดักฟังข้อความ (Real-time)
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    } else {
      _isLoading = false;
    }

    // Timeout fallback: ถ้า backend ไม่ตอบใน 3 วินาที ให้หยุด loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _requestChatList() {
    final msg = {
      'action': 'get_chat_list', // ปรับชื่อ Action ให้ตรงกับ Backend ของคุณ
      'user_id': widget.myUserId,
    };
    widget.channel?.sink.add(jsonEncode(msg));
  }

  // 🟢 5. จัดการข้อมูลที่เด้งเข้ามาจาก WebSocket
  void _handleIncomingData(String jsonStr) {
    if (!mounted) return;

    try {
      final decoded = jsonDecode(jsonStr);

      // กรณี 1: โหลดรายการแชทครั้งแรกสำเร็จ
      if (decoded['action'] == 'load_chat_list') {
        setState(() {
          _chatRooms = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _isLoading = false;
        });
      }
      // กรณี 2: มีแชทใหม่เด้งเข้ามา (ให้ดันแชทนั้นขึ้นบนสุด)
      else if (decoded['action'] == 'new_message') {
        final newMessage = decoded['data'];

        setState(() {
          // หาว่าแชทห้องนี้มีอยู่ใน list หรือยัง
          int existingIndex = _chatRooms.indexWhere(
            (room) => room['room_id'] == newMessage['room_id'],
          );

          if (existingIndex != -1) {
            // ถ้ามีแล้ว ให้อัปเดตข้อความล่าสุด แล้วดันไปไว้บนสุด (index 0)
            final updatedRoom = _chatRooms.removeAt(existingIndex);
            updatedRoom['message'] = newMessage['content'] ?? newMessage['message'];
            updatedRoom['time'] = newMessage['created_at']?.toString() ?? newMessage['time']; // อัปเดตเวลาด้วย
            _chatRooms.insert(0, updatedRoom);
          } else {
            // ถ้ายังไม่มี (เป็นแชทคนใหม่) ให้เพิ่มเข้าไปหน้าสุดเลย
            _chatRooms.insert(0, {
              'room_id': newMessage['sender_id'] ?? newMessage['room_id'] ?? 0,
              'name': newMessage['sender_name'],
              'message': newMessage['content'] ?? newMessage['message'],
              'time': newMessage['created_at']?.toString() ?? newMessage['time'],
            });
          }
        });
      }
    } catch (e) {
      debugPrint('JSON Parse Error in ChatList: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // 🟢 6. ปิดการดักฟังเมื่อออกหน้าจอ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color tweetyYellow = const Color(0xFFFFF100);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(
        userId: widget.myUserId,
        username: myName,
        handle: myHandle,
        email: myEmail,
        following: myFollowing,
        followers: myFollowers,
        // เพิ่มบรรทัดนี้เข้าไปครับ
        onSwitchAccount: (targetAccount) async {
          const storage = FlutterSecureStorage();
          // 1. เขียนทับข้อมูล
          await storage.write(key: 'user_id', value: targetAccount['user_id']);
          await storage.write(
            key: 'username',
            value: targetAccount['username'],
          );
          await storage.write(key: 'email', value: targetAccount['email']);
          await storage.write(key: 'handle', value: targetAccount['handle']);
          await storage.write(
            key: 'following',
            value: targetAccount['following'],
          );
          await storage.write(
            key: 'followers',
            value: targetAccount['followers'],
          );

          // 2. ดีดกลับไปหน้า SignIn หรือหน้า Load ข้อมูลใหม่ (เพื่อให้ทุกอย่าง Refresh)
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
        elevation: 1,
        automaticallyImplyLeading: false,
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
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // 🟢 7. เปลี่ยนมาใช้ข้อมูลจริงที่ดึงมาแสดง
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _chatRooms.isEmpty
          ? const Center(
              child: Text(
                "No messages yet.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: _chatRooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = _chatRooms[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    chat['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat['message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTime(chat['time']?.toString()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    // 🟢 ตอนกดเข้าไปหน้าห้องแชท อย่าลืมส่ง channel เข้าไปด้วย (ถ้าหน้าห้องแชททำ real-time ไว้)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          userName: chat['name'] ?? 'Unknown',
                          myUserId: widget.myUserId,
                          receiverId: chat['room_id'] ?? 0,
                          channel: widget.channel,
                          broadcastStream: widget.broadcastStream,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          backgroundColor: tweetyYellow,
          elevation: 2,
          child: const Icon(Icons.mail_outline, color: Colors.black),
          onPressed: () {
            // TODO: ฟังก์ชันสำหรับเริ่มแชทใหม่
          },
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tweetyYellow,
          border: const Border(
            top: BorderSide(color: Colors.black12, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(
                Icons.home_outlined,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.black54),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  // อย่าลืมแนบค่าต่างๆ ไปด้วย
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 32,
                color: Colors.black54,
              ),
              onPressed: () {
                showPostDialog(
                  context: context,
                  controller: TextEditingController(),
                  onSend: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post Successful!')),
                    );
                  },
                  tweetyYellow: tweetyYellow,
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationScreen(
                      myUserId: widget.myUserId, // 🟢 ส่งค่าต่อไป
                      channel: widget.channel,
                      broadcastStream: widget.broadcastStream,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.mail, size: 30, color: Colors.black),
              onPressed: () {}, // อยู่หน้านี้อยู่แล้ว
            ),
          ],
        ),
      ),
    );
  }
}