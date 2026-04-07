import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/article_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<ArticleModel?> _articleFuture;
  ArticleModel? _fullArticle;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  void _loadArticle() {
    _articleFuture = ArticleService.getById(widget.article.id).then((article) {
      setState(() {
        _fullArticle = article;
      });
      return article;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'начинающий':
        return const Color(0xFF4CAF50);
      case 'промежуточный':
        return const Color(0xFF2196F3);
      case 'продвинутый':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<ArticleModel?>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            );
          }

          final article = _fullArticle ?? widget.article;
          final difficultyColor =
              _getDifficultyColor(widget.article.difficultyRu);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.article.difficultyRu,
                    style: TextStyle(
                      fontSize: 12,
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: AppTheme.border,
                  thickness: 1,
                ),
                const SizedBox(height: 16),
                if (article.content != null && article.content!.isNotEmpty)
                  Text(
                    article.content!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                  )
                else
                  Center(
                    child: Text(
                      'Содержимое недоступно',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
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
