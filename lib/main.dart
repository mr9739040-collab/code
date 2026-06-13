import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/room_members_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const CodeCollabApp(),
    ),
  );
}

class CodeCollabApp extends StatelessWidget {
  const CodeCollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeCollab',

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: Colors.deepPurple,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF070B1D),
      ),

      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,

      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/authGate': (context) => const AuthGateScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),


        '/createRoom': (context) => const CreateRoomScreen(),
        '/joinRoom': (context) => const JoinRoomScreen(),


        '/profile': (context) => const ProfileScreen(),
        '/editProfile': (context) => const EditProfileScreen(),


        '/settings': (context) => const SettingsScreen(),
      },

      onGenerateRoute: (settingsRoute) {
        final args = settingsRoute.arguments;

        if (settingsRoute.name == '/editor') {
          if (args is String) {
            return MaterialPageRoute(
              builder: (_) => EditorScreen(roomId: args),
            );
          }
          return _errorRoute("Editor requires roomId");
        }

        if (settingsRoute.name == '/chat') {
          if (args is String) {
            return MaterialPageRoute(
              builder: (_) => ChatScreen(roomId: args),
            );
          }
          return _errorRoute("Chat requires roomId");
        }

        if (settingsRoute.name == '/members') {
          if (args is String) {
            return MaterialPageRoute(
              builder: (_) => RoomMembersScreen(roomId: args),
            );
          }
          return _errorRoute("Members requires roomId");
        }

        return _errorRoute("Route Not Found");
      },
    );
  }

  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}