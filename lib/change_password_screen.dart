import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // เตรียมไว้สำหรับเรียกใช้ API จริง
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final int userId;

  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // สร้างตัวควบคุมสำหรับดึงค่าจากช่องกรอก
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  WebSocketChannel? _channel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('wss://twiti-server-v0-2.onrender.com/ws'));

    // Send register_connection first
    _channel!.sink.add(json.encode({
      "action": "register_connection",
      "user_id": widget.userId,
    }));

    // Listen for responses
    _channel!.stream.listen(
      (message) {
        print('Received WebSocket message: $message'); // Debug log
        final data = json.decode(message);
        final action = data['action'];
        
        if (action == 'password_changed') {
          setState(() => _isLoading = false);
          _showNotification('Success', 'Password changed successfully!');
          // Clear the form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else if (action == 'error') {
          setState(() => _isLoading = false);
          _showNotification('Error', data['message'] ?? 'An error occurred');
        } else {
          print('Unknown action received: $action'); // Debug log for unknown actions
          setState(() => _isLoading = false);
          _showNotification('Error', 'Unknown response from server: $action');
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
        setState(() => _isLoading = false);
        _showNotification('Connection Error', 'Unable to reach the server.');
      },
      onDone: () {
        print('WebSocket Closed');
      },
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  // ฟังก์ชันแสดงการแจ้งเตือน
  void _showNotification(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: title == 'Error' ? Colors.red : Colors.green,
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

    // 3. ตรวจสอบความยาวรหัสผ่านขั้นต่ำ
    if (newPassword.length < 6) {
      _showNotification('Error', 'New password must be at least 6 characters long.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _channel!.sink.add(json.encode({
        "action": "change_password",
        "user_id": widget.userId,
        "old_password": currentPassword,
        "password": newPassword,
      }));
    } catch (e) {
      setState(() => _isLoading = false);
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
                onPressed: _isLoading ? null : _handlePasswordUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
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