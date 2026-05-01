import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/intro_screen.dart';
import 'screens/profile/profile_page.dart';

/// Global theme controller
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // 🌞 Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF7CB342),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7CB342),
            ),
          ),

          // 🌙 Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7CB342),
              brightness: Brightness.dark,
            ),
          ),

          initialRoute: "/",

          routes: {
            "/": (context) => const IntroScreen(),
            "/profile": (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}
