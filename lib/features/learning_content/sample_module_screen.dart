import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';

class SampleModuleScreen extends StatelessWidget {
  const SampleModuleScreen({super.key});

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
                  const Expanded(
                    child: Text(
                      'sample',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Демо-модуль: замените на свой контент или удалите карточку из сетки «Обучение».',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.45, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
