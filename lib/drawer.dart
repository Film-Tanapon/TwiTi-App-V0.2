import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sign_in_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'create_sub_account_screen.dart';
import 'bookmarks_screen.dart';
import 'lists_screen.dart';

class MyDrawer extends StatefulWidget {
  final int userId;
  final String username;
  final String handle;
  final String email;
  final int following;
  final int followers;
  // เพิ่ม Callback สำหรับสั่งสลับบัญชีจากภายนอก
  final Function(Map<String, String>) onSwitchAccount;

  const MyDrawer({
    super.key,
    required this.userId,
    required this.username,
    required this.handle,
    required this.email,
    required this.following,
    required this.followers,
    required this.onSwitchAccount,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _subAccounts = [];
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchSubAccounts();
  }

  void _fetchSubAccounts() async {
    // 1. ดึงข้อมูลจาก Cache ในเครื่องก่อนเพื่อให้ UI ไม่ว่างเปล่า
    String? cachedData = await _storage.read(key: 'mock_sub_accounts');
    if (cachedData != null && mounted) {
      setState(() {
        _subAccounts = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
      });
    }

    // 2. เชื่อมต่อ Backend ผ่าน WebSocket เพื่ออัปเดตข้อมูลล่าสุด
    try {
      // เปลี่ยน URL เป็น IP หรือ Domain ของ Backend คุณ
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000/ws'));
      
      _channel?.sink.add(jsonEncode({
        "action": "fetch_sub_accounts", 
        "email": widget.email
      }));

      _channel?.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['action'] == 'sub_accounts_response' && mounted) {
          setState(() {
            _subAccounts = List<Map<String, dynamic>>.from(data['accounts'] ?? []);
          });
          // อัปเดต Cache
          _storage.write(key: 'mock_sub_accounts', value: jsonEncode(data['accounts']));
        }
      }, onError: (err) => debugPrint("WS Error: $err"));
      
    } catch (e) {
      debugPrint("Could not connect to backend: $e");
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Drawer(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 20, bottom: 20),
            color: tweetyYellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.black, 
                  radius: 35, 
                  child: Icon(Icons.person, color: Colors.white, size: 45)
                ),
                const SizedBox(height: 12),
                Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(widget.handle, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text('${widget.following}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text(' Following   '),
                    Text('${widget.followers}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text(' Followers'),
                  ],
                ),
              ],
            ),
          ),

          // Menu List Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.group_outlined, color: Colors.black),
                  title: const Text('Other Profiles', style: TextStyle(color: Colors.black)),
                  children: [
                    ..._subAccounts.map((account) => ListTile(
                      leading: const CircleAvatar(
                        radius: 15, 
                        backgroundColor: Colors.black, 
                        child: Icon(Icons.person, size: 18, color: Colors.white)
                      ),
                      title: Text(account['username'] ?? 'Unknown'),
                      subtitle: Text('@${account['handle'] ?? 'user'}'),
                        onTap: () {
                          // 1. ปิด Drawer ก่อนเพื่อความลื่นไหล
                          Navigator.pop(context);

                          // 2. ส่งข้อมูลไปสลับบัญชี
                          // แนะนำให้ใช้ตัวแปรพักข้อมูลเพื่อเช็ค null ก่อน toString()
                          widget.onSwitchAccount({
                            'user_id':
                                (account['user_id'] ?? account['id'] ?? '')
                                    .toString(),
                            'username': (account['username'] ?? 'Unknown')
                                .toString(),
                            'handle': (account['handle'] ?? 'user').toString(),
                            'email': widget
                                .email, // 🟢 สำคัญมาก: ต้องส่ง email หลักพ่วงไปเพื่อให้บัญชีใหม่ใช้ดึง List ต่อได้
                            'following': (account['following'] ?? 0).toString(),
                            'followers': (account['followers'] ?? 0).toString(),
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      title: const Text('Create New Profile', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => CreateSubAccountScreen(mainEmail: widget.email))
                        );
                        if (result == true) _fetchSubAccounts();
                      },
                    ),
                  ],
                ),
                _buildMenuItem(Icons.bookmark_border, 'Bookmarks', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarksScreen()));
                }),
                _buildMenuItem(Icons.list_alt, 'Lists', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ListsScreen(myUserId: widget.userId)));
                }),
                _buildMenuItem(Icons.person_outline, 'Profile', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(
                    targetUserId: widget.userId, 
                    username: widget.username, 
                    handle: widget.handle, 
                    following: widget.following, 
                    followers: widget.followers
                  )));
                }),
                const Divider(),
                _buildMenuItem(Icons.settings_outlined, 'Settings and Privacy', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
              ],
            ),
          ),

          // Logout Section
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              // ลบเฉพาะข้อมูลบัญชีปัจจุบัน (Session)
              await _storage.delete(key: 'user_id');
              await _storage.delete(key: 'username');
              // ห้ามลบ mock_sub_accounts หรือข้อมูลบัญชีอื่นๆ

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black), 
      title: Text(title), 
      onTap: onTap
    );
  }
}