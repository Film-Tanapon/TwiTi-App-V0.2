import 'package:flutter/material.dart';
import 'post_utils.dart';
import 'notification_screen.dart'; 
import 'chat_list_screen.dart';    
import 'drawer.dart'; 
import 'post_screen.dart'; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> _searchHistory = []; 
  final TextEditingController _notiController = TextEditingController();
  final Color tweetyYellow = const Color(0xFFFFF100);

  String myName = "TwiTi User";
  String myHandle = "TwiTi_official";
  String myEmail = "user@example.com";
  int myFollowing = 120;
  int myFollowers = 5500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(
        username: myName,
        handle: myHandle,
        email: myEmail,
        following: myFollowing,
        followers: myFollowers,
      ),
      appBar: AppBar(
        backgroundColor: tweetyYellow,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _searchHistory.insert(0, value.trim()); 
                });
              }
            },
            decoration: const InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero, 
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchHistory.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Latest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchHistory.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                          Text(_searchHistory[index], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Trends", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            for (int i = 1; i <= 6; i++) ...[
              ListTile(
                title: Text("# Trend $i", style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text("Trending in Thailand"),
                onTap: () {}, 
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
      
      // --- ส่วน BottomNavigationBar ที่แก้ไขใหม่ ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tweetyYellow,
          border: const Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. ปุ่ม Home: ใช้ popUntil เพื่อล้าง stack และกลับหน้าแรก
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 30, color: Colors.black54), 
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            
            // 2. ปุ่ม Search: เปลี่ยนเป็นไอคอนทึบ (Icons.search) และสีดำเข้ม
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.black), 
              onPressed: () {
                // อยู่หน้านี้อยู่แล้ว ไม่ต้องทำอะไร
              }
            ),
            
            // 3. ปุ่มบวก
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.black54),
              onPressed: () => showPostDialog(
                context: context,
                controller: _notiController,
                onSend: () {
                  _notiController.clear();
                  Navigator.pop(context);
                },
                tweetyYellow: tweetyYellow,
              ),
            ),
            
            // 4. ปุ่มแจ้งเตือน: ใช้ pushReplacement เพื่อป้องกันหน้าซ้อน
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 30, color: Colors.black54), 
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const NotificationScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            ),
            
            // 5. ปุ่มกล่องจดหมาย: ใช้ pushReplacement เพื่อป้องกันหน้าซ้อน
            IconButton(
              icon: const Icon(Icons.mail_outline, size: 30, color: Colors.black54), 
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const ChatListScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}