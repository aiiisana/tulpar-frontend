import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../widgets/circle_back_button.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = UiLocaleScope.langOf(context);
    final s = AppStr.fromContext(lang);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Row(
              children: [
                const CircleBackButton(),
                Expanded(
                  child: Text(
                    s.termsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 18),
            Text(s.userAgreement, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Text(s.privacyPolicy, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            Text(
              s.termsBody(lang == 'en'),
              style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
