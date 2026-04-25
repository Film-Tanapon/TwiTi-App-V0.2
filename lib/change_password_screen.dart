import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // เตรียมไว้สำหรับเรียกใช้ API จริง

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // สร้างตัวควบคุมสำหรับดึงค่าจากช่องกรอก
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ฟังก์ชันแสดง Popup แจ้งเตือน (เปลี่ยนเป็นภาษาอังกฤษ)
  void _showNotification(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันหลักสำหรับส่งข้อมูลไปอัปเดต
  Future<void> _handlePasswordUpdate() async {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // 1. ตรวจสอบว่ากรอกครบทุกช่องไหม
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showNotification('Error', 'Please fill in all fields.');
      return;
    }

    // 2. ตรวจสอบว่ารหัสใหม่กับยืนยันรหัสตรงกันไหม
    if (newPassword != confirmPassword) {
      _showNotification('Error', 'New passwords do not match.');
      return;
    }

    // 3. เริ่มต้นการเชื่อมต่อ Backend (ส่วนนี้คือ Logic จริงที่จะใช้ส่งข้อมูล)
    try {
      print("System: Sending update request to API...");

      /* // โครงสร้างการยิง API จริงจะเป็นประมาณนี้:
      var response = await http.post(
        Uri.parse('https://your-api-url.com/change-password'),
        body: {
          'old_password': currentPassword,
          'new_password': newPassword,
        },
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      if (response.statusCode == 200) {
        // กรณีหลังบ้านตอบกลับว่าสำเร็จ
        _showNotification('Success', 'Your password has been updated.');
      } else if (response.statusCode == 401) {
        // กรณีหลังบ้านแจ้งว่ารหัสผ่านปัจจุบันไม่ถูกต้อง (เทียบกับ Database)
        _showNotification('Error', 'Incorrect current password.');
      } else {
        // กรณีเกิดข้อผิดพลาดอื่นๆ จาก Server
        _showNotification('Error', 'Something went wrong. Please try again.');
      }
      */

    } catch (e) {
      // กรณีเชื่อมต่อ Server ไม่ได้ (เช่น เน็ตหลุด)
      _showNotification('Connection Error', 'Unable to reach the server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFFFF100), // สี Tweety Yellow
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // ป้องกันหน้าจอทับซ้อนเวลาคีย์บอร์ดเด้งขึ้นมา
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handlePasswordUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}