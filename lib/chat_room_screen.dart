import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  const ChatRoomScreen({super.key, required this.userName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(radius: 15, backgroundColor: Colors.black, child: Icon(Icons.person, size: 20, color: Colors.white)),
            const SizedBox(width: 10),
            Text(widget.userName, style: const TextStyle(color: Colors.black, fontSize: 16)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(child: Text("Start a conversation with ${widget.userName}", style: TextStyle(color: Colors.grey))),
          ),
          // แถบพิมพ์ข้อความด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: Color(0xFFFFF100)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Start a message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFF100)),
                  onPressed: () {
                    _msgController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}