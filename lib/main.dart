import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'package:flutter/services.dart';
import 'routes/app_routes.dart';

void main() {
  // 1. ตั้งค่าระบบก่อน
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 2. เรียก runApp แค่ครั้งเดียว โดยมี Provider หุ้ม MyApp ไว้
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'Tweety App',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.introScreen, 
      routes: AppRoutes.routes,            
    );
  }
}