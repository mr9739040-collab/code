import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import 'activity_screen.dart';
import 'room_members_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? currentUser;

  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  String get userName {
    return currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        "User";
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1D),
      body: SafeArea(child: _getScreen()),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildRoomsScreen();
      case 2:
        return const ActivityScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  /// 🔥 MODERN TOP BAR
  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C4DFF), Color(0xFF3F2B96)],
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.code, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "CodeCollab",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= HOME =================
  Widget _buildHomeScreen() {
    return Column(
      children: [
        _topBar(),

        /// SEARCH
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search rooms...",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("Welcome Back 👋",
                    style: TextStyle(color: Colors.white54)),

                Text(
                  userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                /// 🔥 BIG BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: _bigCard(
                        title: "Create Room",
                        icon: Icons.add,
                        color: Colors.deepPurple,
                        onTap: () =>
                            Navigator.pushNamed(context, '/createRoom'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _bigCard(
                        title: "Join Room",
                        icon: Icons.groups,
                        color: Colors.indigo,
                        onTap: () =>
                            Navigator.pushNamed(context, '/joinRoom'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Available Rooms",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(child: _roomsList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ================= ROOMS TAB =================
  Widget _buildRoomsScreen() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _roomsList(),
          ),
        ),
      ],
    );
  }

  /// 🔥 MODERN ROOMS LIST
  Widget _roomsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var rooms = snapshot.data!.docs;

        if (searchText.isNotEmpty) {
          rooms = rooms.where((room) {
            final data = room.data() as Map<String, dynamic>;
            final name = (data["name"] ?? "").toLowerCase();
            return name.contains(searchText);
          }).toList();
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final data = room.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomMembersScreen(roomId: room.id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A223B), Color(0xFF11162E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [

                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.code,
                          color: Colors.deepPurpleAccent),
                    ),

                    const SizedBox(width: 14),

                    /// TEXT
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            data["name"] ?? "Room",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Room ID: ${room.id}",
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.white38),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🔥 BIG CARD BUTTON
  Widget _bigCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.5),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 NAVBAR
  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTap,
      backgroundColor: const Color(0xFF0B0F2A),
      selectedItemColor: Colors.deepPurpleAccent,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Rooms"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Activity"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}