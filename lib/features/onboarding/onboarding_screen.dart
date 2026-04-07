import 'package:flutter/material.dart';
import '../../widgets/dots_indicator.dart';
import '../../widgets/primary_button.dart';
import '../../app/theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int index = 0;

  void _goNext() {
    if (index < 2) {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _goSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => index = i),
                children: const [
                  _OnbPage(
                    title: 'Изучить новый язык\nлегко!',
                    subtitle:
                        'Короткие и интерактивные уроки,\nкоторые помогут быстро освоить\nматериал.',
                    imagePath: 'assets/images/onboarding_1.png',
                  ),
                  _OnbPage(
                    title: 'Практика и тренировка\nкаждый день',
                    subtitle:
                        'Интерактивные тесты и упражнения для\nзакрепления информации.',
                    imagePath: 'assets/images/onboarding_2.png',
                  ),
                  _OnbPage(
                    title: 'Начинаем путь изучения\nязыка',
                    subtitle: '',
                    imagePath: 'assets/images/onboarding_3.png',
                  ),
                ],
              ),
            ),
            DotsIndicator(count: 3, index: index),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: index < 2
                  ? Row(
                      children: [
                        TextButton(
                          onPressed: _skipOnboarding,
                          child: const Text(
                            'Пропустить',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 160,
                          child: PrimaryButton(
                            text: 'Продолжить',
                            onPressed: _goNext,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(text: 'НАЧАТЬ', onPressed: _goSignup),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _goLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('У МЕНЯ УЖЕ ЕСТЬ АККАУНТ'),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const _OnbPage({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 22),
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.image_outlined, size: 44, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}