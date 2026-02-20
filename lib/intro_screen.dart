import 'dart:async';
import 'package:flutter/material.dart';
import 'routes/app_routes.dart'; // ตรวจสอบ path ให้ตรงกับไฟล์ routes ของคุณ

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    // นับเวลา 3 วินาที (5 วินาทีอาจจะนานไปสำหรับ User สมัยนี้ แต่แก้เลขได้ครับ)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signInScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // สีเหลือง Tweety (ตามรูปตัวอย่าง)
      backgroundColor: const Color(0xFFFFF100), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // แสดงรูปภาพจาก Assets
            Image.asset(
              'assets/images/twity.png',
              width: 200, // ปรับขนาดรูปตามต้องการ
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}