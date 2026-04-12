import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../widgets/circle_back_button.dart';
import '../../widgets/default_popup.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: AppStorage.getEmail(),
          builder: (context, snap) {
            final email = snap.data ?? '—';
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                Row(
                  children: [
                    const CircleBackButton(),
                    Expanded(
                      child: Text(
                        s.accountTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 20),
                Text(s.accountEditHint, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35)),
                const SizedBox(height: 18),
                _Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(s.email),
                        subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(s.password),
                        subtitle: Text('••••••••'),
                        trailing: Text(s.soon, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DefaultPopup(
                              message: s.passwordChangeSoon,
                              buttonText: 'Ок',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _snack(BuildContext context, String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.chipFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
