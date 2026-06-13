import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadsScreen extends StatefulWidget {
  final String roomId;

  const ThreadsScreen({super.key, required this.roomId});

  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  final TextEditingController titleController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  /// ================= CREATE THREAD =================
  Future<void> createThread() async {
    final title = titleController.text.trim();

    if (title.isEmpty || user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("rooms")
          .doc(widget.roomId)
          .collection("threads")
          .add({
        "title": title,
        "createdBy": user!.displayName ??
            user!.email?.split("@")[0] ??
            "User",
        "createdAt": FieldValue.serverTimestamp(),
        "createdById": user!.uid,
      });

      titleController.clear();
      Navigator.pop(context);

      _showSnack("Thread Created 🚀");
    } catch (e) {
      _showSnack("Error creating thread");
    }
  }

  /// ================= SNACK =================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepPurple,
        content: Text(msg),
      ),
    );
  }

  /// ================= CREATE DIALOG =================
  void showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Create Thread",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter thread topic...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: createThread,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1F),

      /// 🔥 MODERN APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Threads",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E1B4B),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: showCreateDialog,
            icon: const Icon(Icons.add_circle, size: 28),
          )
        ],
      ),

      /// ================= BODY =================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.roomId)
            .collection("threads")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          /// 🔄 LOADING FIX
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          /// ❌ ERROR FIX
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong ❌",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final threads = snapshot.data?.docs ?? [];

          /// 📭 EMPTY STATE
          if (threads.isEmpty) {
            return const Center(
              child: Text(
                "No Threads Yet 🚀",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final data =
              threads[index].data() as Map<String, dynamic>;

              return _threadCard(data, threads[index].id);
            },
          );
        },
      ),

      /// 🔥 GLOW FAB
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.6),
              blurRadius: 12,
            )
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: showCreateDialog,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  /// ================= THREAD CARD =================
  Widget _threadCard(Map<String, dynamic> data, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A223B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.forum, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["title"] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "By ${data["createdBy"] ?? "User"}",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton(
            color: const Color(0xFF1B2140),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == "delete") {
                await FirebaseFirestore.instance
                    .collection("rooms")
                    .doc(widget.roomId)
                    .collection("threads")
                    .doc(id)
                    .delete();

                _showSnack("Deleted");
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "delete",
                child: Text("Delete"),
              ),
            ],
          )
        ],
      ),
    );
  }
}