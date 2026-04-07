import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';
import 'club_agreement_screen.dart';

class SpeakingClubsScreen extends StatelessWidget {
  const SpeakingClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Expanded(
                    child: Text(
                      'Разговорные клубы для новичков',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClubAgreementScreen()),
                      );
                    },
                    child: const Text('Соглашение', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: const [
                  _ClubCard(
                    titleKk: 'Менің қазақ тіліндегі күнім',
                    description:
                        'Короткие темы на каждый день: как прошёл день, планы, эмоции — в мягком темпе для новичков.',
                    time: 'в 12:00',
                  ),
                  SizedBox(height: 12),
                  _ClubCard(
                    titleKk: 'Сәлемдесу және танысу',
                    description: 'Практика приветствий и знакомства: шаблоны фраз и мини-диалоги.',
                    time: 'в 18:00',
                  ),
                  SizedBox(height: 12),
                  _ClubCard(
                    titleKk: 'Қазақ тілінде сұрақ-жауап',
                    description: 'Вопросы и ответы: «не істедің?», «қайда бардың?» и ответы по уровню.',
                    time: 'в 20:00',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final String titleKk;
  final String description;
  final String time;

  const _ClubCard({
    required this.titleKk,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.learningTileBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleKk, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Войти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
