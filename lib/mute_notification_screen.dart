import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MuteNotificationScreen extends StatefulWidget {
  const MuteNotificationScreen({super.key});

  @override
  State<MuteNotificationScreen> createState() => _MuteNotificationScreenState();
}

class _MuteNotificationScreenState extends State<MuteNotificationScreen> {
  bool _dontFollow = false;
  bool _notFollowingYou = false;

  static const Color tweetyYellow = Color(0xFFFFF100);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadMuteSettings(); // โหลดการตั้งค่าตอนเปิดหน้าจอ
  }

  // ฟังก์ชันโหลดค่าที่เคยบันทึกไว้
  Future<void> _loadMuteSettings() async {
    String? dontFollowStr = await _storage.read(key: 'mute_dont_follow');
    String? notFollowingYouStr = await _storage.read(key: 'mute_not_following_you');

    if (mounted) {
      setState(() {
        _dontFollow = dontFollowStr == 'true';
        _notFollowingYou = notFollowingYouStr == 'true';
      });
    }
  }

  // ฟังก์ชันบันทึกค่าเมื่อกดเปิด/ปิดสวิตช์
  Future<void> _saveSetting(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Muted notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: tweetyYellow,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          _buildHeader("Mute notifications from people:"),
          
          _buildSwitchTile(
            title: "You don't follow",
            value: _dontFollow,
            onChanged: (val) {
              setState(() => _dontFollow = val);
              _saveSetting('mute_dont_follow', val); // บันทึกค่า
            },
          ),
          
          _buildSwitchTile(
            title: "Who don't follow you",
            value: _notFollowingYou,
            onChanged: (val) {
              setState(() => _notFollowingYou = val);
              _saveSetting('mute_not_following_you', val); // บันทึกค่า
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
      activeTrackColor: const Color(0xFFFFF100),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}