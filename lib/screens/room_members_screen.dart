import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class RoomMembersScreen extends StatelessWidget {
  final String roomId;

  const RoomMembersScreen({super.key, required this.roomId});

  /// ✅ USER NAME FETCH FUNCTION
  Future<String> _getUserName(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) return uid;

      final userData = userDoc.data() as Map<String, dynamic>;

      return userData["name"] ??
          userData["displayName"] ??
          userData["email"] ??
          uid;
    } catch (e) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("CodeCollab"),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.chat),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(roomId: roomId),
            ),
          );
        },
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Room not found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text(
                "No room data",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final members = List<String>.from(data["members"] ?? []);
          final roomName = data["name"] ?? "Room";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ROOM HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C4DFF),
                        Color(0xFF3F2B96),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.code,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 10),

                      Text(
                        roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Room ID: $roomId",
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                /// MEMBERS
                _sectionTitle("Members (${members.length})"),
                const SizedBox(height: 10),

                ...members.map((uid) {
                  return FutureBuilder<String>(
                    future: _getUserName(uid),
                    builder: (context, userSnap) {
                      final userName = userSnap.data ?? uid;
                      return _memberTile(userName);
                    },
                  );
                }).toList(),

                const SizedBox(height: 22),

                /// ACTIVITY
                _sectionTitle("Activity"),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("rooms")
                      .doc(roomId)
                      .collection("activity")
                      .orderBy("time", descending: true)
                      .snapshots(),
                  builder: (context, snap) {

                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snap.hasError) {
                      return Text(
                        "Error: ${snap.error}",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      );
                    }

                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Text(
                        "No activity yet 🚀",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      );
                    }

                    return Column(
                      children: snap.data!.docs.map((doc) {
                        final d =
                        doc.data() as Map<String, dynamic>;

                        return _activityTile(
                          title: d["title"] ?? "Activity",
                          subtitle: d["desc"] ?? "",
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _memberTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A223B),
            Color(0xFF11162E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile({
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A223B),
            Color(0xFF11162E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flash_on,
            color: Colors.purple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}