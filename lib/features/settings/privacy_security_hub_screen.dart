import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../widgets/circle_back_button.dart';
import 'security_screen.dart';

class PrivacySecurityHubScreen extends StatefulWidget {
  const PrivacySecurityHubScreen({super.key});

  @override
  State<PrivacySecurityHubScreen> createState() => _PrivacySecurityHubScreenState();
}

class _PrivacySecurityHubScreenState extends State<PrivacySecurityHubScreen> {
  bool analytics = true;

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
                    s.privacySecurityOneLine,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.chipFill,
              leading: const Icon(Icons.pin_outlined),
              title: Text(s.pinCode),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            Card(
              color: AppTheme.chipFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: SwitchListTile(
                title: Text(s.analytics, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.analyticsSub, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                value: analytics,
                activeTrackColor: AppTheme.primary.withOpacity(0.55),
                activeThumbColor: Colors.white,
                onChanged: (v) => setState(() => analytics = v),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.chipFill,
              leading: const Icon(Icons.download_outlined),
              title: Text(s.downloadData),
              subtitle: Text(s.downloadDataSub),
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
