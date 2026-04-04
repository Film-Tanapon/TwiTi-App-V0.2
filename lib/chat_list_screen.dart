import 'package:flutter/material.dart';
import 'chat_room_screen.dart';
import 'search_screen.dart';         
import 'notification_screen.dart';   
import 'post_utils.dart';           
import 'drawer.dart'; // 1. อย่าลืม Import ไฟล์ MyDrawer ของคุณ

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // 2. กำหนดข้อมูลจำลองสำหรับส่งให้ Drawer (เหมือนหน้าอื่นๆ)
  String myName = "TwiTi User";
  String myHandle = "TwiTi_official";
  String myEmail = "user@example.com";
  int myFollowing = 120;
  int myFollowers = 5500;

  @override
  Widget build(BuildContext context) {
    final Color tweetyYellow = const Color(0xFFFFF100);

    final List<Map<String, String>> chatItems = [
      {'name': 'John Doe', 'message': 'สวัสดีครับ สนใจโปรเจกต์นี้มาก!', 'time': '10:30 AM'},
      {'name': 'Flutter Dev', 'message': 'ส่งโค้ดให้แล้วนะ ลองเช็คดู', 'time': 'Yesterday'},
      {'name': 'สายกิน รีวิว', 'message': 'ร้านนี้อร่อยจริง คอนเฟิร์ม!', 'time': 'Feb 12'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 3. เพิ่ม MyDrawer เข้าไปใน Scaffold
      drawer: MyDrawer(
        username: myName,
        handle: myHandle,
        email: myEmail,
        following: myFollowing,
        followers: myFollowers,
    
      ),

      appBar: AppBar(
        backgroundColor: tweetyYellow,
        elevation: 1,
        automaticallyImplyLeading: false, 
        
        // 4. ใช้ Builder เพื่อให้สามารถเรียก Scaffold.of(context).openDrawer() ได้
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(), 
          ),
        ),
        
        title: const Text(
          'Messages', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: chatItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = chatItems[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(chat['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chat['message']!, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(chat['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatRoomScreen(userName: chat['name']!)),
              );
            },
          );
        },
      ),
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          backgroundColor: tweetyYellow,
          elevation: 2,
          child: const Icon(Icons.mail_outline, color: Colors.black),
          onPressed: () {
            // ฟังก์ชันสำหรับเริ่มแชทใหม่
          },
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tweetyYellow,
          border: const Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 30, color: Colors.black54), 
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.black54), 
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.black54), 
              onPressed: () {
                showPostDialog(
                  context: context,
                  controller: TextEditingController(),
                  onSend: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post Successful!')),
                    );
                  },
                  tweetyYellow: tweetyYellow,
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 30, color: Colors.black54), 
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.mail, size: 30, color: Colors.black), 
              onPressed: () {}
            ),
          ],
        ),
      ),
    );
  }
}