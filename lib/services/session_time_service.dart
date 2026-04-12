import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

/// Tracks how long the user spends in the app each day.
///
/// Usage:
///   - Call [startSession] when the app comes to the foreground (or on launch).
///   - Call [flushSession] when the app goes to the background/is paused.
///   - Call [getTodayTime] to get the current day's stats from the backend.
class SessionTimeService {
  static final _api = ApiClient();

  /// Timestamp of when the current session started (null if not tracking).
  static DateTime? _sessionStart;

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Mark the start of an active session.
  static void startSession() {
    _sessionStart = DateTime.now();
    debugPrint('[SessionTime] Session started at $_sessionStart');
  }

  /// Calculate elapsed seconds since [startSession] was called, send them to
  /// the backend, and reset the internal timer.
  ///
  /// Safe to call even if [startSession] was never called (no-op).
  static Future<void> flushSession() async {
    final start = _sessionStart;
    if (start == null) return;

    _sessionStart = null; // reset immediately to avoid double-counting

    final elapsed = DateTime.now().difference(start).inSeconds;
    if (elapsed < 1) return;

    debugPrint('[SessionTime] Flushing $elapsed seconds');
    try {
      await _api.post('/sessions/time', data: {'seconds': elapsed});
    } catch (e) {
      debugPrint('[SessionTime] flush failed: $e');
      // Not critical — the user's time was already recorded locally via the
      // start timestamp; the next flush will catch subsequent activity.
    }
  }

  // ── Query ──────────────────────────────────────────────────────────────────

  /// Fetch today's accumulated session time and daily goal from the backend.
  ///
  /// Returns a [SessionTimeModel] or null on error.
  static Future<SessionTimeModel?> getTodayTime() async {
    try {
      final res = await _api.get('/sessions/time/today');
      return SessionTimeModel.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SessionTime] getTodayTime failed: $e');
      return null;
    }
  }
}

// ── Model ──────────────────────────────────────────────────────────────────

class SessionTimeModel {
  final int totalSeconds;
  final int goalSeconds;
  final bool goalMet;

  const SessionTimeModel({
    required this.totalSeconds,
    required this.goalSeconds,
    required this.goalMet,
  });

  factory SessionTimeModel.fromJson(Map<String, dynamic> j) => SessionTimeModel(
        totalSeconds: (j['totalSeconds'] as num?)?.toInt() ?? 0,
        goalSeconds:  (j['goalSeconds']  as num?)?.toInt() ?? 0,
        goalMet:      j['goalMet']  as bool? ?? false,
      );

  /// Human-readable "Xч Yмин" or "Yмин" string.
  String get formattedTotal {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}мин';
    if (m > 0) return '${m} мин';
    return '< 1 мин';
  }

  static const empty = SessionTimeModel(
    totalSeconds: 0,
    goalSeconds: 0,
    goalMet: false,
  );
}
