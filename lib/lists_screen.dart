import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class ListsScreen extends StatefulWidget {
  final int myUserId; // 🔴 ต้องรับค่า User ID เพื่อเอาไปบอก Backend ว่าใครสร้าง List
  final WebSocketChannel? channel; // 🔴 รับท่อส่งข้อมูลมาด้วย
  final Stream? broadcastStream;

  const ListsScreen({
    super.key,
    required this.myUserId,
    this.channel,
    this.broadcastStream,
  });

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final Color tweetyYellow = const Color(0xFFFFF100);
  
  // ตัวแปรสำหรับรับค่าตอนสร้าง List
  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _listDescController = TextEditingController();
  
  List<Map<String, dynamic>> _myLists = []; // เก็บข้อมูล List ที่ดึงมาจาก Backend
  bool _isLoading = true;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _requestLists();

    // ดักฟังข้อมูลจาก Backend
    if (widget.broadcastStream != null) {
      _streamSubscription = widget.broadcastStream!.listen((message) {
        _handleIncomingData(message.toString());
      });
    } else {
      _isLoading = false;
    }
  }

  // 1. ฟังก์ชันขอข้อมูล List เก่าที่มีอยู่แล้ว
  void _requestLists() {
    final msg = {
      'action': 'get_lists', // ⚠️ ชื่อ Action ตามที่ Backend กำหนด
      'user_id': widget.myUserId,
    };
    widget.channel?.sink.add(jsonEncode(msg));
  }

  // 2. ฟังก์ชันจัดการข้อมูลที่ Backend ส่งกลับมา
  void _handleIncomingData(String jsonStr) {
    if (!mounted) return;
    try {
      final decoded = jsonDecode(jsonStr);

      if (decoded['action'] == 'load_lists') {
        setState(() {
          _myLists = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _isLoading = false;
        });
      } 
      else if (decoded['action'] == 'new_list_created') {
        // ถ้าระบบบอกว่าสร้างสำเร็จ ให้เอามาโชว์หน้าแอปเลย
        setState(() {
          _myLists.insert(0, decoded['data']);
        });
      }
    } catch (e) {
      debugPrint('JSON Parse Error in Lists: $e');
    }
  }

  // 3. ฟังก์ชันส่งคำสั่งสร้าง List ใหม่ไปให้ Backend
void _createNewList() {
    final name = _listNameController.text.trim();
    final desc = _listDescController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name cannot be empty!')),
      );
      return;
    }

    final msg = {
      'action': 'create_list', // ⚠️ ชื่อ Action สำหรับสร้าง List
      'user_id': widget.myUserId,
      'list_name': name,
      'description': desc,
    };

    // ส่งข้อมูลไปให้ Backend เซฟ
    widget.channel?.sink.add(jsonEncode(msg));

    // 🔴 [ส่วนที่เพิ่มเข้ามา] อัปเดตหน้าจอทันที (Optimistic UI) โดยไม่ต้องรอ Backend ตอบกลับ
    setState(() {
      _myLists.insert(0, {
        'list_name': name,
        'description': desc,
      });
    });

    // เคลียร์ช่องพิมพ์และปิด Popup
    _listNameController.clear();
    _listDescController.clear();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List created successfully!')),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _listNameController.dispose();
    _listDescController.dispose();
    super.dispose();
  }

  // --- Popup สำหรับสร้าง List ใหม่ ---
  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Create a new List', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _listNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter list name',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _listDescController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this list about?',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _createNewList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tweetyYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lists',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      
      // 4. แสดงผล: ถ้ารอกำลังโหลด -> โชว์วงกลม, ถ้าว่าง -> โชว์คำแนะนำ, ถ้ามีข้อมูล -> โชว์ ListView
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : _myLists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "You haven't created or followed\nany lists yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "When you do, they'll show up here.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _myLists.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final listData = _myLists[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.list, color: Colors.black),
                  ),
                  title: Text(listData['list_name'] ?? 'Untitled List', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(listData['description'] ?? 'No description', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: กดเข้าไปดูโพสต์ใน List นี้
                  },
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: tweetyYellow,
        elevation: 2,
        onPressed: _showCreateListDialog, // 🔴 เปลี่ยนจากโชว์ SnackBar เป็นโชว์ Popup แทน
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}