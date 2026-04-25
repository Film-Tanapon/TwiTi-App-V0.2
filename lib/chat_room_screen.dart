import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  final int myUserId;
  final int receiverId;

  // รับ channel สำหรับ sink (ส่งข้อความ) และ broadcastStream สำหรับรับข้อความ
  final WebSocketChannel? channel;
  final Stream? broadcastStream;

  const ChatRoomScreen({
    super.key,
    required this.userName,
    required this.myUserId,
    required this.receiverId,
    this.channel,
    this.broadcastStream,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _sub;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    // ขอประวัติแชทผ่าน channel.sink (ส่งออก)
    widget.channel?.sink.add(jsonEncode({
      'action': 'get_chat_history',
      'user_id': widget.myUserId,
      'receiver_id': widget.receiverId,
    }));

    // ดักฟังจาก broadcastStream (รับเข้า) — ไม่ listen channel.stream ตรงๆ
    if (widget.broadcastStream != null) {
      _sub = widget.broadcastStream!.listen((raw) {
        _handleMessage(raw.toString());
      });
    }

    // timeout: ถ้า backend ไม่ตอบใน 5 วินาที ให้หยุด loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _handleMessage(String raw) {
    if (!mounted) return;
    try {
      final data = jsonDecode(raw);

      // 🟢 กรณีโหลดประวัติแชทสำเร็จ
      if (data['action'] == 'load_chat_history') {
        final List history = data['data'] ?? [];
        setState(() {
          _messages.clear();
          for (final msg in history) {
            _messages.add({
              'id': msg['id'],
              'sender': msg['sender_id'] == widget.myUserId ? 'me' : 'other',
              'text': msg['content'] ?? '',
              'image_url': msg['image_url'],
              'time': _formatTime(msg['created_at']),
            });
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // 🟢 กรณีมีข้อความใหม่เข้ามา real-time
      else if (data['action'] == 'new_message') {
        final msg = data['data'];
        // กรองเฉพาะ message ของห้องนี้
        final int senderId = msg['sender_id'] ?? 0;
        final int receiverId = msg['receiver_id'] ?? 0;
        final bool isThisRoom =
            (senderId == widget.myUserId && receiverId == widget.receiverId) ||
            (senderId == widget.receiverId && receiverId == widget.myUserId);

        if (isThisRoom) {
          setState(() {
            _messages.add({
              'id': msg['id'],
              'sender': senderId == widget.myUserId ? 'me' : 'other',
              'text': msg['content'] ?? '',
              'image_url': msg['image_url'],
              'time': _formatTime(msg['created_at']),
            });
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('ChatRoom parse error: $e');
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🟢 ส่งข้อความผ่าน WebSocket → บันทึกลง DB ที่ Backend
  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    widget.channel?.sink.add(jsonEncode({
      'action': 'send_message',
      'user_id': widget.myUserId,
      'receiver_id': widget.receiverId,
      'content': text,
      'image_url': '',
    }));

    _msgController.clear();
  }

  // 🟢 เลือกรูปจาก Gallery แล้วส่งผ่าน WebSocket
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // TODO: อัปโหลดรูปขึ้น Storage แล้วได้ URL มา
    // ตัวอย่างนี้ยังใช้ local bytes แสดงใน UI ก่อน แล้วค่อยส่ง URL จริง
    final Uint8List imageBytes = await image.readAsBytes();
    setState(() {
      _messages.add({
        'sender': 'me',
        'text': '',
        'imageBytes': imageBytes,
        'time': _formatTime(DateTime.now().toIso8601String()),
      });
    });
    _scrollToBottom();

    // เมื่อได้ URL จริงจาก Storage ให้ส่งแบบนี้:
    // _channel?.sink.add(jsonEncode({
    //   'action': 'send_message',
    //   'user_id': widget.myUserId,
    //   'receiver_id': widget.receiverId,
    //   'content': '',
    //   'image_url': uploadedUrl,
    // }));
  }

  @override
  void dispose() {
    _sub?.cancel(); // cancel subscription เท่านั้น ไม่ปิด channel (เป็นของ parent)
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          // 🟢 ส่วนแสดงรายการข้อความ (ดึงจาก DB จริง)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          "Start a conversation with ${widget.userName}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(15),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isMe = msg['sender'] == 'me';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.72,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFFFF100)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 0),
                                      bottomRight:
                                          Radius.circular(isMe ? 0 : 16),
                                    ),
                                  ),
                                  child: msg['imageBytes'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(
                                            msg['imageBytes'],
                                            width: 200,
                                          ),
                                        )
                                      : msg['image_url'] != null &&
                                              (msg['image_url'] as String)
                                                  .isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                msg['image_url'],
                                                width: 200,
                                              ),
                                            )
                                          : Text(
                                              msg['text'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                ),
                                // แสดงเวลา
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, right: 4),
                                  child: Text(
                                    msg['time'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // แถบพิมพ์ข้อความด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined,
                      color: Color(0xFFFFF100)),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Start a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                    ),
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