import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes/app_routes.dart'; // <--- เพิ่มบรรทัดนี้

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // เอา Sizer ออกก่อนก็ได้ครับถ้ายังไม่ได้ลง Library Sizer
      title: 'Tweety App',
      debugShowCheckedModeBanner: false,
      
      // --- ส่วนสำคัญที่ต้องแก้ ---
      initialRoute: AppRoutes.introScreen, // เริ่มต้นที่หน้า Intro
      routes: AppRoutes.routes,            // แผนที่การเดินทาง
      // -----------------------
      
    );
  }
}