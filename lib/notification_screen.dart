import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sign_in_screen.dart';
import 'drawer.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'chat_room_screen.dart'; // 🟢 import ChatRoom
import 'post_utils.dart';

class NotificationScreen extends StatefulWidget {
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

  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _mentions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestOldNotifications();

    // ถ้า stream เป็น null ให้หยุด loading ทันที
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    } else {
      setState(() => _isLoading = false);
    }

    // Timeout fallback: ถ้า backend ไม่ตอบใน 3 วินาที ให้หยุด loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _requestOldNotifications() {
    final msg = {
      'action': 'get_notifications',
      'user_id': widget.myUserId,
    };
    widget.channel?.sink.add(jsonEncode(msg));
  }

  Future<void> _handleIncomingData(String jsonStr) async {
    if (!mounted) return;
    try {
      final decoded = jsonDecode(jsonStr);

      if (decoded['action'] == 'load_notifications') {
        setState(() {
          _allNotifications =
              List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _mentions = _allNotifications
              .where((n) =>
                  n['type'] == 'reply' || n['type'] == 'mention')
              .toList();
          _isLoading = false;
        });
      }

      // 🟢 แจ้งเตือน: ข้อความใหม่ (DM)
      else if (decoded['action'] == 'new_message') {
        final msg = decoded['data'];
        final int receiverId = msg['receiver_id'] ?? 0;
        final int senderId = msg['sender_id'] ?? 0;

        // แสดงเฉพาะ message ที่ส่งมาหาเรา (ไม่ใช่ที่เราส่งออกไป)
        if (receiverId == widget.myUserId && senderId != widget.myUserId) {
          final notificationItem = {
            'user': msg['sender_name'] ?? 'Someone',
            'type': 'message',
            'content': msg['content'] ?? '',
            'sender_id': senderId,    // 🟢 เก็บ ID เพื่อเปิดหน้าแชท
            'sender_name': msg['sender_name'] ?? 'Someone',
          };
          setState(() {
            _allNotifications.insert(0, notificationItem);
          });
        }
      }

      // 🟢 แจ้งเตือน: ทั่วไป (like, repost, follow, mention)
      else if (decoded['action'] == 'new_notification' ||
          decoded['action'] == 'new_comment') {
        final newNoti = decoded['data'];

        if (newNoti['target_user_id'] == widget.myUserId &&
            newNoti['user_id'] != widget.myUserId) {
          bool iFollowThem = newNoti['is_followed_by_me'] ?? false;
          bool theyFollowMe = newNoti['is_following_me'] ?? false;
          final String notiType = newNoti['type'] ?? '';

          // mute filter ไม่ใช้กับ follow notification
          // เพราะคนที่เพิ่ง follow เรา เราก็ยังไม่ได้ follow กลับ (iFollowThem = false เสมอ)
          if (notiType != 'follow') {
            bool muteDontFollow =
                (await _storage.read(key: 'mute_dont_follow')) == 'true';
            bool muteNotFollowingYou =
                (await _storage.read(key: 'mute_not_following_you')) == 'true';
            if (!mounted) return;
            if (muteDontFollow && !iFollowThem) return;
            if (muteNotFollowingYou && !theyFollowMe) return;
          }

          if (!mounted) return;

          final notificationItem = {
            'user': newNoti['username'] ?? 'Someone',
            'type': newNoti['type'] ?? 'reply',
            'content': newNoti['content'] ?? '',
            // 🟢 เก็บข้อมูลสำหรับปุ่ม Follow (กรณี type == 'follow')
            'sender_id': newNoti['user_id'] ?? 0,
            'they_follow_me': theyFollowMe,
            'i_follow_them': iFollowThem,
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

  // 🟢 Follow กลับจากหน้า Notification
  void _followBack(Map<String, dynamic> item) {
    final int targetId = item['sender_id'] ?? 0;
    if (targetId == 0) return;

    widget.channel?.sink.add(jsonEncode({
      'action': 'toggle_follow',
      'user_id': widget.myUserId,
      'target_user_id': targetId,
    }));

    // อัปเดต UI ทันที
    setState(() {
      item['i_follow_them'] = true;
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
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
        username: "TwiTi User",
        handle: "TwiTi_official",
        email: "user@example.com",
        following: 120,
        followers: 5500,
        onSwitchAccount: (targetAccount) async {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'user_id', value: targetAccount['user_id']);
          await storage.write(
              key: 'username', value: targetAccount['username']);
          await storage.write(key: 'email', value: targetAccount['email']);
          await storage.write(key: 'handle', value: targetAccount['handle']);
          await storage.write(
              key: 'following', value: targetAccount['following']);
          await storage.write(
              key: 'followers', value: targetAccount['followers']);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const SignInScreen()),
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
            icon: const Icon(Icons.person_outline,
                color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Notifications',
          style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              tabs: const [Tab(text: "All"), Tab(text: "Mentions")],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black))
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
          border:
              Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined,
                  size: 30, color: Colors.black54),
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            IconButton(
              icon: const Icon(Icons.search,
                  size: 30, color: Colors.black54),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  size: 32, color: Colors.black54),
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
              icon: Icon(Icons.notifications,
                  size: 30, color: Colors.black),
              onPressed: null,
            ),
            IconButton(
              icon: const Icon(Icons.mail_outline,
                  size: 30, color: Colors.black54),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListScreen(
                    myUserId: widget.myUserId,
                    channel: widget.channel,
                    broadcastStream: widget.broadcastStream,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text("No notifications yet",
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = data[index];

        IconData icon;
        String actionText;
        Color iconColor = Colors.black;

        switch (item['type']) {
          case 'message': // 🟢 DM notification
            icon = Icons.mail;
            actionText = 'sent you a message';
            iconColor = const Color(0xFFFFF100);
            break;
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
          context: context,
          icon: icon,
          iconColor: iconColor,
          title: "${item['user']} $actionText",
          subtitle: item['content'],
          item: item,
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Map<String, dynamic> item,
  }) {
    final bool isMessage = item['type'] == 'message';
    final bool isFollow = item['type'] == 'follow';
    final bool iFollowThem = item['i_follow_them'] == true;

    return ListTile(
      onTap: isMessage
          // 🟢 กดแจ้งเตือน DM → ไปหน้า ChatRoom
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomScreen(
                    userName: item['sender_name'] ?? item['user'] ?? 'Unknown',
                    myUserId: widget.myUserId,
                    receiverId: item['sender_id'] ?? 0,
                    channel: widget.channel,
                    broadcastStream: widget.broadcastStream,
                  ),
                ),
              );
            }
          : null,
      leading: Icon(icon, size: 35, color: iconColor),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: (subtitle != null && subtitle.isNotEmpty)
          ? Text(subtitle)
          : null,
      // 🟢 ปุ่ม Follow กลับ (แสดงเฉพาะ type == 'follow' และเรายังไม่ได้ follow กลับ)
      trailing: isFollow && !iFollowThem
          ? ElevatedButton(
              onPressed: () => _followBack(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              child: const Text('Follow',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : isFollow && iFollowThem
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Colors.grey),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  ),
                  child: const Text('Following',
                      style: TextStyle(color: Colors.grey)),
                )
              : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}