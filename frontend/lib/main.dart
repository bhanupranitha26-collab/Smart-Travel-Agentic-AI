import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(SmartTravelApp());
}

class SmartTravelApp extends StatelessWidget {
  static const Color _primary = Color(0xFF008080); // Stitch Primary Teal
  static const Color _secondary = Color(0xFF4DB6AC); // Stitch Light Teal
  static const Color _background = Color(0xFFF8F9FA); // Stitch Light Gray

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelPilot AI',
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          secondary: _secondary,
          surface: Colors.white,
          background: _background,
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0, // Using manual shadow instead
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: _primary, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
      home: const _BootstrapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userName = prefs.getString('userName') ?? 'Traveler';
    final userEmail = prefs.getString('userEmail') ?? '';

    if (!mounted) return;
    setState(() {
      _nextScreen = isLoggedIn
          ? AppShell(userName: userName, userEmail: userEmail)
          : LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _nextScreen ?? const SplashScreen();
  }
}
