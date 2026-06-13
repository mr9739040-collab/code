import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [

          _section("Account"),
          _tile(
            Icons.person,
            "Profile",
            "View profile",
                () => Navigator.pushNamed(context, '/profile'),
          ),

          _section("Preferences"),

          /// 🔥 THEME (REAL WORKING)
          SwitchListTile(
            value: settings.isDark,
            onChanged: (_) => settings.toggleTheme(),
            title: const Text("Dark Mode"),
          ),

          /// 🔥 LANGUAGE (REAL WORKING)
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            subtitle: Text(settings.language),
            onTap: () => settings.toggleLanguage(),
          ),

          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() => notificationsEnabled = val);
            },
            title: const Text("Notifications"),
          ),

          _section("Security"),

          /// 🔥 CHANGE PASSWORD (REAL)
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: _changePasswordDialog,
          ),

          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text("Active Sessions"),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              _showMsg("Logged in: ${user?.email}");
            },
          ),
        ],
      ),
    );
  }

  /// 🔥 CHANGE PASSWORD DIALOG
  void _changePasswordDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter new password",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser!
                    .updatePassword(controller.text);

                Navigator.pop(context);
                _showMsg("Password Updated ✅");
              } catch (e) {
                _showMsg("Re-login required ⚠️");
              }
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(sub),
      onTap: onTap,
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}