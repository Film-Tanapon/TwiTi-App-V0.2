import 'package:flutter/material.dart';
import 'drawer.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'post_utils.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

// รวม State เป็นอันเดียว และเพิ่ม TickerProvider สำหรับสลับหน้า
class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  
  late TabController _tabController; // ตัวควบคุมหน้า All / Mentions
  final TextEditingController _notiController = TextEditingController();
  final Color tweetyYellow = const Color(0xFFFFF100);
  final Color lightYellow = const Color(0xFFFFFFCC);

  // ข้อมูลสมมติสำหรับหน้า All (ใส่เพื่อให้เห็นตอนรัน)
  List<Map<String, dynamic>> _allNotifications = [
    {'user': 'John Doe', 'type': 'reply', 'content': 'สวัสดีครับ!'},
    {'user': 'Jane Smith', 'type': 'follow', 'content': ''},
  ];

  // ข้อมูลสมมติสำหรับหน้า Mentions (ปล่อยว่างไว้ตามรูปที่คุณส่งมา)
  List<Map<String, dynamic>> _mentions = [];

  @override
  void initState() {
    super.initState();
    // ตั้งค่าให้สลับได้ 2 หน้า
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(
        username: "TwiTi User",
        handle: "TwiTi_official",
        email: "user@example.com",
        following: 120,
        followers: 5500,
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
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        // เปลี่ยนจาก Row ธรรมดา เป็น TabBar เพื่อให้กดสลับได้จริง
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: lightYellow,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black, // เส้นใต้สีดำ
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Mentions"),
              ],
            ),
          ),
        ),
      ),

      // ใช้ TabBarView เพื่อให้เนื้อหาเปลี่ยนไปตามที่เรากด All หรือ Mentions
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(_allNotifications), // หน้า All
          _buildListView(_mentions),         // หน้า Mentions
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF100),
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ปุ่ม Home
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 30, color: Colors.black54), 
              onPressed: () {
                // คำสั่งนี้จะล้างหน้าจอที่ซ้อนอยู่ทั้งหมดทิ้ง แล้วกลับไปหน้าแรกสุด
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),

            // 2. ปุ่ม Search
            IconButton(
              icon: const Icon(Icons.search, size: 30,color: Colors.black54),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
            ),

            // 3. ปุ่ม Add
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 32,color: Colors.black54),
              onPressed: () => showPostDialog(
                context: context,
                controller: _notiController, // ใช้ controller ที่ประกาศไว้ด้านบน
                onSend: () {
                  // Logic เมื่อกดปุ่ม Tweet ในหน้าแจ้งเตือน
                  _notiController.clear(); // ล้างข้อความ
                  Navigator.pop(context); // ปิด Dialog
      
                  // (Option) ถ้าอยากให้มีแจ้งเตือนว่าโพสต์แล้ว
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post Successful!')),
                  );
                },
                tweetyYellow: tweetyYellow, // ส่งสีเหลืองเข้าไป
              ),
            ),

            // 4. ปุ่ม Notifications (รูปทึบ เพราะอยู่หน้านี้ ไม่ต้องมี onPressed)
            const IconButton(
              icon: const Icon(Icons.notifications, size: 30, color: Colors.black),
              onPressed: null,
            ),

            // 5. ปุ่ม Mail (ไปหน้าแชท) - ใช้ IconButton แทน Icon เฉยๆ
            IconButton(
              icon: const Icon(Icons.mail_outline, size: 30,color: Colors.black54),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างรายการแจ้งเตือน (เช็คด้วยว่าถ้าว่างให้โชว์ No notifications)
  Widget _buildListView(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildNotificationItem(
          icon: item['type'] == 'reply' ? Icons.chat_bubble_outline : Icons.person_add_alt_1,
          title: "${item['user']} ${item['type'] == 'reply' ? 'Replied to you' : 'Followed you'}",
          subtitle: item['content'],
        );
      },
    );
  }

  Widget _buildNotificationItem({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, size: 35, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}