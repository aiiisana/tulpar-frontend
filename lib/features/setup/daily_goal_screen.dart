import 'package:flutter/material.dart';
import 'package:tulpar_front/features/auth/signup_screen.dart';
import 'package:tulpar_front/features/setup/home_shell.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_header.dart';
import '../../widgets/select_pill.dart';
import '../../app/app_storage.dart';

class DailyGoalScreen extends StatefulWidget {
  const DailyGoalScreen({super.key});

  @override
  State<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends State<DailyGoalScreen> {
  int? selected;

  void _start() {
    if (selected == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = const [15, 30, 45, 60, 90, 120];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 10),
              ProgressHeader(
                progressIndex: 2,
                progressTotal: 2,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 26),
              Text(
                'Ежедневная цель\nобучения.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Сколько времени вы готовы уделять\nкаждый день?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final m in goals)
                    SizedBox(
                      width: 92,
                      child: SelectPill(
                        text: '$m min',
                        leading: null,
                        selected: selected == m,
                        onTap: () async {
                          setState(() => selected = m);
                          await AppStorage.setGoalMinutes(m);
                        },
                        compact: true,
                      ),
                    ),
                  SizedBox(
                    width: 92,
                    child: SelectPill(
                      text: 'Other',
                      leading: null,
                      selected: selected == -1,
                      onTap: () => setState(() => selected = -1),
                      compact: true,
                    ),
                  ),
                ],
              ),

              const Spacer(),
              PrimaryButton(text: 'НАЧАТЬ', onPressed: selected == null ? null : _start),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
