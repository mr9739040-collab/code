import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// ================= IMAGE PICK =================
  Future<void> pickAndUploadImage(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    File file = File(picked.path);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'profileImage': imageUrl}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (e) {
      debugPrint("Logout error: $e");
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

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              FirebaseFirestore.instance.collection('users').doc(uid).set({
                'name': user.displayName ?? "New User",
                'email': user.email ?? "",
                'createdAt': FieldValue.serverTimestamp(),
                'isOnline': true,
              });

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final doc = snapshot.data!;
            final data = doc.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(
                child: Text(
                  "No data available",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final name = data['name'] ?? "No Name";
            final email = data['email'] ?? "No Email";
            final bio = data['bio'] ?? "No Bio";
            final phone = data['phone'] ?? "No Phone";
            final location = data['location'] ?? "No Location";
            final isOnline = data['isOnline'] ?? false;
            final profileImage = data['profileImage'];

            final joinedOn = data['createdAt'] != null
                ? (data['createdAt'] as Timestamp)
                .toDate()
                .toString()
                .substring(0, 10)
                : "N/A";

            return SingleChildScrollView(
              child: Column(
                children: [
                  /// 🔝 TOP BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        /// ✅ FIXED BACK BUTTON
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                                  (route) => false,
                            );
                          },
                        ),

                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/settings',
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/editProfile',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 👤 PROFILE IMAGE
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                        const Color(0xFF6C4DFF),
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => pickAndUploadImage(uid),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C4DFF),
                              shape: BoxShape.circle,
                            ),
                            padding:
                            const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: isOnline
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline
                            ? "Online"
                            : "Offline",
                        style: TextStyle(
                          color: isOnline
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle("ABOUT"),
                  _infoTile("Full Name", name),
                  _infoTile("Phone", phone),
                  _infoTile("Location", location),
                  _infoTile("Joined On", joinedOn),
                  _infoTile("Bio", bio),

                  const SizedBox(height: 20),

                  _sectionTitle("ACTIVITY"),
                  _infoTile(
                    "Last Active",
                    isOnline
                        ? "Active now"
                        : "Offline",
                  ),

                  const SizedBox(height: 25),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(
                                0xFF6C4DFF),
                            minimumSize:
                            const Size(
                              double.infinity,
                              50,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/editProfile',
                            );
                          },
                          child: const Text(
                            "Edit Profile",
                          ),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton(
                          style:
                          OutlinedButton.styleFrom(
                            minimumSize:
                            const Size(
                              double.infinity,
                              50,
                            ),
                            side: const BorderSide(
                              color:
                              Colors.white24,
                            ),
                          ),
                          onPressed: () =>
                              logout(uid),
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 18,
        bottom: 8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1238),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}