import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 1. import http
import 'dart:convert'; // สำหรับแปลง json

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  // สร้างตัวแปรเก็บข้อมูล (เริ่มต้นเป็น null หรือค่าว่าง)
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // 2. เรียกฟังก์ชันดึงข้อมูลเมื่อเปิดหน้าจอ
  }

  // 3. ฟังก์ชันดึงข้อมูลจาก Backend
  Future<void> fetchUserData() async {
    try {
      // ใส่ URL ของ API Backend ของคุณที่นี่
      final url = Uri.parse('https://api.example.com/user/profile'); 
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer YOUR_TOKEN_HERE'}, // ถ้ามีระบบ Login
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        // จัดการกรณี Error
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account information', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: tweetyYellow,
        centerTitle: true,
      ),
      // 4. แสดง Loading Spinner ขณะรอข้อมูล
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: fetchUserData, // ลากลงเพื่อ Refresh ข้อมูลได้
            child: ListView(
              children: [
                // 5. เอาข้อมูลจากตัวแปร userData มาแสดง
                _buildInfoItem('Username', '@${userData?['username'] ?? 'n/a'}'),
                _buildInfoItem('Email', userData?['email'] ?? 'n/a'),
                _buildInfoItem('Phone', userData?['phone'] ?? 'Add phone number'),
                _buildInfoItem('Country', userData?['country'] ?? 'Thailand'),
                _buildInfoItem('Birth Date', userData?['birth_date'] ?? 'Not set'),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}