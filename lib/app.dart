import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';

/// Root widget of the MedBox application.
///
/// Wrapped by [ProviderScope] in [main.dart].
/// Owns the [GoRouter] instance and applies the global [AppTheme].
class MedBoxApp extends ConsumerWidget {
  const MedBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // ── Identity ──────────────────────────────────────────────────────────
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────────────────────
      theme:      AppTheme.light,
      themeMode:  ThemeMode.light,

      // ── Routing ───────────────────────────────────────────────────────────
      routerConfig: appRouter,
    );
  }
}
