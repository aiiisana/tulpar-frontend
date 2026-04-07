import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';

class LevelLessonScreen extends StatelessWidget {
  final int lessonIndex;
  final String title;
  final String subtitleKk;
  final String description;

  const LevelLessonScreen({
    super.key,
    required this.lessonIndex,
    required this.title,
    required this.subtitleKk,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      'Урок $lessonIndex',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '«$title»',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                subtitleKk,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await AppStorage.markLessonCompleted(lessonIndex);
                  if (context.mounted) Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Продолжить', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
