import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CreateSubAccountScreen extends StatefulWidget {
  final String mainEmail; // รับมาจาก Drawer

  const CreateSubAccountScreen({super.key, required this.mainEmail});

  @override
  State<CreateSubAccountScreen> createState() => _CreateSubAccountScreenState();
}

class _CreateSubAccountScreenState extends State<CreateSubAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  final Color _tweetyYellow = const Color(0xFFFFF100);

  // ฟังก์ชันส่งข้อมูลไป Backend
  Future<void> _createProfile() async {
    final String username = _usernameController.text.trim();
    final String handle = _handleController.text.trim();

    // 1. Validation เบื้องต้น
    if (username.isEmpty || handle.isEmpty) {
      _showSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. ดึงข้อมูลจำเป็นจาก Secure Storage (เหมือนใน PostScreen)
      String? token = await _storage.read(key: 'token');
      String? mainUserId = await _storage.read(key: 'user_id');

      // 3. ยิง API (Endpoint ของคุณ)
      final url = Uri.parse('https://tweety-server.onrender.com/create-sub-account');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', // ส่ง token ถ้ามี
        },
        body: jsonEncode({
          'main_user_id': mainUserId,      // ส่ง ID บัญชีหลัก
          'main_email': widget.mainEmail,  // ส่ง Email บัญชีหลัก
          'new_username': username,
          'new_handle': handle,
        }),
      );

      // 4. ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('สร้างโปรไฟล์ย่อยสำเร็จ!');
          // ดีเลย์นิดนึงเพื่อให้ User เห็น SnackBar ก่อนปิดหน้า
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true); // ส่งค่า true กลับไปบอกว่ามีการสร้างใหม่
          });
        }
      } else {
        // ดึง Error Message จาก Backend (ถ้ามี)
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'ไม่สามารถสร้างโปรไฟล์ได้');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception:', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Create New Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _tweetyYellow,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SingleChildScrollView( // ป้องกัน Keyboard บังช่องกรอก
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.black,
                child: Icon(Icons.person_add_alt_1, size: 45, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),

            // แสดงข้อมูล Account หลัก
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Linked Account', 
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(widget.mainEmail, 
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'ชื่อโปรไฟล์ใหม่ของคุณ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _tweetyYellow, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Handle (@)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                hintText: 'เช่น user_new_123',
                prefixText: '@ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _tweetyYellow, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tweetyYellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  disabledBackgroundColor: _tweetyYellow.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Confirm and Create',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}