import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'profile_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _bookmarkPosts = [];
  int myUserId = 0;
  String myHandle = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    const storage = FlutterSecureStorage();
    final idStr = await storage.read(key: 'user_id');
    final handle = await storage.read(key: 'handle') ?? '';
    myUserId = int.tryParse(idStr ?? '0') ?? 0;
    myHandle = handle;

    _channel = WebSocketChannel.connect(Uri.parse('wss://twiti-server-v0-2.onrender.com/ws'));

    // ส่ง action เพื่อดึง bookmarks
    _channel?.sink.add(jsonEncode({
      'action': 'fetch_bookmarks',
      'user_id': myUserId,
    }));

    _channel?.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['action'] == 'bookmarks_response') {
        if (mounted) {
          setState(() {
            _bookmarkPosts = List<Map<String, dynamic>>.from(
              (data['data'] ?? []).map((e) => Map<String, dynamic>.from(e)),
            );
            _isLoading = false;
          });
        }
      }

      // รับ update stats realtime (like/repost count)
      if (data['action'] == 'update_post_stats') {
        final updatedData = data['data'];
        if (updatedData == null) return;
        if (mounted) {
          setState(() {
            int idx = _bookmarkPosts.indexWhere(
              (m) => m['post_id'] == updatedData['post_id'],
            );
            if (idx != -1) {
              _bookmarkPosts[idx]['likes_count'] = updatedData['likes_count'];
              _bookmarkPosts[idx]['reposts_count'] = updatedData['reposts_count'];
            }
          });
        }
      }
    });
  }

  void _toggleLike(int postId) {
    int index = _bookmarkPosts.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isLiked = _bookmarkPosts[index]['is_liked'] == true;
      _bookmarkPosts[index]['is_liked'] = !isLiked;
      _bookmarkPosts[index]['likes_count'] =
          ((_bookmarkPosts[index]['likes_count'] ?? 0) as int) + (isLiked ? -1 : 1);
    });

    _channel?.sink.add(jsonEncode({
      'action': 'toggle_like',
      'user_id': myUserId,
      'post_id': postId,
    }));
  }

  void _toggleRepost(int postId) {
    int index = _bookmarkPosts.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isReposted = _bookmarkPosts[index]['is_reposted'] == true;
      _bookmarkPosts[index]['is_reposted'] = !isReposted;
      _bookmarkPosts[index]['reposts_count'] =
          ((_bookmarkPosts[index]['reposts_count'] ?? 0) as int) + (isReposted ? -1 : 1);
    });

    _channel?.sink.add(jsonEncode({
      'action': 'toggle_repost',
      'user_id': myUserId,
      'post_id': postId,
    }));
  }

  void _toggleBookmark(int postId) {
    int index = _bookmarkPosts.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    // เมื่อ un-bookmark ให้ลบออกจาก list ด้วย
    setState(() {
      _bookmarkPosts.removeAt(index);
    });

    _channel?.sink.add(jsonEncode({
      'action': 'toggle_bookmark',
      'user_id': myUserId,
      'post_id': postId,
    }));
  }

  void _navigateToProfile(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          targetUserId: post['user_id'] ?? 0,
          username: post['username'] ?? '',
          handle: post['username'] ?? '',
          following: 0,
          followers: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Bookmarks',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '@$myHandle',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: tweetyYellow,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFF100)),
            )
          : _bookmarkPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'ยังไม่มี Bookmark',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'กดไอคอน Bookmark ที่โพสต์เพื่อบันทึกไว้ที่นี่',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: Colors.white,
                  child: ListView.separated(
                    itemCount: _bookmarkPosts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final post = _bookmarkPosts[index];
                      return _buildBookmarkItem(post, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildBookmarkItem(Map<String, dynamic> post, int index) {
    final int postId = post['post_id'] ?? 0;
    final bool isLiked = post['is_liked'] == true;
    final bool isReposted = post['is_reposted'] == true;
    final int likesCount = (post['likes_count'] ?? 0) as int;
    final int repostsCount = (post['reposts_count'] ?? 0) as int;

    String formattedDate = '';
    if (post['created_at'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(post['created_at'].toString()).toLocal();
        formattedDate = DateFormat('dd MMM, HH:mm').format(parsedDate);
      } catch (_) {}
    }

    final String profileImageUrl = post['profile_image_url'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ กดรูปโปรไฟล์ → ไปหน้า ProfileScreen
          GestureDetector(
            onTap: () => _navigateToProfile(post),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อผู้ใช้ + วันที่ (กดชื่อไปโปรไฟล์ได้ด้วย)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(post),
                      child: Text(
                        post['username'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(post['content'] ?? '', style: const TextStyle(fontSize: 15)),

                // รูปภาพ (ถ้ามี)
                if (post['image_urls'] != null &&
                    (post['image_urls'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(post['image_urls'][0]),
                    ),
                  ),
                const SizedBox(height: 8),

                // ปุ่ม Interactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reply (ยังไม่มี action)
                    _buildIconButton(Icons.chat_bubble_outline, '', Colors.grey, () {}),

                    // Like
                    _buildIconButton(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      '$likesCount',
                      isLiked ? Colors.red : Colors.grey,
                      () => _toggleLike(postId),
                    ),

                    // Repost
                    _buildIconButton(
                      Icons.repeat,
                      '$repostsCount',
                      isReposted ? Colors.green : Colors.grey,
                      () => _toggleRepost(postId),
                    ),

                    // Bookmark — กด un-bookmark จะลบออกจากหน้านี้
                    _buildIconButton(
                      Icons.bookmark, // หน้านี้ค่าเริ่มต้น bookmark อยู่เสมอ
                      '',
                      Colors.blue,
                      () => _toggleBookmark(postId),
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