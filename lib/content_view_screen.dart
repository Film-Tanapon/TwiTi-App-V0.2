import 'package:flutter/material.dart';

class ContentViewScreen extends StatefulWidget {
  const ContentViewScreen({super.key});

  @override
  State<ContentViewScreen> createState() => _ContentViewScreenState();
}

class _ContentViewScreenState extends State<ContentViewScreen> {
  final Map<String, bool> _interests = {
    'Technology': false,
    'Music': false,
    'Gaming': false,
    'Food': false,
    'Travel': false,
    'Sports': false,
  };

  // --- 2. ข้อมูลสำหรับ Muted Words ---
  final List<String> _mutedWords = [];
  final TextEditingController _mutedController = TextEditingController();

  // ส่งรายการความสนใจที่ติ๊กถูกไป Backend
  void _syncInterestsToBackend() {
    List<String> selected = _interests.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    print("ส่งข้อมูลความสนใจไป Backend: $selected");
    // TODO: http.post('/api/interests', body: selected)
  }

  // ส่งคำที่ต้องการบล็อกไป Backend
  void _addMutedWordToBackend(String word) {
    if (word.isNotEmpty) {
      setState(() {
        _mutedWords.add(word);
        _mutedController.clear();
      });
      print("บันทึกคำที่บล็อก: $word");
      // TODO: http.post('/api/muted-words', body: {'word': word})
    }
  }

  void _removeMutedWord(int index) {
    setState(() {
      print("ลบคำที่บล็อก: ${_mutedWords[index]}");
      _mutedWords.removeAt(index);
    });
    // TODO: http.delete('/api/muted-words/$index')
  }

  @override
  Widget build(BuildContext context) {
    const Color tweetyYellow = Color(0xFFFFF100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Content you see',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tweetyYellow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        // ป้องกันหน้าจอล้น
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนที่ 1: Interests (รายการความสนใจ) ---
            _buildSectionHeader(
              'Interests',
              'Select topics you\'re interested in.',
            ),
            Column(
              children: _interests.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: _interests[key],
                  activeColor: Colors.black,
                  onChanged: (bool? value) {
                    setState(() {
                      _interests[key] = value ?? false;
                    });
                    _syncInterestsToBackend(); // ส่งค่าไป Backend ทันทีที่ติ๊ก
                  },
                );
              }).toList(),
            ),

            const Divider(height: 40),

            // --- ส่วนที่ 2: Muted Words (คำที่ไม่อยากเห็น) ---
            _buildSectionHeader(
              'Muted Words',
              'Hide posts that contain these words from your timeline.',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mutedController,
                      decoration: const InputDecoration(
                        hintText: 'Enter word to mute...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () =>
                        _addMutedWordToBackend(_mutedController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tweetyYellow,
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // รายการคำที่ถูก Muted
            ListView.builder(
              shrinkWrap:
                  true, // สำคัญ: เพื่อให้ซ้อนใน SingleChildScrollView ได้
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mutedWords.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.block, color: Colors.red, size: 20),
                  title: Text(_mutedWords[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeMutedWord(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
