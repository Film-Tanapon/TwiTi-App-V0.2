import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';

import 'edit_profile_screen.dart';
// 1. อย่าลืม import ไฟล์หน้าแชทของคุณที่นี่
import 'chat_room_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  final int targetUserId;
  final String username;
  final String handle;
  final int following;
  final int followers;

  const ProfileScreen({
    super.key,
    required this.targetUserId,
    required this.username,
    required this.handle,
    required this.following,
    required this.followers,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _ownPosts = [];
  List<Map<String, dynamic>> _reposts = [];
  List<Map<String, dynamic>> _favorites = [];
  int myUserId = 0;
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    const storage = FlutterSecureStorage();
    String? idStr = await storage.read(key: 'user_id');
    myUserId = int.tryParse(idStr ?? '0') ?? 0;

    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000/ws'));

    _channel?.sink.add(
      jsonEncode({
        "action": "fetch_profile_data",
        "user_id": myUserId,
        "target_user_id": widget.targetUserId,
      }),
    );

    _channel?.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['action'] == 'profile_data_response') {
        if (mounted) {
          setState(() {
            _ownPosts = List<Map<String, dynamic>>.from(
              (data['posts'] ?? []).map((e) => Map<String, dynamic>.from(e)),
            );
            _reposts = List<Map<String, dynamic>>.from(
              (data['reposts'] ?? []).map((e) => Map<String, dynamic>.from(e)),
            );
            _favorites = List<Map<String, dynamic>>.from(
              (data['favorites'] ?? []).map((e) => Map<String, dynamic>.from(e)),
            );
            _isLoading = false;
          });
        }
      }

      if (data['action'] == 'update_post_stats') {
        final updatedData = data['data'];
        if (updatedData == null) return;
        if (mounted) {
          setState(() {
            _updatePostStats(_ownPosts, updatedData);
            _updatePostStats(_reposts, updatedData);
            _updatePostStats(_favorites, updatedData);
          });
        }
      }
    });
  }

  void _updatePostStats(List<Map<String, dynamic>> list, dynamic updatedData) {
    int index = list.indexWhere((m) => m['post_id'] == updatedData['post_id']);
    if (index != -1) {
      list[index]['likes_count'] = updatedData['likes_count'];
      list[index]['reposts_count'] = updatedData['reposts_count'];
    }
  }

  // --- Actions ---

  // 🟢 แก้ไขฟังก์ชันนี้เพื่อ Navigate ไปหน้าแชท
  void _startChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(userName: widget.username),
      ),
    );
  }

  void _toggleLike(List<Map<String, dynamic>> list, int postId) {
    int index = list.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isLiked = list[index]['is_liked'] == true;
      list[index]['is_liked'] = !isLiked;
      list[index]['likes_count'] =
          ((list[index]['likes_count'] ?? 0) as int) + (isLiked ? -1 : 1);
    });

    _channel?.sink.add(
      jsonEncode({
        'action': 'toggle_like',
        'user_id': myUserId,
        'post_id': postId,
      }),
    );
  }

  void _toggleRepost(List<Map<String, dynamic>> list, int postId) {
    int index = list.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      bool isReposted = list[index]['is_reposted'] == true;
      list[index]['is_reposted'] = !isReposted;
      list[index]['reposts_count'] =
          ((list[index]['reposts_count'] ?? 0) as int) + (isReposted ? -1 : 1);
    });

    _channel?.sink.add(
      jsonEncode({
        'action': 'toggle_repost',
        'user_id': myUserId,
        'post_id': postId,
      }),
    );
  }

  void _toggleBookmark(List<Map<String, dynamic>> list, int postId) {
    int index = list.indexWhere((m) => m['post_id'] == postId);
    if (index == -1) return;

    setState(() {
      list[index]['is_bookmarked'] = !(list[index]['is_bookmarked'] == true);
    });

    _channel?.sink.add(
      jsonEncode({
        'action': 'toggle_bookmark',
        'user_id': myUserId,
        'post_id': postId,
      }),
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                backgroundColor: tweetyYellow,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(height: 120, color: tweetyYellow),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 45),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.username,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '@${widget.handle}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  myUserId == widget.targetUserId
                                      ? OutlinedButton(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProfileScreen(
                                                  myUserId: myUserId,
                                                  currentUsername: widget.username,
                                                  currentHandle: widget.handle,
                                                  channel: _channel,
                                                ),
                                              ),
                                            );
                                            if (result != null && result['newName'] != null) {
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              _channel?.sink.add(
                                                jsonEncode({
                                                  "action": "fetch_profile_data",
                                                  "user_id": myUserId,
                                                  "target_user_id": widget.targetUserId,
                                                }),
                                              );
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            shape: const StadiumBorder(),
                                            side: const BorderSide(color: Colors.grey),
                                          ),
                                          child: const Text(
                                            'Edit profile',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: _startChat,
                                              style: OutlinedButton.styleFrom(
                                                shape: const CircleBorder(),
                                                side: const BorderSide(color: Colors.grey),
                                                padding: const EdgeInsets.all(8),
                                                minimumSize: const Size(40, 40),
                                              ),
                                              child: const Icon(
                                                Icons.mail_outline, 
                                                color: Colors.black, 
                                                size: 20
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isFollowing = !_isFollowing;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _isFollowing
                                                    ? Colors.white
                                                    : Colors.black,
                                                foregroundColor: _isFollowing
                                                    ? Colors.black
                                                    : Colors.white,
                                                shape: const StadiumBorder(),
                                                side: _isFollowing
                                                    ? const BorderSide(color: Colors.grey)
                                                    : null,
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                _isFollowing ? 'Following' : 'Follow',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  _buildStatText(
                                    widget.following.toString(),
                                    'Following',
                                  ),
                                  const SizedBox(width: 20),
                                  _buildStatText(
                                    widget.followers.toString(),
                                    'Followers',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        color: Colors.white,
                        child: const TabBar(
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: tweetyYellow,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(text: 'Posts'),
                            Tab(text: 'Reposts'),
                            Tab(text: 'Favorites'),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -240,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFF100)),
                )
              : TabBarView(
                  children: [
                    _buildPostList(_ownPosts),
                    _buildPostList(_reposts),
                    _buildPostList(_favorites),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatText(String count, String label) {
    return Row(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text("No posts found", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final int postId = post['post_id'] ?? 0;
        final bool isLiked = post['is_liked'] == true;
        final bool isReposted = post['is_reposted'] == true;
        final bool isBookmarked = post['is_bookmarked'] == true;
        final int likesCount = (post['likes_count'] ?? 0) as int;
        final int repostsCount = (post['reposts_count'] ?? 0) as int;

        String formattedDate = '';
        if (post['created_at'] != null) {
          try {
            DateTime parsedDate = DateTime.parse(
              post['created_at'].toString(),
            ).toLocal();
            formattedDate = DateFormat('dd MMM, HH:mm').format(parsedDate);
          } catch (_) {}
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    backgroundImage: (post['profile_image_url'] ?? '').isNotEmpty
                        ? NetworkImage(post['profile_image_url'])
                        : null,
                    child: (post['profile_image_url'] ?? '').isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 25)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post['username'] ?? widget.username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post['content'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        if (post['image_urls'] != null && (post['image_urls'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(post['image_urls'][0]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleLike(posts, postId),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 20,
                                    color: isLiked ? Colors.red : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('$likesCount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleRepost(posts, postId),
                                  child: Icon(
                                    Icons.repeat,
                                    size: 20,
                                    color: isReposted ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('$repostsCount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _toggleBookmark(posts, postId),
                              child: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 20,
                                color: isBookmarked ? Colors.blue : Colors.grey,
                              ),
                            ),
                            const Icon(Icons.ios_share, size: 20, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}