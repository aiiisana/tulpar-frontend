import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

class DailyChallengeModel {
  final String id;
  final String challengeDate;
  final List<String> letters;
  final List<String> imageUrls;
  final int wordLength;
  final String? correctWord;

  DailyChallengeModel({
    required this.id,
    required this.challengeDate,
    required this.letters,
    required this.imageUrls,
    required this.wordLength,
    this.correctWord,
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    final letters = List<String>.from(json['letters'] as List<dynamic>? ?? []);
    final correctWord = json['correctWord'] as String?;
    // wordLength from backend; fallback to correctWord length, then letters count
    final wordLength = (json['wordLength'] as int?) ??
        correctWord?.length ??
        letters.length;
    return DailyChallengeModel(
      id: json['id'] as String,
      challengeDate: json['challengeDate'] as String,
      letters: letters,
      imageUrls: List<String>.from(json['imageUrls'] as List<dynamic>? ?? []),
      wordLength: wordLength,
      correctWord: correctWord,
    );
  }
}

class DailyChallengeService {
  static final ApiClient _apiClient = ApiClient();

  static Future<DailyChallengeModel?> getToday() async {
    try {
      final response = await _apiClient.get('/daily-challenge');
      return DailyChallengeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching daily challenge: $e');
      return null;
    }
  }
}
