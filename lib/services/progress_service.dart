import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

// ── Result model ──────────────────────────────────────────────────────────────

class ProgressResult {
  final String progressId;
  final String exerciseId;
  final bool correct;
  final String status; // IN_PROGRESS | COMPLETED | FAILED
  final int attempts;

  ProgressResult({
    required this.progressId,
    required this.exerciseId,
    required this.correct,
    required this.status,
    required this.attempts,
  });

  factory ProgressResult.fromJson(Map<String, dynamic> j) => ProgressResult(
        progressId: j['progressId'] as String? ?? '',
        exerciseId: j['exerciseId'] as String? ?? '',
        correct:    j['correct'] as bool? ?? false,
        status:     j['status'] as String? ?? 'IN_PROGRESS',
        attempts:   (j['attempts'] as num?)?.toInt() ?? 1,
      );
}

// ── Progress summary model ────────────────────────────────────────────────────

class ProgressSummary {
  final int totalAttempted;
  final int totalCompleted;
  final int totalFailed;
  final int totalInProgress;

  ProgressSummary({
    required this.totalAttempted,
    required this.totalCompleted,
    required this.totalFailed,
    required this.totalInProgress,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        totalAttempted:  (j['totalAttempted']  as num?)?.toInt() ?? 0,
        totalCompleted:  (j['totalCompleted']  as num?)?.toInt() ?? 0,
        totalFailed:     (j['totalFailed']     as num?)?.toInt() ?? 0,
        totalInProgress: (j['totalInProgress'] as num?)?.toInt() ?? 0,
      );

  factory ProgressSummary.empty() => ProgressSummary(
        totalAttempted: 0,
        totalCompleted: 0,
        totalFailed: 0,
        totalInProgress: 0,
      );
}

// ── Progress history item ─────────────────────────────────────────────────────

class ProgressHistoryItem {
  final String progressId;
  final String exerciseId;
  final String status; // IN_PROGRESS | COMPLETED | FAILED
  final int attempts;
  final bool correct;
  final String? completedAt;

  ProgressHistoryItem({
    required this.progressId,
    required this.exerciseId,
    required this.status,
    required this.attempts,
    required this.correct,
    this.completedAt,
  });

  factory ProgressHistoryItem.fromJson(Map<String, dynamic> j) =>
      ProgressHistoryItem(
        progressId:  j['progressId']  as String? ?? '',
        exerciseId:  j['exerciseId']  as String? ?? '',
        status:      j['status']      as String? ?? 'IN_PROGRESS',
        attempts:    (j['attempts']   as num?)?.toInt() ?? 1,
        correct:     j['correct']     as bool?   ?? false,
        completedAt: j['completedAt'] as String?,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class ProgressService {
  static final _api = ApiClient();

  /// POST /progress — отправляет ответ пользователя на упражнение.
  ///
  /// [exerciseId] — UUID упражнения
  /// [userAnswer] — строка-ответ (выбранный вариант или составленное предложение)
  ///
  /// Возвращает [ProgressResult] с полем [correct] — правильно ли ответил пользователь.
  /// При ошибке возвращает null.
  static Future<ProgressResult?> submit({
    required String exerciseId,
    required String userAnswer,
  }) async {
    try {
      final res = await _api.post('/progress', data: {
        'exerciseId': exerciseId,
        'userAnswer': userAnswer,
      });
      return ProgressResult.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ProgressService] submit failed: $e');
      return null;
    }
  }

  /// GET /progress — история попыток пользователя (постранично).
  /// При ошибке возвращает пустой список.
  static Future<List<ProgressHistoryItem>> getHistory({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.get(
        '/progress',
        params: {'page': page, 'size': size},
      );
      final data    = res.data as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>? ?? [];
      return content
          .map((e) =>
              ProgressHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProgressService] getHistory failed: $e');
      return [];
    }
  }

  /// GET /progress/summary — агрегированная статистика:
  /// totalAttempted, totalCompleted, totalFailed, totalInProgress.
  /// При ошибке возвращает пустую сводку.
  static Future<ProgressSummary> getSummary() async {
    try {
      final res = await _api.get('/progress/summary');
      return ProgressSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ProgressService] getSummary failed: $e');
      return ProgressSummary.empty();
    }
  }
}
