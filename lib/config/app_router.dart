import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../screens/medicines/medicines_list_screen.dart';
import '../screens/medicines/medicine_detail_screen.dart';
import '../screens/medicines/add_medicine_screen.dart';
import '../screens/prescriptions/prescriptions_list_screen.dart';
import '../screens/prescriptions/prescription_detail_screen.dart';
import '../screens/prescriptions/add_prescription_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/alerts/alert_settings_screen.dart';
import '../screens/patients/patient_list_screen.dart';
import '../screens/patients/patient_detail_screen.dart';
import '../screens/patients/patient_form_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/main_shell.dart';

// ── Route path constants ──────────────────────────────────────────────────────

abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login   = '/login';
  static const String signup  = '/signup';

  // ── Shell / tab routes (bottom nav visible) ───────────────────────────────
  static const String home              = '/';
  static const String medicines         = '/medicines';
  static const String patients          = '/patients';
  static const String prescriptions     = '/prescriptions';
  static const String alerts            = '/alerts';

  // ── Detail / modal routes (no bottom nav) ─────────────────────────────────
  static const String medicinesAdd       = '/medicines/add';
  static const String medicineDetail     = '/medicines/detail';
  static const String prescriptionDetail = '/prescriptions/detail';
  static const String prescriptionsAdd   = '/prescriptions/add';
  static const String alertSettings      = '/alerts/settings';
  static const String patientDetail      = '/patients/detail';
  static const String patientsAdd        = '/patients/add';
  static const String profile            = '/profile';
  static const String splash             = '/splash';
}

// ── Auth-state listenable ─────────────────────────────────────────────────────
//
// go_router re-evaluates the redirect whenever this notifier fires.

class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthRefreshNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefreshNotifier = _AuthRefreshNotifier();

// ── Router instance ───────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation:     AppRoutes.splash,
  debugLogDiagnostics: false,
  refreshListenable:   _authRefreshNotifier,

  // ── Auth guard ────────────────────────────────────────────────────────────
  redirect: (context, state) {
    final isSignedIn  = FirebaseAuth.instance.currentUser != null;
    final loc         = state.matchedLocation;
    final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;
    final isSplash    = loc == AppRoutes.splash;

    if (!isSignedIn && !isAuthRoute && !isSplash) return AppRoutes.login;
    if (isSignedIn  && isAuthRoute)               return AppRoutes.home;
    return null;
  },

  routes: [

    // ── Auth screens ──────────────────────────────────────────────────────────
    GoRoute(
      path:    AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path:    AppRoutes.signup,
      builder: (_, __) => const SignupScreen(),
    ),

    // ── Splash ────────────────────────────────────────────────────────────────
    GoRoute(
      path:    AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),

    // ── Shell with persistent bottom nav ──────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, __) => const NoTransitionPage(child: DashboardScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.medicines,
            pageBuilder: (_, __) => const NoTransitionPage(child: MedicinesListScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.patients,
            pageBuilder: (_, __) => const NoTransitionPage(child: PatientListScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.prescriptions,
            pageBuilder: (_, __) => const NoTransitionPage(child: PrescriptionsListScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.alerts,
            pageBuilder: (_, __) => const NoTransitionPage(child: AlertsScreen()),
          ),
        ]),
      ],
    ),

    // ── Detail / modal routes ─────────────────────────────────────────────────

    // Add / edit medicine.
    //   extra: MedicineData → edit mode
    //   extra: MedicineData → edit mode
    //   extra: String       → add mode with pre-selected patient id
    //   extra: null         → new, blank
    GoRoute(
      path: AppRoutes.medicinesAdd,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is MedicineData) {
          return AddMedicineScreen(existing: extra);
        }
        if (extra is String) {
          return AddMedicineScreen(initialPatientId: extra);
        }
        return const AddMedicineScreen();
      },
    ),

    GoRoute(
      path: AppRoutes.medicineDetail,
      builder: (context, state) =>
          MedicineDetailScreen(medicine: state.extra as MedicineData),
    ),

    GoRoute(
      path: AppRoutes.patientDetail,
      builder: (context, state) =>
          PatientDetailScreen(patient: state.extra as PatientData),
    ),

    GoRoute(
      path:    AppRoutes.patientsAdd,
      builder: (_, __) => const PatientFormScreen(),
    ),

    GoRoute(
      path: AppRoutes.prescriptionDetail,
      builder: (context, state) =>
          PrescriptionDetailScreen(prescription: state.extra as PrescriptionData),
    ),

    GoRoute(
      path: AppRoutes.prescriptionsAdd,
      builder: (context, state) =>
          AddPrescriptionScreen(existing: state.extra as PrescriptionData?),
    ),

    GoRoute(
      path:    AppRoutes.alertSettings,
      builder: (_, __) => const AlertSettingsScreen(),
    ),

    GoRoute(
      path:    AppRoutes.profile,
      builder: (_, __) => const ProfileScreen(),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    backgroundColor: AppColors.surface,
    body: Center(
      child: Text(
        'Page not found\n${state.uri}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ),
  ),
);
