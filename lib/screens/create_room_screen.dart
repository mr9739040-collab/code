import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'editor_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  bool isPrivate = true;
  bool allowInvite = true;

  String selectedLanguage = "Dart";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔥 FINAL CREATE ROOM FUNCTION
  Future<void> createRoom(BuildContext context) async {
    String name = nameController.text.trim();
    String desc = descController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room name and password required")),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid == null) return;

      /// ✅ FIRESTORE SAVE (FINAL STRUCTURE)
      DocumentReference docRef =
      await FirebaseFirestore.instance.collection('rooms').add({
        'name': name,
        'description': desc,
        'isPrivate': isPrivate,
        'password': password,
        'language': selectedLanguage,
        'allowInvite': allowInvite,

        /// 🔥 IMPORTANT (TUMHARA SNIPPET YAHI USE HUA HAI)
        'createdAt': FieldValue.serverTimestamp(), // ✅ timestamp
        'creator': uid, // ✅ UID store
        'members': [uid], // ✅ creator auto add

        /// 🔥 REAL-TIME FEATURES
        'typingUsers': [],
        'code': "// Start coding in $name...",
      });

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(roomId: docRef.id),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF050A1A),
              Color(0xFF0B1230),
              Color(0xFF141B3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create Room 🚀",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildInput(
                        controller: nameController,
                        hint: "Room Name",
                        icon: Icons.meeting_room,
                      ),

                      const SizedBox(height: 15),

                      _buildInput(
                        controller: descController,
                        hint: "Description",
                        icon: Icons.description,
                      ),

                      const SizedBox(height: 15),

                      _buildInput(
                        controller: passwordController,
                        hint: "Set Room Password",
                        icon: Icons.lock,
                        obscure: true,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Choose Language",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          dropdownColor: const Color(0xFF11162E),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: ["Dart", "Java", "Python", "C++", "JS"]
                              .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedLanguage = val!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Room Type",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _typeCard(
                              title: "Public",
                              desc: "Anyone can join",
                              icon: Icons.public,
                              selected: !isPrivate,
                              onTap: () =>
                                  setState(() => isPrivate = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _typeCard(
                              title: "Private",
                              desc: "Password protected",
                              icon: Icons.lock,
                              selected: isPrivate,
                              onTap: () =>
                                  setState(() => isPrivate = true),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Allow members to invite others",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Switch(
                              value: allowInvite,
                              activeColor: Colors.purpleAccent,
                              onChanged: (val) {
                                setState(() {
                                  allowInvite = val;
                                });
                              },
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => createRoom(context),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B6CFF), Color(0xFF00E5FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Create Room",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// INPUT
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  /// TYPE CARD
  Widget _typeCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.purple.withOpacity(0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}