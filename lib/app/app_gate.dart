import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tulpar_front/app/security_service.dart';
import 'package:tulpar_front/features/auth/enter_pin_screen.dart';
import 'package:tulpar_front/features/auth/set_pin_screen.dart';
import 'app_storage.dart';
import '../features/onboarding/splash_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  /// Пользователь считается авторизованным если:
  /// 1. Есть локальный флаг (setLoggedIn(true)) — обычный случай, ИЛИ
  /// 2. Firebase знает текущего пользователя — восстановление сессии
  ///    (работает оффлайн, Firebase кэширует auth-токен локально)
  Future<bool> _isLoggedIn() async {
    final local = await AppStorage.isLoggedIn();
    if (local) return true;
    // Firebase хранит токен локально и не требует интернета для этой проверки
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Синхронизируем локальный флаг
      await AppStorage.setLoggedIn(true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snap) {
        if (!snap.hasData) return const SplashScreen();
        final loggedIn = snap.data!;
        if (!loggedIn) return const SplashScreen();

        return FutureBuilder<bool>(
          future: SecurityService().hasPin(),
          builder: (context, s2) {
            if (!s2.hasData) return const SplashScreen();
            return s2.data! ? const EnterPinScreen() : const SetPinScreen();
          },
        );
      },
    );
  }
}
