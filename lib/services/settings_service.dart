import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppSettings {
  final String supportEmail;
  final String termsUrl;
  final String privacyPolicyUrl;
  final String appVersion;

  AppSettings({
    required this.supportEmail,
    required this.termsUrl,
    required this.privacyPolicyUrl,
    required this.appVersion,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        supportEmail:     j['supportEmail'] as String? ?? 'support@tulpar.kz',
        termsUrl:         j['termsUrl'] as String? ?? '',
        privacyPolicyUrl: j['privacyPolicyUrl'] as String? ?? '',
        appVersion:       j['appVersion'] as String? ?? '1.0.0',
      );

  /// Значения по умолчанию — используются при ошибке сети
  factory AppSettings.defaults() => AppSettings(
        supportEmail: 'support@tulpar.kz',
        termsUrl: 'https://tulpar.kz/terms',
        privacyPolicyUrl: 'https://tulpar.kz/privacy',
        appVersion: '1.0.0',
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class SettingsService {
  static final _api = ApiClient();

  /// GET /settings — возвращает статичные настройки приложения.
  /// При ошибке возвращает значения по умолчанию.
  static Future<AppSettings> getSettings() async {
    try {
      final res = await _api.get('/settings');
      return AppSettings.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SettingsService] getSettings failed: $e');
      return AppSettings.defaults();
    }
  }
}
