import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {

    final user = FirebaseAuth.instance.currentUser;

    // 👇 thoda smooth UX ke liye small delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0F2A),
              Color(0xFF12163A),
              Color(0xFF1A1F4F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [

            /// LOGO
            _Logo(),

            SizedBox(height: 25),

            Text(
              "CodeCollab",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Code together. Build together.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 50),

            CircularProgressIndicator(
              color: Color(0xFF7B6CFF),
            ),

            SizedBox(height: 10),

            Text(
              "Loading...",
              style: TextStyle(color: Colors.white54),
            )
          ],
        ),
      ),
    );
  }
}

/// 🔥 Separate widget (clean code)
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4BFF),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple,
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: const Text(
        "</>",
        style: TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}