import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async'; // 🟢 สำหรับ StreamSubscription
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'chat_room_screen.dart';
import 'search_screen.dart';
import 'notification_screen.dart';
import 'post_utils.dart';
import 'drawer.dart';
import 'sign_in_screen.dart';

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

    // 1. ลองขอข้อมูลจาก Backend จริงก่อน
    _requestChatList();

    // 2. ตั้งเวลาจำลอง: ถ้าผ่านไป 1 วินาทีแล้ว Backend ยังไม่ตอบกลับ ให้โชว์ Mock Data แทน
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _chatRooms.isEmpty && _isLoading) {
        setState(() {
          _chatRooms = _getMockChatRooms();
          _isLoading = false;
        });
      }
    });

    // 3. เริ่มดักฟังข้อความ (Real-time)
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    }
  }

  // 🟢 ฟังก์ชันสำหรับสร้างข้อมูลจำลอง (Mock Data)
  List<Map<String, dynamic>> _getMockChatRooms() {
    return [
      {
        'room_id': 101,
        'name': 'John Doe',
        'message': 'สวัสดีครับ สนใจโปรเจกต์นี้มาก!',
        'time': '10:30 AM',
      },
      {
        'room_id': 102,
        'name': 'Flutter Developer',
        'message': 'ส่งโค้ดชุดใหม่ให้แล้วนะ ลองเช็คดูใน GitHub',
        'time': 'Yesterday',
      },
      {
        'room_id': 103,
        'name': 'Sarah Wilson',
        'message': 'ขอบคุณสำหรับคำแนะนำเมื่อวานนะคะ',
        'time': 'Yesterday',
      },
      {
        'room_id': 104,
        'name': 'Design Team',
        'message': 'อัปเดตไฟล์ Figma สำหรับหน้า Profile เรียบร้อย',
        'time': 'Feb 12',
      },
      {
        'room_id': 105,
        'name': 'Mike Ross',
        'message': 'เจอกันที่ออฟฟิศพรุ่งนี้ตอนบ่ายนะครับ',
        'time': 'Feb 10',
      },
      {
        'room_id': 106,
        'name': 'TwiTi Support',
        'message': 'ยินดีต้อนรับสู่แอป TwiTi! มีอะไรให้ช่วยไหมครับ?',
        'time': 'Feb 01',
      },
    ];
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
            updatedRoom['message'] = newMessage['message'];
            updatedRoom['time'] = newMessage['time']; // อัปเดตเวลาด้วย
            _chatRooms.insert(0, updatedRoom);
          } else {
            // ถ้ายังไม่มี (เป็นแชทคนใหม่) ให้เพิ่มเข้าไปหน้าสุดเลย
            _chatRooms.insert(0, {
              'room_id': newMessage['room_id'],
              'name': newMessage['sender_name'],
              'message': newMessage['message'],
              'time': newMessage['time'],
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
                    chat['time'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    // 🟢 ตอนกดเข้าไปหน้าห้องแชท อย่าลืมส่ง channel เข้าไปด้วย (ถ้าหน้าห้องแชททำ real-time ไว้)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          userName: chat['name'] ?? 'Unknown',
                          // channel: widget.channel, // ถ้าหน้า ChatRoom รับค่านี้ ให้เปิดคอมเมนต์
                          // myUserId: widget.myUserId,
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
