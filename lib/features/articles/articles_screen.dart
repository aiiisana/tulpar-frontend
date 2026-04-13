import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/article_service.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({Key? key}) : super(key: key);

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late Future<List<ArticleModel>> _articlesFuture;
  List<ArticleModel> _articles = [];
  bool _isKazakh = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    _articlesFuture = ArticleService.getList().then((articles) {
      setState(() => _articles = articles);
      return articles;
    });
  }

  Color _getDifficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.BEGINNER:
        return const Color(0xFF4CAF50);
      case DifficultyLevel.ELEMENTARY:
        return const Color(0xFF2196F3);
      case DifficultyLevel.INTERMEDIATE:
        return const Color(0xFFFF9800);
      case DifficultyLevel.ADVANCED:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статьи'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _LanguageToggle(
              isKazakh: _isKazakh,
              onChanged: (v) => setState(() => _isKazakh = v),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<List<ArticleModel>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || _articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Статьи недоступны',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadArticles,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadArticles();
              await _articlesFuture;
            },
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                final diffColor = _getDifficultyColor(article.difficultyLevel);
                final displayTitle = article.displayTitle(_isKazakh);
                final diffLabel = article.getDifficulty(_isKazakh);

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(
                        article: article,
                        initialKazakh: _isKazakh,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover image
                        if (article.imageUrl != null &&
                            article.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              article.imageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          height: 160,
                                          color: const Color(0xFFF0F0F0),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Text(
                                        displayTitle,
                                        key: ValueKey(displayTitle),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: diffColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        diffLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: diffColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Sliding language toggle ──────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final bool isKazakh;
  final ValueChanged<bool> onChanged;

  const _LanguageToggle({required this.isKazakh, required this.onChanged});

  static const double _pillW = 46;
  static const double _h = 32;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isKazakh),
      child: Container(
        width: _pillW * 2,   // ← фиксированная ширина = 92px
        height: _h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(_h / 2),
        ),
        child: Stack(
          children: [
            // Sliding white pill
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              left: isKazakh ? _pillW : 0,
              top: 0,
              child: Container(
                width: _pillW,
                height: _h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_h / 2),
                ),
              ),
            ),
            // Labels on top of pill
            Row(
              children: [
                _label('РУ', !isKazakh),
                _label('ҚАЗ', isKazakh),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool active) {
    return SizedBox(
      width: _pillW,
      height: _h,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppTheme.primary : Colors.white,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
