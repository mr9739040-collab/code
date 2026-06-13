import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'editor_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController roomIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  String searchText = "";

  /// 🔥 JOIN ROOM (FIXED)
  Future<void> joinRoom() async {
    final roomId = roomIdController.text.trim();
    final pass = passwordController.text.trim();

    if (roomId.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Room ID & Password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final docRef =
      FirebaseFirestore.instance.collection('rooms').doc(roomId);

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room not found ❌")),
        );
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      /// 🔐 PASSWORD CHECK
      if (data['password'] != pass) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong Password ❌")),
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;

      /// 🔥 ✅ UPDATE MEMBERS + LAST ACTIVITY
      await docRef.update({
        'members': FieldValue.arrayUnion([uid]),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);

      /// 🔥 NAVIGATE
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    roomIdController.dispose();
    passwordController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Join Room",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _input(
                controller: roomIdController,
                hint: "Enter Room ID",
                icon: Icons.tag,
              ),

              const SizedBox(height: 15),

              _input(
                controller: passwordController,
                hint: "Enter Password",
                icon: Icons.lock,
                obscure: !showPassword,
                suffix: IconButton(
                  icon: Icon(
                    showPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: isLoading ? null : joinRoom,
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7B6CFF),
                        Color(0xFF00E5FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Join Room",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 ROOM LIST (FIXED ID)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final rooms = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final data =
                        room.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(
                            data['name'] ?? "",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "ID: ${room.id}", // ✅ FIXED
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () {
                            roomIdController.text = room.id; // ✅ FIXED
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E234A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}