import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

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
              Icons.shield_outlined,
              'Security',
              'Manage your account’s security.',
              onTap: () {
                // TODO: ไปหน้าตั้งค่ารหัสผ่าน หรือ 2FA
              },
            ),
            
            _buildSecurityItem(
              Icons.devices_other,
              'Connected apps',
              'Manage the apps that you have connected to your account to report and perform actions.',
              onTap: () {
                // TODO: ไปหน้าจัดการแอปที่เชื่อมต่อไว้
              },
            ),

            _buildSecurityItem(
              Icons.history,
              'Sessions',
              'See and manage your active sessions on different browsers and devices.',
              onTap: () {
                // TODO: ไปหน้าดูประวัติการ Login
              },
            ),

            const Divider(),
            _buildSectionTitle('Data and permissions'),
            
            _buildSecurityItem(
              Icons.cloud_download_outlined,
              'Download an archive of your data',
              'Get insights into the type of information stored for your account.',
              onTap: () {},
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