import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _timeoutTimer;

  final Color _tweetyYellow = const Color(0xFFFFF100);
  final Color _tweetyGreen = const Color(0xFF00FF44);

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _cleanupConnection() {
    _timeoutTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _sub = null;
    _timeoutTimer = null;
  }

  Future<void> _registerUser() async {
    setState(() => _isLoading = true);
    _cleanupConnection(); // ปิด connection เก่าถ้ามี

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://twiti-server-v0-2.onrender.com/ws'),
      );

      // Timeout 15 วินาที — เผื่อ Render.com cold start
      _timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          _cleanupConnection();
          setState(() => _isLoading = false);
          _showError("Connection timed out. Please try again.");
        }
      });

      final request = {
        "action": "email_register",
        "email": _emailController.text.trim(),
        "username": _nameController.text.trim(),
        "password": _passwordController.text,
      };

      _channel!.sink.add(jsonEncode(request));

      _sub = _channel!.stream.listen((message) {
        final jsonResponse = jsonDecode(message);

        if (jsonResponse['action'] == 'register_success') {
          _cleanupConnection();
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSuccess("Registration Successful!");
          Navigator.pop(context);
        } else if (jsonResponse['action'] == 'error') {
          _cleanupConnection();
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showError(jsonResponse['message'] ?? "Registration failed");
        }
        // action อื่นๆ (new_post ฯลฯ) ข้ามไป ไม่ทำอะไร
      }, onError: (error) {
        _cleanupConnection();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError("Connection error. Please try again.");
      }, onDone: () {
        // Server ปิด connection โดยไม่ตอบ
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          _showError("Server disconnected. Please try again.");
        }
      });
    } catch (e) {
      _cleanupConnection();
      setState(() => _isLoading = false);
      _showError("Connection failed. Please check your internet.");
    }
  }

  @override
  void dispose() {
    _cleanupConnection();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tweetyYellow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 🟢 นำ PageView ออก และใช้ SingleChildScrollView แทน
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Image.asset('assets/images/twity.png', height: 80),
              const Text('TwiTi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Create your account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              _buildTextField(_nameController, 'Name', false),
              const SizedBox(height: 15),
              _buildTextField(_emailController, 'Email', false),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, 'Password', true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, 'Confirm Password', true),
              const SizedBox(height: 30),
              _isLoading 
                ? const CircularProgressIndicator()
                : _buildRegisterButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: () {
        String pass = _passwordController.text;
        String confirmPass = _confirmPasswordController.text;

        if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
          _showError("Please enter your name and email");
        } else if (pass.isEmpty || confirmPass.isEmpty) {
          _showError("Please enter your password");
        } else if (pass.length < 6) {
          _showError("Password must be at least 6 characters");
        } else if (pass != confirmPass) {
          _showError("Passwords do not match");
        } else {
          // 🟢 ข้อมูลครบถ้วน เรียกฟังก์ชันสมัครสมาชิกเลย
          _registerUser();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _tweetyGreen,
        minimumSize: const Size(140, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}