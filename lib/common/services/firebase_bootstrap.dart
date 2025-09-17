import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Initializes Firebase and related services in a guarded way.
/// If platform configuration is missing, it fails silently to keep the app usable offline.
Future<void> initFirebaseBootstrap(ProviderContainer container) async {
  try {
    // Initialize Firebase app if not already
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Enable App Check (mobile only)
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      }
    } catch (_) {}

    // Remote Config with sensible defaults
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(<String, Object?>{
        'earn_rate': 1, // points per currency unit
        'maintenance': false,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.fetchAndActivate();
    } catch (_) {}

    // Messaging permissions (iOS/Android) and foreground presentation
    try {
      final fm = FirebaseMessaging.instance;
      await fm.setAutoInitEnabled(true);
      await fm.requestPermission(alert: true, badge: true, sound: true);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (_) {}
  } catch (_) {
    // If Firebase core init fails (e.g., not configured), skip silently for MVP
  }
}

/// Background message handler must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}
