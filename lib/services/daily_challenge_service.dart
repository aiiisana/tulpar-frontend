import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/api_client.dart';

class DailyChallengeModel {
  final String id;
  final String challengeDate;
  final List<String> letters;
  final List<String> imageUrls;
  final int wordLength;
  final String? correctWord;
  /// Backend tells us whether THIS user already completed the challenge today.
  final bool completedByCurrentUser;

  DailyChallengeModel({
    required this.id,
    required this.challengeDate,
    required this.letters,
    required this.imageUrls,
    required this.wordLength,
    this.correctWord,
    this.completedByCurrentUser = false,
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
      completedByCurrentUser: json['completedByCurrentUser'] as bool? ?? false,
    );
  }
}

class DailyChallengeSubmitResult {
  final bool correct;
  final int xpAwarded;
  final String correctWord;

  DailyChallengeSubmitResult({
    required this.correct,
    required this.xpAwarded,
    required this.correctWord,
  });
}

class DailyChallengeService {
  static final ApiClient _apiClient = ApiClient();

  /// SharedPrefs key is scoped per-user so different accounts on the same
  /// device don't share completion state.
  static String _xpDateKey(String userId) => 'daily_challenge_xp_date_$userId';

  static Future<DailyChallengeModel?> getToday() async {
    try {
      final response = await _apiClient.get('/daily-challenge');
      return DailyChallengeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching daily challenge: $e');
      return null;
    }
  }

  /// Returns true if this [userId] has NOT yet earned XP today.
  /// Primary source of truth is the backend flag [DailyChallengeModel.completedByCurrentUser];
  /// this is a local fallback used before the network response arrives.
  static Future<bool> canEarnXpToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_xpDateKey(userId)) ?? '';
    return saved != _todayStr();
  }

  /// Sends the user's answer to the backend.
  /// On correct answer saves today's date locally (per-user key) to avoid
  /// an extra round-trip on the next app launch.
  static Future<DailyChallengeSubmitResult> submitAnswer({
    required String challengeId,
    required String answer,
    required String userId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/daily-challenge/submit',
        data: {
          'challengeId': challengeId,
          'answer': answer,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final result = DailyChallengeSubmitResult(
        correct:     data['correct'] as bool? ?? false,
        xpAwarded:   data['xpAwarded'] as int? ?? 0,
        correctWord: data['correctWord'] as String? ?? '',
      );

      // Per-user local cache so we don't hit network unnecessarily next launch
      if (result.correct) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_xpDateKey(userId), _todayStr());
      }
      return result;
    } catch (e) {
      debugPrint('[DailyChallenge] submitAnswer failed: $e');
      return DailyChallengeSubmitResult(correct: false, xpAwarded: 0, correctWord: '');
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
