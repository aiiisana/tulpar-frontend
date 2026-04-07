import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

class FlashcardModel {
  final String id;
  final String wordRu;
  final String wordKz;
  final String? transcription;
  final String? exampleSentence;

  FlashcardModel({
    required this.id,
    required this.wordRu,
    required this.wordKz,
    this.transcription,
    this.exampleSentence,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      wordRu: json['wordRu'] as String,
      wordKz: json['wordKz'] as String,
      transcription: json['transcription'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
    );
  }
}

class FlashcardService {
  static final ApiClient _apiClient = ApiClient();

  static Future<List<FlashcardModel>> getAll({int page = 0, int size = 50}) async {
    try {
      final response = await _apiClient.get(
        '/flashcards',
        params: {'page': page, 'size': size},
      );
      // Backend returns PageResponse<FlashcardResponse>
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> content = data['content'] as List<dynamic>? ?? [];
      return content
          .map((item) => FlashcardModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching flashcards: $e');
      return [];
    }
  }
}
