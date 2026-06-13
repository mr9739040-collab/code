import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'room_info_screen.dart';
import 'threads_screen.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String roomName = "Chat Room";
  bool pageLoading = true;

  @override
  void initState() {
    super.initState();
    loadRoomData();
    updatePresence(true);
  }

  @override
  void dispose() {
    updatePresence(false);
    controller.dispose();
    super.dispose();
  }

  Future<void> loadRoomData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("rooms")
          .doc(widget.roomId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        roomName = data["name"] ?? "Chat Room";
      }
    } catch (e) {}

    if (mounted) {
      setState(() {
        pageLoading = false;
      });
    }
  }

  Future<void> updatePresence(bool online) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .collection("members")
        .doc(user!.uid)
        .set({
      "name": user!.displayName ??
          user!.email?.split("@")[0] ??
          "User",
      "online": online,
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || user == null) return;

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .collection("messages")
        .add({
      "text": text,
      "senderId": user!.uid,
      "senderName": user!.displayName ??
          user!.email?.split("@")[0] ??
          "User",
      "timestamp": FieldValue.serverTimestamp(),
    });

    controller.clear();
  }

  void attachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11162E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text("Send Attachment",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 20),
              _attachItem(Icons.image, "Image"),
              _attachItem(Icons.insert_drive_file, "Document"),
              _attachItem(Icons.code, "Code File"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _attachItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurpleAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title Coming Soon")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pageLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050B1F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050B1F),

      /// 🔥🔥🔥 UPDATED APP BAR 🔥🔥🔥
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [

                  /// 🔙 BACK BUTTON (GLOW)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 🏷 ROOM NAME
                  Expanded(
                    child: Text(
                      roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  /// 🔥 INFO BUTTON
                  _topIcon(
                    icon: Icons.info_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RoomInfoScreen(roomId: widget.roomId),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  /// 🔥 THREAD BUTTON
                  _topIcon(
                    icon: Icons.forum,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ThreadsScreen(roomId: widget.roomId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [

          /// MESSAGES (same)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("rooms")
                  .doc(widget.roomId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString(),
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Start Conversation 🚀",
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                    messages[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == user?.uid;

                    return _bubble(
                      text: data["text"] ?? "",
                      sender: data["senderName"] ?? "",
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT SAME
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF0B122B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white70, size: 28),
                  onPressed: attachMenu,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type message...",
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.6),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 TOP ICON DESIGN
  Widget _topIcon({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _bubble({
    required String text,
    required String sender,
    required bool isMe,
  }) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent])
              : const LinearGradient(
              colors: [Color(0xFF1A223B), Color(0xFF2A3355)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                sender,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}