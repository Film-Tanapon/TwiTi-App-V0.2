import 'package:flutter/material.dart';
import 'account_info_screen.dart';
import 'security_settings_screen.dart';
import 'privacy_safety_screen.dart';
import 'notifications_settings_screen.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends StatelessWidget {
  final int userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings and Privacy',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: tweetyYellow, 
        elevation: 0, 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            _buildSectionTitle('Account'),
            _buildSettingsItem(
              Icons.person_outline, 
              'Your account', 
              'See information about your account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountInfoScreen(userId: userId),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              Icons.vpn_key_outlined,
              'Security and Account access',
              'Manage your account\'s security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecuritySettingsScreen(userId: userId),
                  ),
                );
              },
            ),
            
            const Divider(),
            _buildSectionTitle('Privacy'),
            _buildSettingsItem(
              Icons.lock_outline, 
              'Privacy and Safety', 
              'Manage what information you see and share',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacySafetyScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              Icons.notifications_none, 
              'Notifications', 
              'Select the kinds of notifications you get',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsSettingsScreen(),
                  ),
                );
              },
            ),

            // 🟢 เพิ่มส่วน Log out และ Version
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      print("Logging out...");
                      // ใช้ pushAndRemoveUntil เพื่อล้างประวัติการกด back กลับมาหน้าเดิม
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                        (route) =>
                            false, // บรรทัดนี้คือการบอกว่า "ไม่ให้เหลือหน้าเก่าไว้เลย"
                      );
                    },
                    child: const Text(
                      'Log out',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TwiTi for Web v1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // จุดที่แก้ไข: เชื่อมโยงค่า onTap ให้ทำงานจริง
  Widget _buildSettingsItem(IconData icon, String title, String? subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap, 
    );
  }
}