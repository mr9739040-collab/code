import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {

  /// 🔥 AUTO USER CREATE FUNCTION
  Future<void> createUserIfNotExists(User user) async {
    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'name': user.displayName ??
            user.email?.split('@')[0] ??
            "User",
        'email': user.email,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      /// 🔥 update online status
      await userRef.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),

      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          /// 🔄 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// ❌ NOT LOGGED IN
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          /// ✅ LOGGED IN
          final user = snapshot.data!;

          /// 🔥 CALL AUTO USER CREATE
          createUserIfNotExists(user);

          /// 👉 GO TO HOME
          return const HomeScreen();
        },
      ),
    );
  }
}