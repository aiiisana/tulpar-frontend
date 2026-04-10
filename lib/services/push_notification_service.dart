import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../app/api_client.dart';

/// Handles FCM push notifications end-to-end:
///   1. Request iOS permission
///   2. Get FCM token and register it with the backend
///   3. Listen for foreground messages and refresh the token when it rotates
///
/// Call [PushNotificationService.init] once from main() after Firebase.initializeApp().
class PushNotificationService {
  static final _api = ApiClient();
  static final _messaging = FirebaseMessaging.instance;

  /// Call once at app startup (after Firebase.initializeApp()).
  static Future<void> init() async {
    // ── 1. Request permission (required on iOS, no-op on Android) ────────────
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // ask for full permission, not provisional
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[Push] Permission denied by user');
      return;
    }

    debugPrint('[Push] Permission status: ${settings.authorizationStatus}');

    // ── 2. Get current FCM token and register with backend ───────────────────
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[Push] FCM token: ${token.substring(0, 20)}...');
      await _registerToken(token);
    }

    // ── 3. Listen for token refresh (token changes after app restore etc.) ───
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[Push] FCM token refreshed');
      await _registerToken(newToken);
    });

    // ── 4. Foreground message handler ─────────────────────────────────────────
    // By default FCM does NOT show a notification banner when the app is in
    // the foreground.  We can show a local snackbar / in-app banner here.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[Push] Foreground message: ${message.notification?.title}');
      // The NotificationsScreen auto-refreshes on resume, so no extra handling
      // needed for now.  Add a local notification package here if you want
      // in-app banners while the user is actively using the app.
    });

    // ── 5. Notification opened app from background ────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[Push] App opened from notification: ${message.notification?.title}');
      // TODO: navigate to the relevant screen based on message.data
    });
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  static Future<void> _registerToken(String token) async {
    try {
      final platform = defaultTargetPlatform.name.toLowerCase(); // 'ios' | 'android' | 'fuchsia'...
      await _api.post('/devices/token', data: {
        'token': token,
        'platform': platform == 'ios' || platform == 'android' ? platform : 'android',
      });
      debugPrint('[Push] Token registered with backend');
    } catch (e) {
      debugPrint('[Push] Failed to register token: $e');
    }
  }

  /// Call on logout so the user stops receiving push notifications on this device.
  static Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _api.post('/devices/token', data: {'token': token});
      await _messaging.deleteToken();
      debugPrint('[Push] Token removed');
    } catch (e) {
      debugPrint('[Push] Failed to remove token: $e');
    }
  }
}
