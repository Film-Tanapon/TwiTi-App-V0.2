import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MuteBlockScreen extends StatefulWidget {
  const MuteBlockScreen({super.key});

  @override
  State<MuteBlockScreen> createState() => _MuteBlockScreenState();
}

class _MuteBlockScreenState extends State<MuteBlockScreen> {
  // 1. เตรียมตัวแปรเก็บรายชื่อ
  List<dynamic> blockedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers(); // เรียกดึงข้อมูลทันทีที่เปิดหน้านี้
  }

  // 2. ฟังก์ชันดึงข้อมูลจาก Backend
  Future<void> fetchBlockedUsers() async {
    try {
      // เปลี่ยนเป็น URL API จริงของคุณ 
      final url = Uri.parse('http://localhost:8000/api/settings/blocked-users');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN', // ใส่ Token ถ้าต้องใช้ Login
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          blockedUsers = json.decode(
            response.body,
          ); // สมมติ Backend ส่งมาเป็น [{}, {}]
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 3. ฟังก์ชันสำหรับกดปลดบล็อก (ตัวอย่างการส่งข้อมูลกลับไป Backend)
  Future<void> unblockUser(int userId) async {
    // โค้ดส่งคำขอ DELETE หรือ POST ไปที่ Backend เพื่อปลดบล็อก
    print("Unblocking user: $userId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Muted and blocked accounts',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFF100),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // แสดงตัวหมุนตอนโหลด
          : blockedUsers.isEmpty
          ? const Center(child: Text("No blocked users")) // กรณีไม่มีข้อมูล
          : ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['username'] ?? 'Unknown'),
                  subtitle: const Text('Blocked'),
                  trailing: TextButton(
                    onPressed: () => unblockUser(user['id']),
                    child: const Text(
                      'Unblock',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
