import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Text(
          'Túlpar',
          style: TextStyle(
            color: Color(0xFFEFE9D7),
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
