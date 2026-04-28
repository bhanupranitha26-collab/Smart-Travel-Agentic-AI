import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1F3A), Color(0xFF5B4BFF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/travelpilot_logo.png',
                width: 88,
                height: 88,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 72,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'TravelPilot AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered travel pilot',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
