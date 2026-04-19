import 'package:flutter/material.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  // สมมติข้อมูลโพสต์ที่ดึงมาจาก Database
  List<Map<String, dynamic>> bookmarkPosts = List.generate(5, (index) => {
    'post_id': index,
    'user_name': 'User Name $index',
    'handle': '@handle_$index',
    'content': 'นี่คือข้อความที่ถูกบันทึกไว้ใน Bookmarks ของคุณ รายการที่ $index',
    'likes': 20,
    'reposts': 5,
    'replies': 12,
    'is_liked': false,
    'is_reposted': false,
    'is_bookmarked': true, // หน้า Bookmark ค่าเริ่มต้นควรเป็น true
  });

  // ฟังก์ชันสลับสถานะต่างๆ
  void _toggleAction(int index, String field) {
    setState(() {
      bookmarkPosts[index][field] = !bookmarkPosts[index][field];
      // ตัวอย่าง: ถ้ากด Like ก็เพิ่ม/ลดจำนวนเลขได้ตรงนี้
      if (field == 'is_liked') {
        bookmarkPosts[index]['likes'] += bookmarkPosts[index][field] ? 1 : -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Bookmarks', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('@tweety_official', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        backgroundColor: tweetyYellow,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: ListView.separated(
          itemCount: bookmarkPosts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final post = bookmarkPosts[index];
            return _buildBookmarkItem(post, index);
          },
        ),
      ),
    );
  }

  Widget _buildBookmarkItem(Map<String, dynamic> post, int index) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post['user_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('${post['handle']} · 2h', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Text(post['content'], style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                
                // --- ส่วนปุ่มกดต่างๆ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reply
                    _buildIconButton(Icons.chat_bubble_outline, post['replies'].toString(), Colors.grey, () {}),
                    
                    // 1. Like
                    _buildIconButton(
                      post['is_liked'] ? Icons.favorite : Icons.favorite_border,
                      post['likes'].toString(),
                      post['is_liked'] ? Colors.red : Colors.grey,
                      () => _toggleAction(index, 'is_liked'),
                    ),

                    // 2. Repost
                    _buildIconButton(
                      Icons.repeat,
                      post['reposts'].toString(),
                      post['is_reposted'] ? Colors.green : Colors.grey,
                      () => _toggleAction(index, 'is_reposted'),
                    ),

                    // 3. Bookmark
                    _buildIconButton(
                      post['is_bookmarked'] ? Icons.bookmark : Icons.bookmark_border,
                      '',
                      post['is_bookmarked'] ? Colors.blue : Colors.grey,
                      () => _toggleAction(index, 'is_bookmarked'),
                    ),

                    // Share
                    _buildIconButton(Icons.ios_share, '', Colors.grey, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper สำหรับสร้างปุ่มที่มี Text ต่อท้าย
  Widget _buildIconButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}