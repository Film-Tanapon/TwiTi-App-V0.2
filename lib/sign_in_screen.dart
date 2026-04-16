import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';

// 🟢 ตรวจสอบว่าชื่อไฟล์เหล่านี้ถูกต้องตามที่คุณตั้งไว้
import 'post_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color _tweetyYellow = const Color(0xFFFFF100);
  final Color _tweetyGreen = const Color(0xFF00FF44);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId:
        '305844664566-7392po3uu4d377lvcqao4i9jcnj7plgc.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ฟังก์ชันจำลองการ Check Auth
  Future<bool> _checkAuth(String user, String pass) async {
    await Future.delayed(const Duration(seconds: 2));
    if (user == "@admin" && pass == "1234") return true;
    return false;
  }

  Future<void> _loginUser() async {
    String userInput = _usernameController.text.trim();
    String passInput = _passwordController.text;

    if (userInput.isEmpty || passInput.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('ws://tweety-server.onrender.com/ws'),
      );

      final request = {
        "action": "login",
        "username": userInput, // ส่งค่าไปเช็คได้ทั้ง email และ username
        "password": passInput,
      };
      channel.sink.add(jsonEncode(request));

      channel.stream.listen(
        (message) async {
          final jsonResponse = jsonDecode(message);

          // เช็คว่ามี jwt ส่งมา ถือว่าล็อกอินสำเร็จ
          if (jsonResponse.containsKey('jwt') && jsonResponse['jwt'] != null) {
            await _storage.write(key: 'jwt_token', value: jsonResponse['jwt']);

            if (jsonResponse['user_id'] != null) {
              await _storage.write(
                key: 'user_id',
                value: jsonResponse['user_id'].toString(),
              );
            }
            if (jsonResponse['username'] != null) {
              await _storage.write(
                key: 'username',
                value: jsonResponse['username'].toString(),
              );
            }

            channel.sink.close();

            if (mounted) {
              setState(() => _isLoading = false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PostScreen()),
              );
            }
          } else if (jsonResponse['action'] == 'error') {
            _showError(jsonResponse['message'] ?? "Login failed");
            setState(() => _isLoading = false);
            channel.sink.close();
          } else {
            print("Received unhandled message: $jsonResponse");
          }
        },
        onError: (error) {
          _showError("Connection error.");
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      _showError("Cannot connect to server.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        final channel = WebSocketChannel.connect(
          Uri.parse('wss://tweety-server.onrender.com'),
        );

        final request = {"action": "google_login", "token": idToken};
        channel.sink.add(jsonEncode(request));

        channel.stream.listen((message) async {
          final jsonResponse = jsonDecode(message);
          if (jsonResponse['action'] == 'login_success') {
            await _storage.write(key: 'jwt_token', value: jsonResponse['jwt']);

            if (jsonResponse['user_id'] != null) {
              await _storage.write(
                key: 'user_id',
                value: jsonResponse['user_id'].toString(),
              );
            }
            if (jsonResponse['username'] != null) {
              await _storage.write(
                key: 'username',
                value: jsonResponse['username'].toString(),
              );
            }

            channel.sink.close();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PostScreen()),
              );
            }
          } else if (jsonResponse['action'] == 'error') {
            _showError("Google login failed from server");
            setState(() => _isLoading = false);
            channel.sink.close();
          }
        });
      }
    } catch (error) {
      _showError("Failed to sign in with Google");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tweetyYellow,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🟢 ตรวจสอบว่ามีไฟล์รูปนี้ใน pubspec.yaml หรือยัง
              Image.asset(
                'assets/images/twity.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 120),
              ),
              const SizedBox(height: 10),
              const Text(
                'TwiTi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(
                  Icons.g_mobiledata,
                  color: Colors.red,
                  size: 35,
                ),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "or",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'username',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 2,
                    ), // 🟢 ปรับให้ชิดขึ้นแล้ว
                    child: Text(
                      "@",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Password',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(
                      right: 15,
                    ), // 🟢 ดันปุ่มรูปตาเข้ามาแล้ว
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _loginUser, // 🟢 เรียกใช้ฟังก์ชันล็อกอินจริงตรงนี้
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tweetyGreen,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
