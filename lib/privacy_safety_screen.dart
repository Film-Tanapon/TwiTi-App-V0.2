import 'package:flutter/material.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy and Safety',
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
            _buildSectionTitle('Your Activity'),
            _buildListItem(
              Icons.article_outlined,
              'Content you see',
              'Decide what you see on TwiTi based on your interests.',
            ),
            _buildListItem(
              Icons.volume_off_outlined,
              'Mute and block',
              'Manage the accounts, words, and notifications that you’ve muted or blocked.',
            ),
            const Divider(),
            _buildSectionTitle('Data sharing and off-TwiTi activity'),
            _buildListItem(
              Icons.location_on_outlined,
              'Location information',
              'Manage the location information TwiTi uses.',
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

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        // เพิ่ม Navigation ไปยังหน้าย่อยอื่นๆ ได้ที่นี่
      },
    );
  }
}