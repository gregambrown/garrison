import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:garrison/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/room_screen.dart';
import 'services/firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart'; // From flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseService.initFirebase();
  await FirebaseService.signInAnonymously(); // Anonymous login

  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool('seen_onboarding') ?? false;

  runApp(GarrisonApp(seenIntro: seenIntro));
}

class GarrisonApp extends StatelessWidget {
  final bool seenIntro;
  GarrisonApp({super.key, required this.seenIntro});

  final ThemeData garrisonTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green.shade800,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade900),
    scaffoldBackgroundColor: Colors.grey.shade100,
    fontFamily: 'Montserrat', // or a bolder, island-style font
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Bebas Neue"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.green.shade100,
      labelStyle: const TextStyle(color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garrison',
      theme: garrisonTheme,
      home: seenIntro ? const RoomScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
