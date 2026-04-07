import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

class DailyChallengeModel {
  final String id;
  final String challengeDate;
  final List<String> letters;
  final List<String> imageUrls;

  DailyChallengeModel({
    required this.id,
    required this.challengeDate,
    required this.letters,
    required this.imageUrls,
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    return DailyChallengeModel(
      id: json['id'] as String,
      challengeDate: json['challengeDate'] as String,
      letters: List<String>.from(json['letters'] as List<dynamic>? ?? []),
      imageUrls: List<String>.from(json['imageUrls'] as List<dynamic>? ?? []),
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
