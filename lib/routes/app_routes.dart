import 'package:flutter/material.dart';
// Import ไฟล์หน้าจอจาก lib โดยตรง (เพราะไฟล์คุณวางไว้ที่ lib ไม่ได้ซ้อนโฟลเดอร์)
import '../intro_screen.dart';
import '../sign_in_screen.dart'; //add
import '../post_screen.dart';

class AppRoutes {
  static const String introScreen = '/intro_screen';
  static const String signInScreen = '/sign_in_screen'; //add
  static const String postScreen = '/post_screen';

  static Map<String, WidgetBuilder> routes = {
    introScreen: (context) => const IntroScreen(),
    signInScreen: (context) => const SignInScreen(), //add
    postScreen: (context) => const PostScreen(),
  };
}