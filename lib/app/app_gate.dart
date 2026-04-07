import 'package:flutter/material.dart';
import 'package:tulpar_front/app/security_service.dart';
import 'package:tulpar_front/features/auth/enter_pin_screen.dart';
import 'package:tulpar_front/features/auth/set_pin_screen.dart';
import 'app_storage.dart';
import '../features/onboarding/splash_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppStorage.isLoggedIn(),
      builder: (context, snap) {
        if (!snap.hasData) return const SplashScreen();
        final loggedIn = snap.data!;
        if (!loggedIn) return const SplashScreen();

        return FutureBuilder<bool>(
          future: SecurityService().hasPin(),
          builder: (context, s2) {
            if (!s2.hasData) return const SplashScreen();
            return s2.data! ? const EnterPinScreen() : const SetPinScreen(
            );
          },
        );
      },
    );

  }
}
