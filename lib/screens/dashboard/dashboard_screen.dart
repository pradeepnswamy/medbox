import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/alert_item.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../models/prescription.dart';
import '../../services/data_service.dart';
import '../../services/alert_engine.dart';
import '../../services/notification_service.dart';
import 'components/overview_card.dart';
import 'components/alert_tile.dart';
import 'components/patient_chip.dart';
import 'components/medicine_tile.dart';
import 'components/prescription_tile.dart';
import 'components/quick_action_card.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg           = AppColors.surface;
const _kGreen        = AppColors.primary;
const _kSectionLabel = AppColors.textSecondary;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

  /// Called by [MainShell] whenever the dashboard branch is activated from
  /// a different tab, so the data reloads even though initState() doesn't re-run
  /// (StatefulShellRoute keeps widget state alive across tab switches).
  static VoidCallback? onBranchActivated;
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedPatient = 0;

  // ── Async data — all null until Firestore responds ────────────────────────
  List<MedicineData>?     _medicines;
  List<PatientData>       _patients      = [];
  List<PrescriptionData>? _prescriptions;
  List<AlertItem>?        _alerts;

  // ── Connectivity ──────────────────────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    // ── Wait for Firebase Auth to confirm the user before loading data ────
    // On a fresh app launch Firebase restores the session asynchronously,
    // so currentUser can be null at initState() time even if the user is
    // already signed in.  authStateChanges() fires as soon as the token is
    // ready, guaranteeing _uid is non-null when _reload() runs.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) _reload();
    });

    // Register the tab-reselect callback so MainShell can trigger a reload
    // when the user switches back to the dashboard from another tab.
    DashboardScreen.onBranchActivated = _reload;

    // ── Real-time connectivity monitoring ─────────────────────────────────
    Connectivity().checkConnectivity().then(_handleConnectivity);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_handleConnectivity);

    // Ask for notification permission the first time the dashboard loads.
    // The OS only shows the system dialog once; subsequent calls are silent.
    NotificationService.requestPermissions();
  }

  /// Called whenever connectivity state changes (and once on init).
  void _handleConnectivity(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (!mounted) return;
    final wasOffline = _isOffline;
    setState(() => _isOffline = offline);

    // Auto-reload the moment connection is restored.
    if (wasOffline && !offline) {
      _reload();
    }
  }

  @override
  void dispose() {
    DashboardScreen.onBranchActivated = null;
    _authSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    // AlertEngine.sync is fire-and-forget — its failure must NOT block or abort
    // the data load.  Any Firestore write error inside sync was silently killing
    // the entire _reload(), leaving the dashboard showing zeros.
    unawaited(
      AlertEngine.sync().catchError((e) {
        debugPrint('[Dashboard] AlertEngine.sync error (non-fatal): $e');
      }),
    );

    try {
      // Load all collections in parallel for speed.
      final results = await Future.wait([
        DataService.instance.getMedicines(),
        DataService.instance.getPatients(),
        DataService.instance.getPrescriptions(),
        DataService.instance.getAlerts(),
      ]);

      if (mounted) {
        setState(() {
          _medicines     = results[0] as List<MedicineData>;
          _patients      = results[1] as List<PatientData>;
          _prescriptions = results[2] as List<PrescriptionData>;
          _alerts        = results[3] as List<AlertItem>;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Data load error: $e');
      // Data load failed — keep whatever was already loaded (if anything).
      // The connectivity banner already communicates the offline state.
      if (mounted) {
        setState(() {
          _medicines     ??= [];
          _prescriptions ??= [];
          _alerts        ??= [];
        });
      }
    }
  }

  // ── Derived counts (all live from Firestore data) ─────────────────────────

  int get _totalMedicines   => _medicines?.length ?? 0;
  int get _expiringSoon     => (_medicines ?? [])
      .where((m) => m.topStatus == 'Expiring').length;
  int get _openedTooLong    => (_medicines ?? [])
      .where((m) => m.topStatus == 'Opened').length;
  int get _totalPrescriptions => _prescriptions?.length ?? 0;

  // Active (non-dismissed) alerts, capped at 2 for the dashboard preview
  List<AlertItem> get _activeAlerts =>
      (_alerts ?? []).where((a) => !a.isDismissed).take(2).toList();

  List<MedicineData>     get _recentMedicines     => (_medicines ?? []).take(3).toList();
  List<PrescriptionData> get _recentPrescriptions => (_prescriptions ?? []).take(2).toList();

  /// Quick O(1) lookup: patientId → PatientData.
  Map<String, PatientData> get _patientMap =>
      {for (final p in _patients) p.id: p};

  /// Medicine count per patient, derived from loaded medicines.
  Map<String, int> get _medCountByPatient {
    final counts = <String, int>{};
    for (final m in _medicines ?? []) {
      if (m.patientId != null) {
        counts[m.patientId!] = (counts[m.patientId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _kGreen,
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_isOffline) ...[
                  const SizedBox(height: 16),
                  _buildOfflineBanner(),
                ],
                const SizedBox(height: 24),
                _buildSectionLabel('OVERVIEW'),
                const SizedBox(height: 12),
                _buildOverviewGrid(),
                const SizedBox(height: 24),
                _buildSectionLabel('ACTIVE ALERTS'),
                const SizedBox(height: 12),
                _buildAlerts(),
                const SizedBox(height: 24),
                _buildSectionLabelWithAction(
                  'PATIENTS', 'See all',
                  () => context.go(AppRoutes.patients),
                ),
                const SizedBox(height: 12),
                _buildPatients(),
                const SizedBox(height: 24),
                _buildSectionLabelWithAction(
                  'RECENT MEDICINES', 'See all',
                  () => context.go(AppRoutes.medicines),
                ),
                const SizedBox(height: 12),
                _buildMedicines(),
                const SizedBox(height: 24),
                _buildSectionLabelWithAction(
                  'RECENT PRESCRIPTIONS', 'See all',
                  () => context.go(AppRoutes.prescriptions),
                ),
                const SizedBox(height: 12),
                _buildPrescriptions(),
                const SizedBox(height: 24),
                _buildSectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 12),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline. Data will refresh automatically when reconnected.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user      = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName ?? 'there').split(' ').first;
    final hour      = DateTime.now().hour;
    final greeting  = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    // Clamp title scale so the Row never overflows on large-text settings.
    // Body text elsewhere scales freely; only this branded header is capped.
    final titleScaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);

    final alertLabel = _activeAlerts.isEmpty
        ? 'Alerts, no active alerts'
        : 'Alerts, ${_activeAlerts.length} active alert'
          '${_activeAlerts.length == 1 ? '' : 's'}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flexible so the text column can shrink if the user's font is large.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CarerMeds',
                textScaler: titleScaler,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$greeting, $firstName',
                textScaler: titleScaler,
                style: const TextStyle(fontSize: 13, color: _kSectionLabel),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Notification bell
            Semantics(
              label: alertLabel,
              button: true,
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.alerts),
                child: Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                    if (_activeAlerts.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar → Profile & Settings
            Semantics(
              label: 'Profile and settings',
              button: true,
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.profile),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        (user?.displayName ?? user?.email ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _kSectionLabel,
      ),
    );
  }

  Widget _buildSectionLabelWithAction(
    String label,
    String actionLabel,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel(label),
        Semantics(
          label: '$actionLabel $label',
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                color: _kGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Overview grid — counts derived from Firestore data ────────────────────

  Widget _buildOverviewGrid() {
    return Column(
      children: [
        Row(
          children: [
            OverviewCard(
              title: 'Total medicines',
              value: '$_totalMedicines',
              subtitle: 'across ${_patients.length} patient${_patients.length == 1 ? '' : 's'}',
              backgroundColor: AppColors.statMint,
              textColor: AppColors.statMintText,
              subtitleColor: AppColors.statMintSub,
              onTap: () => context.go(AppRoutes.medicines),
            ),
            const SizedBox(width: 12),
            OverviewCard(
              title: 'Expiring soon',
              value: '$_expiringSoon',
              subtitle: 'within 30 days',
              backgroundColor: AppColors.statPink,
              textColor: AppColors.statPinkText,
              subtitleColor: AppColors.statPinkSub,
              onTap: () => context.go(AppRoutes.alerts),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OverviewCard(
              title: 'Opened 3+ mo',
              value: '$_openedTooLong',
              subtitle: 'review these',
              backgroundColor: AppColors.statAmber,
              textColor: AppColors.statAmberText,
              subtitleColor: AppColors.statAmberSub,
              onTap: () => context.go(AppRoutes.alerts),
            ),
            const SizedBox(width: 12),
            OverviewCard(
              title: 'Prescriptions',
              value: '$_totalPrescriptions',
              subtitle: 'total',
              backgroundColor: AppColors.card,
              textColor: AppColors.textPrimary,
              subtitleColor: AppColors.textSecondary,
              onTap: () => context.go(AppRoutes.prescriptions),
            ),
          ],
        ),
      ],
    );
  }

  // ── Active alerts — live from Firestore ───────────────────────────────────

  Widget _buildAlerts() {
    if (_alerts == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(color: _kGreen),
        ),
      );
    }
    if (_activeAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'No active alerts — all medicines are in good shape!',
                style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _activeAlerts.map((alert) {
        final severity = alert.severity == AlertSeverity.critical
            ? AlertSeverity.critical
            : AlertSeverity.warning;
        final title = alert.type == AlertType.expiring
            ? '${alert.medicineName} expiring'
            : '${alert.medicineName} opened too long';
        final subtitle = alert.description;
        return AlertTile(
          severity: severity,
          title: title,
          subtitle: subtitle,
          onTap: () => context.go(AppRoutes.alerts),
        );
      }).toList(),
    );
  }

  // ── Patients — loaded from Firestore ─────────────────────────────────────

  Widget _buildPatients() {
    // Show spinner until the first reload completes.
    if (_medicines == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: _kGreen),
        ),
      );
    }
    if (_patients.isEmpty) {
      return const Text(
        'No patients yet — add a patient to get started.',
        style: TextStyle(fontSize: 13, color: _kSectionLabel),
      );
    }
    final medCounts = _medCountByPatient;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _patients.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return PatientChip(
            initials:    p.initials,
            name:        p.name,
            medCount:    medCounts[p.id] ?? 0,
            avatarColor: p.avatarColor,
            isSelected:  i == _selectedPatient,
            onTap: () {
              setState(() => _selectedPatient = i);
              context.push(AppRoutes.patientDetail, extra: p);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Recent medicines ───────────────────────────────────────────────────────

  Widget _buildMedicines() {
    if (_medicines == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: _kGreen),
        ),
      );
    }
    if (_recentMedicines.isEmpty) {
      return const Text(
        'No medicines added yet.',
        style: TextStyle(fontSize: 13, color: _kSectionLabel),
      );
    }
    final patMap = _patientMap;
    return Column(
      children: _recentMedicines.map((med) {
        MedicineStatus tileStatus;
        switch (med.topStatus) {
          case 'Expiring':
            tileStatus = MedicineStatus.expiring;
            break;
          case 'Opened':
            tileStatus = MedicineStatus.opened;
            break;
          default:
            tileStatus = MedicineStatus.available;
        }
        return MedicineTile(
          name:         med.name,
          patientName:  med.patientId != null ? patMap[med.patientId]?.name : null,
          acquiredDate: med.acquiredDate,
          status:       tileStatus,
          expiryDate:   'Exp ${med.expiryLabel}',
          onTap: () async {
            await context.push(AppRoutes.medicineDetail, extra: med);
            _reload();
          },
        );
      }).toList(),
    );
  }

  // ── Recent prescriptions ───────────────────────────────────────────────────

  Widget _buildPrescriptions() {
    if (_prescriptions == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: _kGreen),
        ),
      );
    }
    if (_recentPrescriptions.isEmpty) {
      return const Text(
        'No prescriptions added yet.',
        style: TextStyle(fontSize: 13, color: _kSectionLabel),
      );
    }
    return Column(
      children: _recentPrescriptions.map((rx) {
        return PrescriptionTile(
          title:          rx.cause,
          patientInitials: rx.patientInitials,
          patientName:    rx.patientName,
          avatarColor:    rx.patientAvatarColor,
          date:           rx.date,
          medicineCount:  rx.medicines.length,
          onTap: () async {
            await context.push(AppRoutes.prescriptionDetail, extra: rx);
            _reload();
          },
        );
      }).toList(),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuickActionCard(
            icon:     Icons.add_box_rounded,
            iconColor: _kGreen,
            title:    'Add medicine',
            subtitle: 'Log a new one',
            onTap: () async {
              await context.push(AppRoutes.medicinesAdd);
              _reload();
            },
          ),
          const SizedBox(width: 12),
          QuickActionCard(
            icon:     Icons.note_add_rounded,
            iconColor: AppColors.rxBlue,
            title:    'Add prescription',
            subtitle: 'New hospital visit',
            onTap: () async {
              await context.push(AppRoutes.prescriptionsAdd);
              _reload();
            },
          ),
        ],
      ),
    );
  }
}
