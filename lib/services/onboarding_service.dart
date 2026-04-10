import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../app/api_client.dart';
import '../app/app_storage.dart';

/// Отправляет данные онбординга на бэкенд после успешной Firebase-регистрации.
///
/// Вызывать ТОЛЬКО в SignupScreen, после того как Firebase-токен уже есть.
/// ApiClient автоматически добавит Bearer токен в заголовки.
///
/// Маппинги:
///   Уровень (строка из UI) → DifficultyLevel (enum бэкенда)
///   Минуты (int из UI)     → DailyGoal (enum бэкенда)
///
/// Бэкенд DailyGoal:
///   CASUAL  — 5 мин   → используем для 15 и ниже
///   REGULAR — 10 мин  → используем для 30
///   SERIOUS — 20 мин  → используем для 45
///   INTENSE — 30+ мин → используем для 60, 90, 120
class OnboardingService {
  static final _api = ApiClient();

  /// Читает сохранённые данные из AppStorage и отправляет их на бэкенд.
  /// Если уровень или цель не выбраны — пропускает соответствующий запрос.
  /// Ошибки не пробрасываются: онбординг не должен блокировать вход.
  static Future<void> sendIfNeeded() async {
    try {
      final level = await AppStorage.getLevel();
      final goalMinutes = await AppStorage.getGoalMinutes();

      // POST /onboarding/level
      if (level != null) {
        await _api.post('/onboarding/level', data: {
          'level': _levelToApi(level),
        });
        debugPrint('[Onboarding] level sent: ${_levelToApi(level)}');
      }

      // POST /onboarding/goal
      if (goalMinutes != null) {
        await _api.post('/onboarding/goal', data: {
          'dailyGoal': _goalToApi(goalMinutes),
        });
        debugPrint('[Onboarding] goal sent: ${_goalToApi(goalMinutes)}');
      }

      // POST /onboarding/complete — бэкенд ставит onboardingCompleted = true
      await _api.post('/onboarding/complete');
      debugPrint('[Onboarding] complete');
    } on DioException catch (e) {
      // Логируем, но не бросаем — пользователь всё равно проходит дальше.
      // При следующем входе данные уже будут на бэкенде.
      debugPrint('[Onboarding] sync failed: ${e.message}');
    } catch (e) {
      debugPrint('[Onboarding] unexpected error: $e');
    }
  }

  // ── Маппинги ────────────────────────────────────────────────────────────────

  /// Русские строки UI → DifficultyLevel enum бэкенда
  static String _levelToApi(String uiLevel) => switch (uiLevel) {
        'Начинающий'    => 'BEGINNER',
        'Элементарный'  => 'ELEMENTARY',
        'Средний'       => 'INTERMEDIATE',
        'Продвинутый'   => 'ADVANCED',
        _               => 'BEGINNER', // fallback
      };

  /// Минуты из UI → DailyGoal enum бэкенда
  ///
  /// Бэкенд: CASUAL(5м) REGULAR(10м) SERIOUS(20м) INTENSE(30м+)
  /// Фронт:  15, 30, 45, 60, 90, 120 мин
  static String _goalToApi(int minutes) {
    if (minutes <= 0)  return 'CASUAL';   // "Other" или неопределено
    if (minutes <= 15) return 'CASUAL';
    if (minutes <= 30) return 'REGULAR';
    if (minutes <= 45) return 'SERIOUS';
    return 'INTENSE';                      // 60, 90, 120
  }
}
