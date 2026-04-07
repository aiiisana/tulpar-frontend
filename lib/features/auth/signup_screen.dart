import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tulpar_front/app/security_service.dart';
import 'package:tulpar_front/features/auth/set_pin_screen.dart';
import 'package:tulpar_front/features/setup/home_shell.dart';
import '../../app/theme.dart';
import '../../app/app_storage.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_auth_row.dart';
import 'login_screen.dart';
import 'social_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  bool passMismatch = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
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

  Future<void> _goNextAfterAuth() async {
    // Отправляем уровень + цель на бэкенд.
    // Вызываем здесь — к этому моменту Firebase-токен уже есть,
    // и ApiClient может добавить Authorization: Bearer <token>.
    // Ошибки внутри OnboardingService не бросаются — не блокируют вход.
    await OnboardingService.sendIfNeeded();

    final hasPin = await SecurityService().hasPin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetPinScreen()),
    );
  }

  // ── Email / Password ────────────────────────────────────────────────────────

  Future<void> _signupWithEmail() async {
    final email = emailCtrl.text.trim();
    final p1 = passCtrl.text;
    final p2 = pass2Ctrl.text;
    final first = firstCtrl.text.trim();
    final last = lastCtrl.text.trim();

    // Проверяем совпадение паролей локально
    if (p1.isNotEmpty && p2.isNotEmpty && p1 != p2) {
      setState(() => passMismatch = true);
      return;
    }
    if (email.isEmpty || p1.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Firebase создаёт аккаунт — пароль хранится в Firebase, не у нас
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: p1,
      );

      // Сохраняем имя локально для ProfileTab
      final firstName = first.isEmpty ? 'User' : first;
      await AppStorage.saveProfile(firstName: firstName, lastName: last);

      // Обновляем displayName в Firebase (опционально, для удобства)
      await result.user?.updateDisplayName(
        last.isEmpty ? firstName : '$firstName $last',
      );

      await _goNextAfterAuth();
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = _mapError(e.code));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  Future<void> _signupWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final user = await SocialAuth.signInWithGoogle();
      if (user == null) return;

      _saveDisplayName(user.displayName);
      await _goNextAfterAuth();
    } catch (_) {
      if (mounted) {
        setState(() => errorMessage = 'Не удалось войти через Google');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  Future<void> _signupWithApple() async {
    setState(() => isLoading = true);
    try {
      final user = await SocialAuth.signInWithApple();
      if (user == null) return;

      _saveDisplayName(user.displayName);
      await _goNextAfterAuth();
    } catch (_) {
      if (mounted) {
        setState(() => errorMessage = 'Не удалось войти через Apple');
      }
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
        'email-already-in-use' =>
          'Аккаунт с этой почтой уже существует. Войдите.',
        'weak-password' => 'Пароль слишком простой (минимум 6 символов)',
        'invalid-email' => 'Неверный формат email',
        'network-request-failed' => 'Нет соединения с интернетом',
        _ => 'Ошибка регистрации. Попробуйте ещё раз',
      };

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final passErrorText = passMismatch ? 'Пароли не совпадают' : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                const SizedBox(height: 34),
                Text(
                  'Создать аккаунт',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 22),

                SocialAuthRow(
                  title: 'Зарегистрироваться через',
                  onGoogle: _signupWithGoogle,
                  onApple: _signupWithApple,
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: firstCtrl,
                  decoration:
                      _decor(hint: 'Имя', icon: Icons.person_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastCtrl,
                  decoration:
                      _decor(hint: 'Фамилия', icon: Icons.person_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decor(
                      hint: 'Электронная почта', icon: Icons.mail_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure1,
                  onChanged: (_) {
                    if (passMismatch) {
                      setState(() =>
                          passMismatch = passCtrl.text != pass2Ctrl.text);
                    }
                  },
                  decoration: _decor(
                    hint: 'Пароль',
                    icon: Icons.lock_outline,
                    error: passMismatch,
                    suffix: IconButton(
                      onPressed: () => setState(() => obscure1 = !obscure1),
                      icon: Icon(
                        obscure1 ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pass2Ctrl,
                  obscureText: obscure2,
                  onChanged: (_) {
                    setState(() {
                      passMismatch = passCtrl.text.isNotEmpty &&
                          pass2Ctrl.text.isNotEmpty &&
                          passCtrl.text != pass2Ctrl.text;
                    });
                  },
                  decoration: _decor(
                    hint: 'Повтор пароля',
                    icon: Icons.lock_outline,
                    error: passMismatch,
                    errorText: passErrorText,
                    suffix: IconButton(
                      onPressed: () => setState(() => obscure2 = !obscure2),
                      icon: Icon(
                        obscure2 ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                // Общая ошибка (не совпадение паролей)
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 18),
                isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Создать аккаунт',
                        onPressed: _signupWithEmail,
                      ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Уже есть аккаунт? ',
                        style: TextStyle(fontSize: 12)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Войти',
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
