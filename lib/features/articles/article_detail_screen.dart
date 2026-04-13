import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/article_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;
  final bool initialKazakh;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
    this.initialKazakh = false,
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<ArticleModel?> _articleFuture;
  ArticleModel? _fullArticle;
  late bool _isKazakh;

  @override
  void initState() {
    super.initState();
    _isKazakh = widget.initialKazakh;
    _loadArticle();
  }

  void _loadArticle() {
    _articleFuture = ArticleService.getById(widget.article.id).then((article) {
      if (mounted) setState(() => _fullArticle = article);
      return article;
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
    final article = _fullArticle ?? widget.article;
    final displayTitle = article.displayTitle(_isKazakh);
    final displayContent = article.displayContent(_isKazakh);
    final diffColor = _getDifficultyColor(article.difficultyLevel);
    final diffLabel = article.getDifficulty(_isKazakh);

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            displayTitle,
            key: ValueKey(displayTitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
      body: FutureBuilder<ArticleModel?>(
        future: _articleFuture,
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  _fullArticle == null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero cover image
                if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                  _ArticleHeroImage(imageUrl: article.imageUrl!),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          displayTitle,
                          key: ValueKey('title_$_isKazakh'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Difficulty badge
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
                      const SizedBox(height: 16),
                      Divider(color: AppTheme.border, thickness: 1),
                      const SizedBox(height: 16),

                      // Content
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (displayContent != null &&
                          displayContent.isNotEmpty)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            displayContent,
                            key: ValueKey('content_$_isKazakh'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.7,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            _isKazakh
                                ? 'Мазмұн қолжетімді емес'
                                : 'Содержимое недоступно',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Hero image widget ────────────────────────────────────────────────────────

class _ArticleHeroImage extends StatelessWidget {
  final String imageUrl;
  const _ArticleHeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          color: const Color(0xFFF0F0F0),
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 48, color: Color(0xFFBDBDBD)),
          ),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 220,
                color: const Color(0xFFF0F0F0),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
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
        width: _pillW * 2,
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
            // Labels on top
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
