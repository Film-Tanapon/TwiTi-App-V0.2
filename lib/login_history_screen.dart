import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  
  // 🟢 ฟังก์ชันดึงข้อมูล Last Login จาก Backend (จะส่งกลับมาเป็น Map อันเดียว)
  Future<Map<String, dynamic>> _fetchLastLogin() async {
    print("System: Fetching last login timestamp...");
    
    /* ตัวอย่างเมื่อเชื่อมต่อจริง:
    final response = await http.get(Uri.parse('https://api.yourproject.com/user/last-login'));
    if (response.statusCode == 200) {
      return json.decode(response.body); // สมมติส่งมาเป็น {"last_login": "2026-04-25 15:30"}
    }
    */

    // คืนค่าว่างไว้ก่อนเพื่อทดสอบ UI
    return {}; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFFFF100),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchLastLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          // ถ้าไม่มีข้อมูล หรือเพื่อนยังไม่ได้ทำฟิลด์นี้
          if (!snapshot.hasData || snapshot.data!['last_login'] == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No recent login data found.'),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // การ์ดแสดงผล Last Login
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFF100),
                        child: Icon(Icons.access_time_filled, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Successful Login',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          // แสดงเวลาที่ดึงมาจาก Database
                          Text(
                            data['last_login'] ?? 'Not available',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Note: This shows the most recent time you accessed your account.',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}