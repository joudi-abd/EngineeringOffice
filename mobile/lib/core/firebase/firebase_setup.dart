import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Runs in its own isolate when a push message arrives while the app is closed or in the
/// background. It has to be a top-level function. Firebase has to be started again in that isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Starts Firebase (Analytics, Crashlytics, Cloud Messaging).
///
/// The app must work without it: if Firebase cannot start (no `google-services.json`, a platform
/// that was not set up, no Play services) this logs the reason and the app carries on normally.
class FirebaseSetup {
  const FirebaseSetup._();

  static bool _ready = false;

  /// True once Firebase started. Everything else is skipped when it did not.
  static bool get ready => _ready;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      _ready = true;
    } catch (error) {
      debugPrint('Firebase did not start: $error');
      return;
    }

    // Debug runs stay out of the real reports and statistics.
    const collect = kReleaseMode;
    await _guard('crashlytics', () async {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        collect,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    });
    await _guard('analytics', () async {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(collect);
    });
    await _guard('messaging', () async {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      // The system dialog (Android 13+) must not hold up the start of the app, so it is not awaited.
      unawaited(
        FirebaseMessaging.instance.requestPermission().then(
          (_) {},
          onError: (Object e) => debugPrint('Notification permission: $e'),
        ),
      );
    });
  }

  static Future<void> _guard(String name, Future<void> Function() run) async {
    try {
      await run();
    } catch (error) {
      debugPrint('Firebase $name could not start: $error');
    }
  }
}
