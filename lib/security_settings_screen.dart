import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'login_history_screen.dart';

class SecuritySettingsScreen extends StatelessWidget {
  final int userId;

  const SecuritySettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security and access',
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
            _buildSectionHeader(
              'Manage your account\'s security and keep track of your account\'s usage including apps that you have connected to your account.',
            ),
            
            _buildSecurityItem(
              Icons.lock_outline,
              'Change password',
              'Change your password at any time to keep your account secure.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(userId: userId),
                  ),
                );
              },
            ),

            const Divider(height: 1), // เส้นคั่นนิดนึงให้ดูสวย
            _buildSecurityItem(
              Icons.history,
              'Login history',
              'See and manage your active sessions.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ส่วนหัวข้ออธิบายรายละเอียดของหน้า
  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}