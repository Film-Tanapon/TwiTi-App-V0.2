import 'package:flutter/material.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  // สร้างตัวแปรเก็บสถานะการเปิด/ปิดแจ้งเตือน
  bool _mentions = true;
  bool _retweets = false;
  bool _likes = true;
  bool _messages = true;

  static const Color tweetyYellow = Color(0xFFFFF100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Push Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: tweetyYellow,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            _buildHeader("Turn on/off the notifications you want to see."),
            
            _buildSwitchTile(
              title: "Mentions and replies",
              subtitle: "When someone mentions you or replies to your tweet.",
              value: _mentions,
              onChanged: (val) => setState(() => _mentions = val),
            ),
            
            _buildSwitchTile(
              title: "Retweets",
              subtitle: "When someone retweets your content.",
              value: _retweets,
              onChanged: (val) => setState(() => _retweets = val),
            ),
            
            _buildSwitchTile(
              title: "Likes",
              subtitle: "When someone likes your tweets.",
              value: _likes,
              onChanged: (val) => setState(() => _likes = val),
            ),
            
            const Divider(),
            
            _buildSwitchTile(
              title: "Direct Messages",
              subtitle: "When someone sends you a message.",
              value: _messages,
              onChanged: (val) => setState(() => _messages = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black, // สีปุ่มตอนเปิด
      activeTrackColor: tweetyYellow, // สีแถบตอนเปิด
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}