import 'package:flutter/material.dart';
import 'settings_screen.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account information', // หัวข้อภาษาอังกฤษ
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tweetyYellow,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildInfoItem('Username', '@admin'),
          _buildInfoItem('Phone', 'Add phone number'), // ตัวอย่างกรณีไม่มีข้อมูล
          _buildInfoItem('Email', 'admin@gmail.com'),
          _buildInfoItem('Verified', 'No'),
          _buildInfoItem('Protected Posts', 'No'),
          _buildInfoItem('Account Creation', '7 Apr 2025, 18:20:26'),
          _buildInfoItem('Country', 'Thailand'),
          _buildInfoItem('Languages', 'Thai, English, Japanese'),
          _buildInfoItem('Gender', 'Male'),
          _buildInfoItem('Birth Date', '14 Nov 2005'),
          _buildInfoItem('Age', '20'),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างแต่ละแถวข้อมูลตามรูปแบบในรูปภาพที่ 2
  Widget _buildInfoItem(String title, String value) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          onTap: () {
            // ใส่คำสั่งเมื่อกดเข้าไปแก้ไขข้อมูลแต่ละตัวได้ที่นี่
          },
        ),
        const Divider(height: 1, indent: 16), // เส้นคั่นบางๆ ตามสไตล์แอป
      ],
    );
  }
}