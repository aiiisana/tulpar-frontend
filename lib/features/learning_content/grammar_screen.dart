import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/grammar_service.dart';
import '../../widgets/circle_back_button.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<GrammarRuleModel> _rules = [];
  bool _loading = true;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await GrammarService.getAll();
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Expanded(
                    child: Text(
                      'Грамматика',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rules.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: AppTheme.textSecondary, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Правила грамматики ещё не добавлены',
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _load();
                        },
                        child: const Text('Обновить'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Sidebar (rule list) ──────────────────────────────
                    SizedBox(
                      width: 118,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.only(left: 12, right: 8),
                        itemCount: _rules.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final selected = i == _selected;
                          return Material(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.learningTileBg,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () =>
                                  setState(() => _selected = i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                child: Text(
                                  _rules[i].title,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Detail panel ─────────────────────────────────────
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                            right: 12, bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: SingleChildScrollView(
                          child: _RuleDetail(rule: _rules[_selected]),
                        ),
                      ),
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

// ── Rule detail widget ────────────────────────────────────────────────────────

class _RuleDetail extends StatelessWidget {
  final GrammarRuleModel rule;

  const _RuleDetail({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          rule.title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        // Explanation
        Text(
          rule.explanation,
          style: const TextStyle(fontSize: 14, height: 1.45),
        ),

        // Examples
        if (rule.examples.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Примеры',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ...rule.examples.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.chipFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  ex,
                  style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
