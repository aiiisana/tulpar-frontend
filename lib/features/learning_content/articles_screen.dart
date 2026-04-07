import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/article_service.dart';
import '../../widgets/circle_back_button.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  List<ArticleModel> _articles = [];
  bool _loading = true;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final articles = await ArticleService.getList(size: 50);
    if (!mounted) return;
    setState(() {
      _articles = articles;
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
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Expanded(
                    child: Text(
                      'Статьи',
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

            // ── Body ─────────────────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_articles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined,
                          color: AppTheme.textSecondary, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Статьи пока не добавлены',
                        style:
                            TextStyle(color: AppTheme.textSecondary),
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
                    // ── Article list sidebar ──────────────────────────
                    SizedBox(
                      width: 118,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.only(left: 12, right: 8),
                        itemCount: _articles.length,
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _articles[i].title,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Difficulty badge
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                                .withOpacity(0.25)
                                            : AppTheme.chipFill,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _articles[i].difficultyRu,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: selected
                                              ? Colors.white
                                                  .withOpacity(0.9)
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Article content ───────────────────────────────
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
                          child: _ArticleContent(
                              article: _articles[_selected]),
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

// ── Article content widget ────────────────────────────────────────────────────

class _ArticleContent extends StatelessWidget {
  final ArticleModel article;

  const _ArticleContent({required this.article});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          article.title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),

        // Difficulty + date row
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.chipFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                article.difficultyRu,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(article.createdAt),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Body text
        if (article.content != null && article.content!.isNotEmpty)
          Text(
            article.content!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          )
        else
          Text(
            'Содержание статьи «${article.title}» скоро появится.',
            style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
