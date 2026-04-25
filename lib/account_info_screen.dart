import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class AccountInfoScreen extends StatefulWidget {
  final int userId;

  const AccountInfoScreen({super.key, required this.userId});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000/ws'));

    // Send register_connection first
    _channel!.sink.add(json.encode({
      "action": "register_connection",
      "user_id": widget.userId,
    }));

    // Then fetch account info
    _channel!.sink.add(json.encode({
      "action": "fetch_account_info",
      "user_id": widget.userId,
    }));

    // Listen for responses
    _channel!.stream.listen(
      (message) {
        final data = json.decode(message);
        if (data['action'] == 'account_info_response') {
          setState(() {
            userData = data['data'];
            isLoading = false;
          });
        } else if (data['action'] == 'update_success') {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
        setState(() => isLoading = false);
      },
      onDone: () {
        print('WebSocket Closed');
      },
    );
  }

  // --- 2. ฟังก์ชันอัปเดตข้อมูล (UPDATE/PUT) ---
  Future<void> updateUserData(String field, String newValue) async {
    setState(() => isLoading = true);

    try {
      _channel!.sink.add(json.encode({
        "action": "update_account_field",
        "user_id": widget.userId,
        "field": field,
        "content": newValue,
      }));
    } catch (e) {
      setState(() => isLoading = false);
      print("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  // 🟢 แก้ไขฟังก์ชันนี้ให้รองรับการเลือกวันที่
  void _showEditDialog(String title, String field, String currentValue) async {
    // --- ส่วนที่เพิ่ม: ถ้าเป็น Birth Date ให้เปิดปฏิทิน ---
    if (field == 'birth_date') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000, 1, 1), // วันที่เริ่มต้นในปฏิทิน
        firstDate: DateTime(1900), // เก่าสุดที่เลือกได้
        lastDate: DateTime.now(), // ใหม่สุดที่เลือกได้ (ห้ามเลือกอนาคต)
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFFF100), // สีหลักของปฏิทิน
                onPrimary: Colors.black,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        // บังคับ Format เป็น YYYY-MM-DD เพื่อส่ง Backend
        String formattedDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        updateUserData(field, formattedDate);
      }
      return; // จบการทำงานตรงนี้ ไม่ไปเปิดช่องพิมพ์ด้านล่าง
    }

    // --- ส่วนเดิม: สำหรับ Username, Email, Phone, Country ---
    final TextEditingController _editController = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: _editController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter new $title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateUserData(field, _editController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF100),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tweetyYellow,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView(
              children: [
                _buildInfoItem(
                  'Username',
                  '@${userData?['username']}',
                  () => _showEditDialog(
                    'Username',
                    'username',
                    userData?['username'],
                  ),
                ),
                _buildInfoItem(
                  'Email',
                  userData?['email'],
                  () => _showEditDialog('Email', 'email', userData?['email']),
                ),
                _buildInfoItem(
                  'Phone',
                  userData?['phone'],
                  () => _showEditDialog('Phone', 'phone', userData?['phone']),
                ),
                _buildInfoItem(
                  'Country',
                  userData?['country'],
                  () => _showEditDialog(
                    'Country',
                    'country',
                    userData?['country'],
                  ),
                ),
                _buildInfoItem(
                  'Birth Date',
                  userData?['birth_date'],
                  () => _showEditDialog(
                    'Birth Date',
                    'birth_date',
                    userData?['birth_date'],
                  ),
                ),
              ],
            ),
    );
  }

  // เพิ่มพารามิเตอร์ onTap เข้ามาใน Widget
  Widget _buildInfoItem(String title, String value, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap, // 🟢 ทำให้กดได้
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
