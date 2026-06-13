import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1D),

      /// 🔥 GRADIENT APPBAR
      appBar: AppBar(
        title: const Text("Activity"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C4DFF), Color(0xFF3F2B96)],
            ),
          ),
        ),
      ),

      /// 🔥 COLLECTION GROUP (MAIN FIX)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup("activity")
            .snapshots(),

        builder: (context, snapshot) {

          /// LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          /// EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No activity yet 🚀",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final activities = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {

              final data =
              activities[index].data() as Map<String, dynamic>;

              final type = data["type"] ?? "";
              final userName = data["userName"] ?? "User";
              final roomName = data["roomName"] ?? "Room";
              final time = data["time"];

              return _activityCard(
                icon: _getIcon(type),
                title: _getTitle(type, userName, roomName),
                desc: _getDescription(type, roomName),
                time: _timeAgo(time),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔥 ICON
  IconData _getIcon(String type) {
    switch (type) {
      case "join":
        return Icons.person_add;
      case "leave":
        return Icons.logout;
      case "message":
        return Icons.chat;
      default:
        return Icons.flash_on;
    }
  }

  /// 🔥 TITLE
  String _getTitle(String type, String user, String room) {
    switch (type) {
      case "join":
        return "$user joined $room";
      case "leave":
        return "$user left $room";
      case "message":
        return "$user sent message";
      default:
        return "New Activity";
    }
  }

  /// 🔥 DESC
  String _getDescription(String type, String room) {
    switch (type) {
      case "join":
        return "User entered room";
      case "leave":
        return "User exited room";
      case "message":
        return "Message in $room";
      default:
        return "Recent activity";
    }
  }

  /// 🔥 TIME AGO
  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return "Now";

    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  /// 🔥 MODERN CARD
  Widget _activityCard({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A223B), Color(0xFF11162E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          /// ICON
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text(desc,
                    style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),

          Text(time,
              style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}