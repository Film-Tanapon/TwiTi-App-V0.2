import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async'; // สำหรับ StreamSubscription
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sign_in_screen.dart';
import 'drawer.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'post_utils.dart';

class NotificationScreen extends StatefulWidget {
  // 🟢 1. รับค่า Channel, Stream และ User ID มาใช้งาน
  final WebSocketChannel? channel;
  final Stream? broadcastStream;
  final int myUserId;

  const NotificationScreen({
    super.key,
    this.channel,
    this.broadcastStream,
    required this.myUserId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notiController = TextEditingController();
  final Color tweetyYellow = const Color(0xFFFFF100);
  final Color lightYellow = const Color(0xFFFFFFCC);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  StreamSubscription? _streamSubscription;
  bool _isLoading = true;

  // เปลี่ยนมาใช้เป็น List เปล่าๆ เพื่อรอรับข้อมูลจริง
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _mentions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 🟢 2. ขอข้อมูลแจ้งเตือนเก่าจาก Backend ตอนเปิดหน้าจอ
    _requestOldNotifications();

    // 🟢 3. ดักฟังการแจ้งเตือนใหม่ๆ แบบ Real-time
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    } else {
      // ถ้าไม่มี Stream ส่งมาให้ปิดโหลดไปเลย (กันค้าง)
      _isLoading = false;
    }
  }

  void _requestOldNotifications() {
    final msg = {
      'action':
          'get_notifications', // ต้องแก้ชื่อ action ให้ตรงกับ backend ของคุณ
      'user_id': widget.myUserId,
    };
    widget.channel?.sink.add(jsonEncode(msg));
  }

  // 🟢 4. ฟังก์ชันจัดการข้อมูลที่รับมาจาก Backend
  Future<void> _handleIncomingData(String jsonStr) async {
    if (!mounted) return;

    try {
      final decoded = jsonDecode(jsonStr);

      // กรณี 1: โหลดข้อมูลเก่าทั้งหมดสำเร็จ
      if (decoded['action'] == 'load_notifications') {
        setState(() {
          _allNotifications = List<Map<String, dynamic>>.from(
            decoded['data'] ?? [],
          );

          _mentions = _allNotifications
              .where(
                (noti) => noti['type'] == 'reply' || noti['type'] == 'mention',
              )
              .toList();

          _isLoading = false;
        });
      }
      // กรณี 2: มีคนคอมเมนต์ หรือ มีการแจ้งเตือนใหม่ (Real-time)
      else if (decoded['action'] == 'new_notification' ||
          decoded['action'] == 'new_comment') {
        final newNoti = decoded['data'];

        if (newNoti['target_user_id'] == widget.myUserId &&
            newNoti['user_id'] != widget.myUserId) {
          // ==========================================
          // 🛡️ เริ่มระบบคัดกรอง Mute Notification
          // ==========================================
          bool muteDontFollow =
              (await _storage.read(key: 'mute_dont_follow')) == 'true';
          bool muteNotFollowingYou =
              (await _storage.read(key: 'mute_not_following_you')) == 'true';

          if (!mounted) return;

          // ดึงค่าความสัมพันธ์ที่ Backend ต้องส่งมาด้วย
          bool iFollowThem = newNoti['is_followed_by_me'] ?? false;
          bool theyFollowMe = newNoti['is_following_me'] ?? false;

          // เช็คเงื่อนไขการ Mute
          if (muteDontFollow && !iFollowThem) {
            return; // ❌ เราไม่ได้ตามเขา -> ทิ้งการแจ้งเตือน
          }

          if (muteNotFollowingYou && !theyFollowMe) {
            return; // ❌ เขาไม่ได้ตามเรา -> ทิ้งการแจ้งเตือน
          }
          // ==========================================

          // จัดฟอร์แมตข้อมูลให้ตรงกับที่ UI นำไปใช้
          final notificationItem = {
            'user': newNoti['username'] ?? 'Someone',
            'type': newNoti['type'] ?? 'reply',
            'content': newNoti['content'] ?? '',
          };

          setState(() {
            _allNotifications.insert(0, notificationItem);

            if (notificationItem['type'] == 'reply' ||
                notificationItem['type'] == 'mention') {
              _mentions.insert(0, notificationItem);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('JSON Parse Error in Notifications: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // อย่าลืมปิดเพื่อคืน Memory
    _tabController.dispose();
    _notiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(
        userId: widget.myUserId,
        username: "TwiTi User", // หรือจะใช้ตัวแปรชื่อ User จาก State ถ้ามี
        handle: "TwiTi_official",
        email: "user@example.com",
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
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: lightYellow,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Mentions"),
              ],
            ),
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(_allNotifications),
                _buildListView(_mentions),
              ],
            ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF100),
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
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
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.black54),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 32,
                color: Colors.black54,
              ),
              onPressed: () => showPostDialog(
                context: context,
                controller: _notiController,
                onSend: () {
                  _notiController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post Successful!')),
                  );
                },
                tweetyYellow: tweetyYellow,
              ),
            ),
            const IconButton(
              icon: const Icon(
                Icons.notifications,
                size: 30,
                color: Colors.black,
              ),
              onPressed: null,
            ),
            IconButton(
              icon: const Icon(
                Icons.mail_outline,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListScreen(
                    myUserId: widget.myUserId, // ส่ง ID ต่อไป
                    channel: widget.channel, // ส่งท่อ WebSocket ต่อไป
                    broadcastStream:
                        widget.broadcastStream, // ส่งตัวดักฟังต่อไป
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ใช้ _buildListView แบบที่รองรับ Like, Repost, Follow ตามที่เราทำกันไว้ก่อนหน้านี้
  Widget _buildListView(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = data[index];

        IconData icon;
        String actionText;
        Color iconColor = Colors.black;

        switch (item['type']) {
          case 'reply':
          case 'mention':
            icon = Icons.chat_bubble_outline;
            actionText = 'Replied to you';
            break;
          case 'follow':
            icon = Icons.person_add_alt_1;
            actionText = 'Followed you';
            iconColor = Colors.blue;
            break;
          case 'like':
            icon = Icons.favorite;
            actionText = 'Liked your post';
            iconColor = Colors.red;
            break;
          case 'repost':
            icon = Icons.repeat;
            actionText = 'Reposted your post';
            iconColor = Colors.green;
            break;
          default:
            icon = Icons.notifications;
            actionText = 'New notification';
        }

        return _buildNotificationItem(
          icon: icon,
          iconColor: iconColor,
          title: "${item['user']} $actionText",
          subtitle: item['content'],
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, size: 35, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: (subtitle != null && subtitle.isNotEmpty)
          ? Text(subtitle)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}
