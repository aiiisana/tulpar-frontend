import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

class GrammarRuleModel {
  final String id;
  final String title;
  final String explanation;
  final List<String> examples;
  final String createdAt;

  GrammarRuleModel({
    required this.id,
    required this.title,
    required this.explanation,
    required this.examples,
    required this.createdAt,
  });

  factory GrammarRuleModel.fromJson(Map<String, dynamic> json) {
    return GrammarRuleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      examples: List<String>.from(json['examples'] as List<dynamic>? ?? []),
      createdAt: json['createdAt'] as String,
    );
  }
}

class GrammarService {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<GrammarRuleModel>> getAll() async {
    try {
      final response = await _apiClient.get('/grammar');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => GrammarRuleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching grammar rules: $e');
      return [];
    }
  }

  static Future<GrammarRuleModel?> getById(String id) async {
    try {
      final response = await _apiClient.get('/grammar/$id');
      return GrammarRuleModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching grammar rule by id: $e');
      return null;
    }
  }
}
