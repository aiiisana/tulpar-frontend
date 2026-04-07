import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tulpar_front/app/security_service.dart';
import 'package:tulpar_front/features/auth/set_pin_screen.dart';
import 'package:tulpar_front/features/setup/home_shell.dart';
import '../../app/theme.dart';
import '../../app/app_storage.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_auth_row.dart';
import 'signup_screen.dart';
import 'social_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscure = true;

  bool wrongCreds = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool error = false,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      suffixIcon: suffix,
      errorText: errorText,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: error ? Colors.red : AppTheme.border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
            color: error ? Colors.red : AppTheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  // После успешного входа в Firebase идём к PIN-экрану
  Future<void> _goNextAfterAuth() async {
    final hasPin = await SecurityService().hasPin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasPin ? const HomeShell() : const SetPinScreen(),
      ),
    );
  }

  // ── Email / Password ────────────────────────────────────────────────────────

  Future<void> _loginWithEmail() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;

    setState(() {
      isLoading = true;
      wrongCreds = false;
      errorMessage = null;
    });

    try {
      // Firebase проверяет пароль на своей стороне — никаких хэшей локально
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await _goNextAfterAuth();
    } on FirebaseAuthException catch (e) {
      setState(() {
        wrongCreds = true;
        errorMessage = _mapError(e.code);
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final user = await SocialAuth.signInWithGoogle();
      if (user == null) return; // пользователь закрыл диалог

      // Сохраняем отображаемое имя для ProfileTab
      _saveDisplayName(user.displayName);
      await _goNextAfterAuth();
    } catch (_) {
      if (mounted) setState(() => errorMessage = 'Не удалось войти через Google');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  Future<void> _loginWithApple() async {
    setState(() => isLoading = true);
    try {
      final user = await SocialAuth.signInWithApple();
      if (user == null) return;

      // Apple передаёт имя только при первом входе
      _saveDisplayName(user.displayName);
      await _goNextAfterAuth();
    } catch (_) {
      if (mounted) setState(() => errorMessage = 'Не удалось войти через Apple');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _saveDisplayName(String? displayName) async {
    final name = (displayName ?? '').trim();
    if (name.isEmpty) return;
    final parts = name.split(' ');
    await AppStorage.saveProfile(
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
  }

  String _mapError(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Неверная почта или пароль',
        'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
        'network-request-failed' => 'Нет соединения с интернетом',
        _ => 'Ошибка входа. Попробуйте ещё раз',
      };

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                const SizedBox(height: 34),
                Text(
                  'С возвращением!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 22),

                SocialAuthRow(
                  title: 'Войти через',
                  onGoogle: _loginWithGoogle,
                  onApple: _loginWithApple,
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (wrongCreds) setState(() => wrongCreds = false);
                  },
                  decoration: _decor(
                    hint: 'Электронная почта',
                    icon: Icons.mail_outline,
                    error: wrongCreds,
                    errorText: wrongCreds ? errorMessage : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  onChanged: (_) {
                    if (wrongCreds) setState(() => wrongCreds = false);
                  },
                  decoration: _decor(
                    hint: 'Пароль',
                    icon: Icons.lock_outline,
                    error: wrongCreds,
                    suffix: IconButton(
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Войти',
                        onPressed: _loginWithEmail,
                      ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Нет аккаунта? ',
                        style: TextStyle(fontSize: 12)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen()),
                      ),
                      child: const Text(
                        'Создать',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
