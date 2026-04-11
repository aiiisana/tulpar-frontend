import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

// ── Модель ────────────────────────────────────────────────────────────────────

class ProfileModel {
  final String id;
  final String email;
  final String? username;   // единое поле имени на бэкенде
  final String? avatarUrl;
  final String? level;      // DifficultyLevel: BEGINNER / ELEMENTARY / INTERMEDIATE / ADVANCED
  final String? dailyGoal;  // DailyGoal: CASUAL / REGULAR / SERIOUS / INTENSE
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final bool notificationsEnabled;
  final bool onboardingCompleted;

  ProfileModel({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.level,
    this.dailyGoal,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.notificationsEnabled,
    required this.onboardingCompleted,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id:                   j['id'] as String? ?? '',
        email:                j['email'] as String? ?? '',
        username:             j['username'] as String?,
        avatarUrl:            j['avatarUrl'] as String?,
        level:                j['level'] as String?,
        dailyGoal:            j['dailyGoal'] as String?,
        currentStreak:        (j['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak:        (j['longestStreak'] as num?)?.toInt() ?? 0,
        totalXp:              (j['totalXp'] as num?)?.toInt() ?? 0,
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? false,
        onboardingCompleted:  j['onboardingCompleted'] as bool? ?? false,
      );

  // ── Преобразования enum → UI ───────────────────────────────────────────────

  /// DifficultyLevel → строка на русском
  String get levelRu => switch (level) {
        'BEGINNER'     => 'Начинающий',
        'ELEMENTARY'   => 'Элементарный',
        'INTERMEDIATE' => 'Средний',
        'ADVANCED'     => 'Продвинутый',
        _              => 'Начинающий',
      };

  /// DailyGoal → минуты (для отображения в UI)
  int get goalMinutes => switch (dailyGoal) {
        'CASUAL'  => 15,
        'REGULAR' => 30,
        'SERIOUS' => 45,
        'INTENSE' => 60,
        _         => 15,
      };
}

// ── Сервис ────────────────────────────────────────────────────────────────────

class ProfileService {
  static final _api = ApiClient();

  /// GET /profile — возвращает null при ошибке сети
  static Future<ProfileModel?> getProfile() async {
    try {
      final res = await _api.get('/profile');
      return ProfileModel.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Profile] getProfile failed: $e');
      return null;
    }
  }

  /// PUT /profile — обновляет username (и опционально avatarUrl).
  /// Бэкенд принимает: { username, avatarUrl, notificationsEnabled }
  /// Возвращает обновлённый профиль или null при ошибке.
  static Future<ProfileModel?> updateUsername(String username) async {
    try {
      final res = await _api.put('/profile', data: {'username': username});
      return ProfileModel.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Profile] updateUsername failed: $e');
      return null;
    }
  }

  /// POST /onboarding/level — меняет уровень сложности.
  /// [level] — одно из: BEGINNER, ELEMENTARY, INTERMEDIATE, ADVANCED.
  /// Идемпотентен: вызывать можно повторно (OnboardingService.setLevel просто
  /// перезаписывает user.level в БД).
  static Future<void> updateLevel(String level) async {
    try {
      await _api.post('/onboarding/level', data: {'level': level});
    } catch (e) {
      debugPrint('[Profile] updateLevel failed: $e');
      rethrow; // пробрасываем, чтобы UI мог показать snackbar об ошибке
    }
  }

  /// POST /onboarding/goal — меняет ежедневную цель.
  /// Бэкенд не предоставляет PUT /profile для dailyGoal,
  /// поэтому используем /onboarding/goal (идемпотентен, вызывать можно повторно).
  static Future<void> updateDailyGoal(int minutes) async {
    try {
      await _api.post('/onboarding/goal', data: {
        'dailyGoal': _minutesToEnum(minutes),
      });
    } catch (e) {
      debugPrint('[Profile] updateDailyGoal failed: $e');
    }
  }

  /// PUT /profile — обновляет флаг уведомлений.
  /// Вызывается из NotificationsScreen при переключении тоггла.
  static Future<void> updateNotificationsEnabled(bool enabled) async {
    try {
      await _api.put('/profile', data: {'notificationsEnabled': enabled});
    } catch (e) {
      debugPrint('[Profile] updateNotificationsEnabled failed: $e');
    }
  }

  static String _minutesToEnum(int minutes) => switch (minutes) {
        <= 15 => 'CASUAL',
        <= 30 => 'REGULAR',
        <= 45 => 'SERIOUS',
        _     => 'INTENSE',
      };
}
