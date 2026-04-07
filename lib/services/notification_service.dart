import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool read;
  final String createdAt; // ISO-8601

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id:        j['id'] as String? ?? '',
        title:     j['title'] as String? ?? '',
        body:      j['body'] as String? ?? '',
        read:      j['read'] as bool? ?? false,
        createdAt: j['createdAt'] as String? ?? '',
      );

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id:        id,
        title:     title,
        body:      body,
        read:      read ?? this.read,
        createdAt: createdAt,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  static final _api = ApiClient();

  /// GET /notifications — возвращает постраничный список уведомлений.
  /// Бэкенд отдаёт PageResponse<NotificationResponse>.
  /// При ошибке возвращает пустой список.
  static Future<List<NotificationModel>> getList({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.get(
        '/notifications',
        params: {'page': page, 'size': size},
      );
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>? ?? [];
      return content
          .map((e) =>
              NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationService] getList failed: $e');
      return [];
    }
  }

  /// PATCH /notifications/{id}/read — помечает уведомление как прочитанное.
  /// Возвращает обновлённую модель или null при ошибке.
  static Future<NotificationModel?> markRead(String id) async {
    try {
      final res = await _api.patch('/notifications/$id/read');
      return NotificationModel.fromJson(
          res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NotificationService] markRead failed: $e');
      return null;
    }
  }

  /// Удобный метод: подсчитывает кол-во непрочитанных.
  static Future<int> unreadCount() async {
    final list = await getList(size: 50);
    return list.where((n) => !n.read).length;
  }
}
