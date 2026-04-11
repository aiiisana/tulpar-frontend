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
  static const _kXpDateKey = 'daily_challenge_xp_date';

  static Future<DailyChallengeModel?> getToday() async {
    try {
      final response = await _apiClient.get('/daily-challenge');
      return DailyChallengeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching daily challenge: $e');
      return null;
    }
  }

  /// Возвращает true если +10 XP за сегодня ещё не начислялись.
  static Future<bool> canEarnXpToday() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kXpDateKey) ?? '';
    final today = _todayStr();
    return saved != today;
  }

  /// Отправляет ответ на бэкенд, проверяет правильность и начисляет +10 XP.
  /// Возвращает [DailyChallengeSubmitResult] с полями correct, xpAwarded, correctWord.
  static Future<DailyChallengeSubmitResult> submitAnswer({
    required String challengeId,
    required String answer,
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

      // Локальный кэш: не спрашиваем снова сегодня
      if (result.correct) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kXpDateKey, _todayStr());
      }
      return result;
    } catch (e) {
      debugPrint('[DailyChallenge] submitAnswer failed: $e');
      return DailyChallengeSubmitResult(correct: false, xpAwarded: 0, correctWord: '');
    }
  }

  /// Legacy: используется только если нет данных об ответе.
  static Future<bool> completeChallenge(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    if (prefs.getString(_kXpDateKey) == today) return false;
    try {
      await _apiClient.post('/daily-challenge/$challengeId/complete');
    } catch (e) {
      debugPrint('[DailyChallenge] complete failed: $e');
    }
    await prefs.setString(_kXpDateKey, today);
    return true;
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
