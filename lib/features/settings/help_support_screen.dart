import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../widgets/circle_back_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

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
                    s.helpTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.faq, style: const TextStyle(fontWeight: FontWeight.w700)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(s.faqAnswer, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade800)),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(s.contact),
              subtitle: SelectableText(s.contactEmail),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(s.reportBug),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.soon)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
