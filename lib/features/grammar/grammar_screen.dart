import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/grammar_service.dart';

// ── Список правил ─────────────────────────────────────────────────────────────

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<GrammarRuleModel> _rules = [];
  bool _loading = true;

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
      appBar: AppBar(
        title: const Text('Грамматика'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Правила пока не добавлены',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final rule = _rules[i];
                      return _GrammarCard(
                        rule: rule,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GrammarDetailScreen(rule: rule),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Карточка правила ──────────────────────────────────────────────────────────

class _GrammarCard extends StatelessWidget {
  final GrammarRuleModel rule;
  final VoidCallback onTap;

  const _GrammarCard({required this.rule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 2),
                color: Color(0x18000000)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.chipFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_outlined,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (rule.examples.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${rule.examples.length} ${_exampleWord(rule.examples.length)}',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  String _exampleWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'пример';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'примера';
    }
    return 'примеров';
  }
}

// ── Детальный экран правила ───────────────────────────────────────────────────

class GrammarDetailScreen extends StatelessWidget {
  final GrammarRuleModel rule;
  const GrammarDetailScreen({super.key, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Грамматика'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              rule.title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Объяснение
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                rule.explanation,
                style: const TextStyle(fontSize: 14, height: 1.55),
              ),
            ),

            // Примеры
            if (rule.examples.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Примеры',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...rule.examples.map((ex) => _ExampleTile(text: ex)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Плитка примера ────────────────────────────────────────────────────────────

class _ExampleTile extends StatelessWidget {
  final String text;
  const _ExampleTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.chipFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
