import 'package:flutter/material.dart';

void showPostDialog({
  required BuildContext context,
  required TextEditingController controller,
  required VoidCallback onSend, // รับฟังก์ชัน _sendMessage ของแต่ละหน้ามาใช้
  required Color tweetyYellow,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Tweet'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "What's happening?",
          border: OutlineInputBorder(),
        ),
        minLines: 2,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onSend, // เรียกใช้ฟังก์ชันส่งข้อความที่ส่งมา
          style: ElevatedButton.styleFrom(
            backgroundColor: tweetyYellow, 
            foregroundColor: Colors.black
          ),
          child: const Text('Tweet'),
        ),
      ],
    ),
  );
}