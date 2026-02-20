import 'package:flutter/material.dart';
import 'profile_screen.dart'; // 1. ตรวจสอบว่านำเข้าไฟล์ ProfileScreen แล้ว
import 'settings_screen.dart'; // อย่าลืมนำเข้าไฟล์ที่เพิ่งสร้าง

class MyDrawer extends StatelessWidget {
  final String username;
  final String handle;
  final int following;
  final int followers;

  const MyDrawer({
    super.key,
    required this.username,
    required this.handle,
    required this.following,
    required this.followers,

  });

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Drawer(
      child: Column(
        children: [
          // ส่วนหัวโปรไฟล์หลัก
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
                  child: Icon(Icons.person, color: Colors.white, size: 45),
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$handle',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text('$following', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text(' Following   '),
                    Text('$followers', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text(' Followers'),
                  ],
                ),
              ],
            ),
          ),

          // --- ส่วนรายการเมนู (Menu Items) ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.person_outline, color: Colors.black),
                  title: const Text('Other Profile', style: TextStyle(color: Colors.black)),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('Profile 1'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('Profile 2'),
                      onTap: () {},
                    ),
                  ],
                ),
                _buildMenuItem(Icons.bookmark_border, 'Bookmarks', () {
                  // ใส่คำสั่งสำหรับ Bookmarks ตรงนี้
                }),
                _buildMenuItem(Icons.list_alt, 'Lists', () {
                  // ใส่คำสั่งสำหรับ Lists ตรงนี้
                }),
                
                // --- แก้ไขตรงนี้: เมนู Profile ให้กดได้จริง ---
                _buildMenuItem(Icons.person_outline, 'Profile', () {
                  Navigator.pop(context); // ปิด Drawer ก่อนเปิดหน้าใหม่
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        username: username,
                        handle: handle,
                        following: following,
                        followers: followers,
                      ),
                    ),
                  );
                }),
                
                const Divider(),
                _buildMenuItem(Icons.settings_outlined, 'Settings and Privacy', () {
                  Navigator.pop(context); // ปิด Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }),
                _buildMenuItem(Icons.help_outline, 'Help Center', () {}),
              ],
            ),
          ),
          
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // เพิ่มคำสั่ง Logout
            },
          ),
        ],
      ),
    );
  }

  // --- ปรับปรุงฟังก์ชันตัวช่วยให้รับค่า Function เพิ่มเติม ---
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap, // นำคำสั่งมาใช้ที่นี่
    );
  }
}