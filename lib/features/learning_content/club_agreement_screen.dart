import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';

class ClubAgreementScreen extends StatelessWidget {
  const ClubAgreementScreen({super.key});

  static const _body = '''
• Перед тем как войти в разговорный клуб на казахском языке, вы обязуетесь соблюдать следующие правила:

Уважение к участникам Все участники должны общаться вежливо и с уважением. Любые оскорбления, травля, дискриминация или грубые выражения строго запрещены. Нарушение этого правила считается серьёзным и может привести к ограничению доступа к клубу.

Приветствуются новички Даже если вы знаете совсем мало казахских слов, вы можете участвовать в клубе. Главное — пытаться говорить и практиковаться. Никто не будет принуждать говорить больше, чем вы можете, но уважение к другим участникам обязательно.

Свободное общение Участники могут задавать вопросы, отвечать на них, обсуждать простые темы и участвовать в игровых заданиях клуба. Любое агрессивное или неподобающее поведение в общении запрещено.

Конфиденциальность Всё, что обсуждается в клубе, остаётся внутри него. Не разглашайте личные данные других участников, не делайте скриншоты без согласия и не используйте информацию против других пользователей.

Ответственность и последствия нарушений Любое нарушение правил может привести к временной или постоянной блокировке доступа к клубу, а также к ограничению функций приложения. Администрация приложения оставляет за собой право принимать решения о блокировке без предварительного предупреждения, если это необходимо для безопасности и комфортного общения всех участников.

Согласие с правилами Нажимая кнопку «Принять», вы подтверждаете, что прочитали это соглашение, понимаете его и обязуетесь соблюдать все правила клуба. Несоблюдение правил считается нарушением условий пользования и может повлечь последствия, указанные выше.
''';

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
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Пользовательское соглашение клуба',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _body.trim(),
                        style: const TextStyle(fontSize: 14, height: 1.45, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
