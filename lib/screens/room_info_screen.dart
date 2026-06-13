import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomInfoScreen extends StatefulWidget {
  final String roomId;

  const RoomInfoScreen({super.key, required this.roomId});

  @override
  State<RoomInfoScreen> createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen> {

  /// ✅ FETCH USER NAME FROM USERS COLLECTION
  Future<String> getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!doc.exists) return "User";

      final data = doc.data() as Map<String, dynamic>;

      return data["name"] ??
          data["displayName"] ??
          (data["email"] != null
              ? data["email"].toString().split("@")[0]
              : "User");
    } catch (e) {
      return "User";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1D),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Room Details"),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.roomId)
            .snapshots(),

        builder: (context, roomSnap) {

          if (roomSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!roomSnap.hasData || !roomSnap.data!.exists) {
            return const Center(
              child: Text("Room not found",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final roomData =
          roomSnap.data!.data() as Map<String, dynamic>;

          final roomName = roomData["name"] ?? "Room";

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
                      colors: [Color(0xFF6C4DFF), Color(0xFF3F2B96)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// MEMBERS
                const Text(
                  "Members",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("rooms")
                      .doc(widget.roomId)
                      .collection("members")
                      .snapshots(),

                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final members = snapshot.data!.docs;

                    return Column(
                      children: members.map((doc) {

                        final uid = doc.id;

                        return FutureBuilder<String>(
                          future: getUserName(uid),
                          builder: (context, snap) {

                            final name = snap.data ?? "Loading...";

                            return Container(
                              margin:
                              const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11162E),
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [

                                  CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Text(
                                      name[0].toUpperCase(),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
}