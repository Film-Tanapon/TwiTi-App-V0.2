import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CreateSubAccountScreen extends StatefulWidget {
  final String mainEmail;

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

  Future<void> _createProfile() async {
    final String username = _usernameController.text.trim();
    final String handle = _handleController.text.trim();

    if (username.isEmpty || handle.isEmpty) {
      _showSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      /* // ==========================================
      // 🟢 ส่วนเชื่อมต่อ BACKEND จริง (คอมเมนต์ไว้รอใช้)
      // ==========================================
      String? token = await _storage.read(key: 'token');
      String? mainUserId = await _storage.read(key: 'user_id');
      
      final url = Uri.parse('https://tweety-server.onrender.com/create-sub-account');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'main_user_id': mainUserId,
          'main_email': widget.mainEmail,
          'new_username': username,
          'new_handle': handle.replaceAll('@', ''),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
          _showSnackBar('สร้างโปรไฟล์ย่อยสำเร็จ!');
          Navigator.pop(context, true);
          return; // จบการทำงานตรงนี้ถ้าใช้ Backend
      }
      */

      // ==========================================
      // 🟡 ส่วน MOCK DATA สำหรับทดสอบ (ใช้งานอยู่ตอนนี้)
      // ==========================================
      String? existingData = await _storage.read(key: 'mock_sub_accounts');
      List<dynamic> subAccounts = (existingData != null) ? jsonDecode(existingData) : [];

      subAccounts.add({
        'user_id': DateTime.now().millisecondsSinceEpoch,
        'username': username,
        'handle': handle.replaceAll('@', ''),
      });

      await _storage.write(key: 'mock_sub_accounts', value: jsonEncode(subAccounts));
      await Future.delayed(const Duration(seconds: 1)); // จำลองโหลด

      if (mounted) {
        _showSnackBar('สร้างโปรไฟล์ "$username" สำเร็จ! (Mock Mode)');
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _tweetyYellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(Icons.person_add_alt_1, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Text('Linked Account', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(widget.mainEmail, style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Sub-Account Username',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: _tweetyYellow, width: 2)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                hintText: 'handle name',
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 20, right: 2),
                  child: Text("@", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: _tweetyYellow, width: 2)),
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
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : const Text('Confirm and Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}