import 'package:flutter/material.dart';
import 'profile_screen.dart'; 
import 'settings_screen.dart';
import 'create_sub_account_screen.dart';
import 'bookmarks_screen.dart';

class MyDrawer extends StatelessWidget {
  final int userId;
  final String username;
  final String handle;
  final String email;
  final int following;
  final int followers;

  const MyDrawer({
    super.key,
    required this.userId,
    required this.username,
    required this.handle,
    required this.email,
    required this.following,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Drawer(
      child: Column(
        children: [
          // ส่วนหัวของ Drawer (User Profile Header)
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
                  handle,
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

          // รายการเมนูต่างๆ
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ส่วนสำหรับจัดการโปรไฟล์อื่นๆ และสร้างโปรไฟล์ย่อย
                ExpansionTile(
                  leading: const Icon(Icons.group_outlined, color: Colors.black),
                  title: const Text('Other Profile', style: TextStyle(color: Colors.black)),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      title: const Text(
                        'Create New Profile',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Add a sub-account using this email'),
                      onTap: () async {
                        Navigator.pop(context); // ปิด Drawer ก่อนเปลี่ยนหน้า
                        
                        // นำทางไปหน้าสร้างโปรไฟล์ย่อย และรอรับผล (ถ้ามีการส่งค่ากลับมา)
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateSubAccountScreen(mainEmail: email),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                _buildMenuItem(Icons.bookmark_border, 'Bookmarks', () {
                  Navigator.pop(context); // ปิด Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                  );
                }),
                _buildMenuItem(Icons.list_alt, 'Lists', () {}),
                
                _buildMenuItem(Icons.person_outline, 'Profile', () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        targetUserId: userId ?? 0,
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
                  Navigator.pop(context); 
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
              // เพิ่มฟังก์ชัน Logout ตรงนี้ในอนาคต
            },
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับสร้างเมนู ListTile
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap, 
    );
  }
}