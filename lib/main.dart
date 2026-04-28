import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  runApp(
    const ProviderScope(
      child: MedBoxApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();

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
      debugPrint('[MedBox] Cleared legacy anonymous session');
    }
  } catch (e) {
    debugPrint('[MedBox] Firebase init error: $e');
  }
}
