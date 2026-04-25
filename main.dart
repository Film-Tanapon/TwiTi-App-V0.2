import 'package:flutter/material.dart';
import 'package:tweety/routes/app_routes.dart'; // 1. ต้อง Import ไฟล์รูท

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwiTi',
      debugShowCheckedModeBanner: false,
      
      // 2. กำหนดหน้าแรกสุดของแอป (เลือกชื่อจากใน AppRoutes)
      initialRoute: AppRoutes.introScreen, 
      
      // 3. ✅ สำคัญที่สุด: ต้องมีบรรทัดนี้แอปถึงจะรู้จัก "แผนที่" ทั้งหมด
      routes: AppRoutes.routes, 
    );
  }
}