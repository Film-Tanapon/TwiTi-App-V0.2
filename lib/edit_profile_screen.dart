import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; 

class EditProfileScreen extends StatefulWidget {
  final int myUserId; 
  final String currentUsername;
  final String currentHandle;
  final WebSocketChannel? channel; 

  const EditProfileScreen({
    super.key,
    required this.myUserId,
    required this.currentUsername,
    required this.currentHandle,
    this.channel,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); 

  @override
  void initState() {
    super.initState();
    // นำค่าเดิมมาตั้งเป็นค่าเริ่มต้นในช่องกรอก
    _nameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty!')),
      );
      return;
    }

    // 1. ส่งข้อมูลไป Backend ผ่าน WebSocket
    final msg = {
      'action': 'update_profile', 
      'user_id': widget.myUserId,
      'username': newName,
      // 'profile_image_url': ... (ถ้ามีทำระบบอัปโหลดรูป ค่อยส่ง URL เข้ามาตรงนี้)
    };
    
    try {
      widget.channel?.sink.add(jsonEncode(msg));

      // 2. บันทึกค่าใหม่ลงในเครื่อง (Local Storage) เพื่อให้หน้าอื่นๆ ดึงไปใช้ต่อได้ทันที
      await _storage.write(key: 'username', value: newName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      
      // 3. ปิดหน้าจอ และส่งค่าใหม่กลับไปให้หน้า ProfileScreen เพื่อให้มัน Refresh ตัวเอง
      Navigator.pop(context, {'newName': newName});
      
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10.0, bottom: 10.0),
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนแก้ไขรูปภาพ ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Header / Cover Image
                Container(
                  height: 150,
                  width: double.infinity,
                  color: tweetyYellow,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined, color: Colors.black54, size: 30),
                      onPressed: () {
                        // TODO: ฟังก์ชันเปลี่ยนรูปปก
                      },
                    ),
                  ),
                ),
                // Profile Avatar
                Positioned(
                  top: 100,
                  left: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white70),
                        onPressed: () {
                          // TODO: ฟังก์ชันเปลี่ยนรูปโปรไฟล์
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // --- ส่วนกรอกข้อมูล ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: widget.currentHandle,
                    enabled: false, 
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.grey),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
      ),
    );
  }
}