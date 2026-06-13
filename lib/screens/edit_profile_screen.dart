import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = false;

  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    loadUserData();
  }

  /// ================= LOAD DATA =================
  Future<void> loadUserData() async {
    if (currentUser == null) return;

    emailController.text = currentUser!.email ?? "";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      nameController.text = data["name"] ?? "";
      usernameController.text = data["username"] ?? "";
      phoneController.text = data["phone"] ?? "";
      bioController.text = data["bio"] ?? "";
      locationController.text = data["location"] ?? "";
    }
  }

  /// ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    if (currentUser == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      /// 🔹 Firestore Save
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .set({
        "name": nameController.text.trim(),
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "bio": bioController.text.trim(),
        "location": locationController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      /// 🔥 Firebase Auth Update
      final newName = nameController.text.trim();

      /// 👉 TEMP IMAGE URL (baad me Firebase Storage lagana)
      final newImageUrl =
          currentUser!.photoURL ?? "https://i.pravatar.cc/300";

      await currentUser!.updateDisplayName(newName);
      await currentUser!.updatePhotoURL(newImageUrl);
      await currentUser!.reload();

      /// 🔄 Refresh user locally
      currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Updated Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: isLoading ? null : saveProfile,
            child: const Text(
              "Save",
              style: TextStyle(
                color: Color(0xFF7B6CFF),
                fontSize: 16,
              ),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// ================= PROFILE PHOTO =================
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFF7B6CFF),
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: currentUser?.photoURL == null
                          ? const Icon(
                        Icons.person,
                        size: 55,
                        color: Colors.white,
                      )
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B6CFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              _field("Name", nameController, Icons.person),
              _field("Username", usernameController, Icons.alternate_email),
              _field("Email", emailController, Icons.email, readOnly: true),
              _field("Phone", phoneController, Icons.phone),
              _bioField(),
              _field("Location", locationController, Icons.location_on),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B6CFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: isLoading ? null : saveProfile,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= FIELD =================
  Widget _field(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xFF7B6CFF)),
          filled: true,
          fillColor: const Color(0xFF11162E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  /// ================= BIO =================
  Widget _bioField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: bioController,
        maxLines: 4,
        maxLength: 150,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Bio",
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF11162E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}