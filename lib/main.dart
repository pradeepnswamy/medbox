import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/notification_service.dart';

/// App entry point.
///
/// Responsibilities:
///  1. Ensure Flutter bindings are ready.
///  2. Initialise Firebase.
///  3. Enable Firestore offline persistence so the app works without internet.
///  4. Wrap the app in [ProviderScope] so every widget has access
///     to Riverpod providers.
///
/// Authentication is handled by [AuthService] + Firebase Auth.
/// The router's redirect guard in [app_router.dart] sends unauthenticated
/// users to the login screen automatically — no manual navigation needed here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();

  // Initialise local notifications before runApp so the plugin is ready when
  // AlertEngine.sync() fires shortly after the first authenticated screen loads.
  await NotificationService.init();

  // ── Crashlytics error hooks ──────────────────────────────────────────────
  // 1. Flutter framework errors (widget build failures, etc.)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // 2. Uncaught async / platform errors (Futures, Streams, isolate errors).
  //    PlatformDispatcher covers everything runZonedGuarded used to handle,
  //    and avoids the zone-mismatch assertion that occurs when ensureInitialized()
  //    and runApp() are called in different zones.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    const ProviderScope(
      child: CarerMedsApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();

    // Disable Crashlytics in debug builds — only report real crashes.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Enable offline persistence — the app stays usable without internet.
    // Any writes are queued locally and synced when connectivity returns.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled:  true,
      cacheSizeBytes:      Settings.CACHE_SIZE_UNLIMITED,
    );

    // Sign out any leftover anonymous session from before email auth was added.
    // Anonymous UIDs are not linked to a real account, so if we find one we
    // clear it so the router correctly sends the user to the login screen.
    // Real email/password users are unaffected — their isAnonymous is false.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null && current.isAnonymous) {
      await FirebaseAuth.instance.signOut();
      debugPrint('[CarerMeds] Cleared legacy anonymous session');
    }
  } catch (e) {
    debugPrint('[CarerMeds] Firebase init error: $e');
  }
}
