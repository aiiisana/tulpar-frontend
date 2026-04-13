import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'services/push_notification_service.dart';

/// Background message handler — must be a top-level function (not inside a class).
/// Called when a data-only FCM message arrives while the app is terminated or
/// in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request iOS permission + register FCM token with backend.
  // Intentionally unawaited — token registration happens after login.
  PushNotificationService.init();

  runApp(const TulparApp());
}
