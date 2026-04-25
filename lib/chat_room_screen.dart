import 'dart:typed_data'; // สำหรับ Uint8List
import 'package:image_picker/image_picker.dart'; // อย่าลืมแอด package นี้ใน pubspec.yaml

import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  const ChatRoomScreen({super.key, required this.userName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // สร้างตัวเลือกรูป
  final List<Map<String, dynamic>> _messages = [];

  // 🟢 ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _messages.add({
          'sender': 'me',
          'text': null, // ไม่มีข้อความ
          'imageBytes': imageBytes, // เก็บข้อมูลรูป
          'time': TimeOfDay.now().format(context),
        });
      });
    }
  }

  // 🟢 2. ฟังก์ชันสำหรับกดส่งข้อความ
  void _sendMessage() {
    String text = _msgController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        // เพิ่มข้อความใหม่ลงใน List
        _messages.add({
          'sender': 'me', // สมมติว่าเราเป็นคนส่ง
          'text': text,
          'time': TimeOfDay.now().format(context),
        });
      });
      _msgController.clear(); // ล้างช่องพิมพ์
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 🟢 3. ส่วนแสดงรายการข้อความ
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      "Start a conversation with ${widget.userName}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      bool isMe = msg['sender'] == 'me';

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            // ถ้าเราส่งให้เป็นสีเหลือง ถ้าเขาส่งให้เป็นสีเทาอ่อน
                            color: isMe
                                ? const Color(0xFFFFF100)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: Radius.circular(isMe ? 15 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 15),
                            ),
                          ),
                          child: Text(
                            msg['text'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // แถบพิมพ์ข้อความด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // 🟢 เปลี่ยน Icon เป็น IconButton ให้กดได้
                IconButton(
                  icon: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFFFFF100),
                  ),
                  onPressed: _pickImage, // เรียกฟังก์ชันเลือกรูป
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Start a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFF100)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
