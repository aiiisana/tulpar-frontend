import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

enum DifficultyLevel {
  BEGINNER,
  ELEMENTARY,
  INTERMEDIATE,
  ADVANCED,
}

class ArticleModel {
  final String id;
  final String title;
  final String? content;
  final DifficultyLevel difficultyLevel;
  final String createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    this.content,
    required this.difficultyLevel,
    required this.createdAt,
  });

  String get difficultyRu {
    switch (difficultyLevel) {
      case DifficultyLevel.BEGINNER:
        return 'Начинающий';
      case DifficultyLevel.ELEMENTARY:
        return 'Элементарный';
      case DifficultyLevel.INTERMEDIATE:
        return 'Средний';
      case DifficultyLevel.ADVANCED:
        return 'Продвинутый';
    }
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      difficultyLevel: _parseDifficultyLevel(json['difficultyLevel'] as String),
      createdAt: json['createdAt'] as String,
    );
  }

  static DifficultyLevel _parseDifficultyLevel(String value) {
    switch (value.toUpperCase()) {
      case 'BEGINNER':
        return DifficultyLevel.BEGINNER;
      case 'ELEMENTARY':
        return DifficultyLevel.ELEMENTARY;
      case 'INTERMEDIATE':
        return DifficultyLevel.INTERMEDIATE;
      case 'ADVANCED':
        return DifficultyLevel.ADVANCED;
      default:
        return DifficultyLevel.BEGINNER;
    }
  }
}

class ArticleService {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<ArticleModel>> getList({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get(
        '/articles',
        params: {'page': page, 'size': size},
      );
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> content = data['content'] as List<dynamic>? ?? [];
      return content
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      return [];
    }
  }

  static Future<ArticleModel?> getById(String id) async {
    try {
      final response = await _apiClient.get('/articles/$id');
      return ArticleModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching article by id: $e');
      return null;
    }
  }
}
