import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../learning_content/ai_assistant_screen.dart';
import '../learning_content/articles_screen.dart';
import '../learning_content/flashcards_screen.dart';
import '../learning_content/grammar_screen.dart';
import '../learning_content/alphabet_module_screen.dart';
import '../learning_content/club_agreement_screen.dart';

class LearningTab extends StatelessWidget {
  const LearningTab({super.key});

  static void _openFlashcards(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const FlashcardsScreen()));
  }

  static void _openClubs(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const ClubAgreementScreen()));
  }

  static void _openArticles(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const ArticlesScreen()));
  }

  static void _openAi(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
  }

  static void _openGrammar(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const GrammarScreen()));
  }

  static void _openAlphabet(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const AlphabetModuleScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    final items = <_LearningItem>[
      _LearningItem(title: s.learnFlashcards, imagePath: 'assets/images/flashcards.png', builder: _openFlashcards),
      _LearningItem(title: s.learnClubs, imagePath: 'assets/images/clubs.png', builder: _openClubs),
      _LearningItem(title: s.learnArticles, imagePath: 'assets/images/articles.png', builder: _openArticles),
      _LearningItem(title: s.learnAi, imagePath: 'assets/images/ai_assistant.png', builder: _openAi),
      _LearningItem(title: s.learnGrammar, imagePath: 'assets/images/grammar.png', builder: _openGrammar),
      _LearningItem(title: s.learnSample, imagePath: 'assets/images/grammar.png', builder: _openAlphabet),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.learningTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final item = items[i];
                return _LearningCard(
                  title: item.title,
                  imagePath: item.imagePath,
                  onTap: () => item.builder(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningItem {
  final String title;
  final String imagePath;
  final void Function(BuildContext) builder;

  const _LearningItem({
    required this.title,
    required this.imagePath,
    required this.builder,
  });
}

class _LearningCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _LearningCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.learningCardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 5),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
