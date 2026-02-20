import 'dart:io';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String handle;
  final int following;
  final int followers;
  // --- เพิ่มตัวแปรสำหรับรับรายการโพสต์ ---
  //final List<Map<String, dynamic>> userPosts;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.handle,
    required this.following,
    required this.followers,
    //required this.userPosts, // บังคับให้ส่งค่ามา
  });

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    // กรองเอาเฉพาะโพสต์ที่เป็นของ User คนนี้ (ป้องกันกรณีในหน้า Feed มีโพสต์คนอื่น)
    //final myOwnPosts = userPosts.where((post) => post['username'] == username).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: tweetyYellow,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.black), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            // --- ส่วน Header (เหมือนเดิมของคุณ) ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 60, color: tweetyYellow),
                Positioned(
                  top: 10,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFE1E1E1),
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('@$handle', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("-bio-", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text('$following ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Following    '),
                      Text('$followers ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Followers'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- TabBar ---
            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: tweetyYellow,
              tabs: [
                Tab(text: 'Post'),
                Tab(text: 'Comment'),
                Tab(text: 'Favorites'),
                Tab(text: 'Media'),
              ],
            ),

            // --- เนื้อหาใน Tab ---
            /*Expanded(
              child: TabBarView(
                children: [
                  _buildPostList(myOwnPosts), // ส่งโพสต์ที่กรองแล้วไปแสดง
                  const Center(child: Text("No Comments yet")),
                  const Center(child: Text("No Favorites yet")),
                  const Center(child: Text("No Media yet")),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  // --- ฟังก์ชันสร้างรายการโพสต์จากข้อมูลจริง ---
  Widget _buildPostList(List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text("You haven't posted anything yet."));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
              title: Row(
                children: [
                  Text(post['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(post['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(post['content'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 15)),
                  // ถ้ามีรูปภาพให้แสดงรูปด้วย
                  if (post['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(post['image']), fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                  Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                  Icon(Icons.repeat, size: 18, color: Colors.grey),
                  Icon(Icons.ios_share, size: 18, color: Colors.grey),
                ],
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}