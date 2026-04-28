import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/alert_item.dart';
import '../../services/data_service.dart';
import '../../widgets/offline_retry_widget.dart';
import 'components/alert_card.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kGreen = AppColors.primary;
const _kRed   = AppColors.danger;
const _kAmber = AppColors.warning;
const _kGrey  = AppColors.textSecondary;

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _activeTab = 0; // 0 = Expiring, 1 = Opened, 2 = Dismissed

  // Local mutable copy so dismiss/undo work within this session.
  // Null while still loading from DataService.
  List<AlertItem>? _alerts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() { _error = null; _alerts = null; });
    try {
      final list = await DataService.instance.getAlerts();
      if (mounted) {
        setState(() {
          // Create a mutable copy — the cached list is treated as read-only.
          _alerts = list
              .map((a) => AlertItem(
                    id: a.id,
                    medicineName: a.medicineName,
                    daysValue: a.daysValue,
                    daysLabel: a.daysLabel,
                    description: a.description,
                    patientName: a.patientName,
                    patientInitials: a.patientInitials,
                    patientAvatarColor: a.patientAvatarColor,
                    type: a.type,
                    severity: a.severity,
                  ))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _alerts = [];
        _error = 'Could not load alerts. Check your connection and retry.';
      });
    }
  }

  // ── Filtered lists ────────────────────────────────────────────────────────────

  List<AlertItem> get _activeAlerts =>
      (_alerts ?? []).where((a) => !a.isDismissed).toList();

  List<AlertItem> get _expiringAlerts =>
      _activeAlerts.where((a) => a.type == AlertType.expiring).toList();

  List<AlertItem> get _criticalAlerts =>
      _expiringAlerts
          .where((a) => a.severity == AlertSeverity.critical)
          .toList();

  List<AlertItem> get _warningAlerts =>
      _expiringAlerts
          .where((a) => a.severity == AlertSeverity.warning)
          .toList();

  List<AlertItem> get _openedAlerts =>
      _activeAlerts.where((a) => a.type == AlertType.opened).toList();

  List<AlertItem> get _dismissedAlerts =>
      (_alerts ?? []).where((a) => a.isDismissed).toList();

  void _dismiss(AlertItem item) =>
      setState(() => item.isDismissed = true);

  void _undo(AlertItem item) =>
      setState(() => item.isDismissed = false);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: _error != null
                  ? OfflineRetryWidget(onRetry: _reload, message: _error)
                  : _alerts == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : RefreshIndicator(
                          onRefresh: _reload,
                          color: AppColors.primary,
                          child: _buildTabContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Alerts',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        // "3 active" pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kRed.withOpacity(0.4)),
          ),
          child: Text(
            '${_activeAlerts.length} active',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kRed,
            ),
          ),
        ),
        const Spacer(),
        // Settings gear
        GestureDetector(
          onTap: () => context.push(AppRoutes.alertSettings),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('Expiring (${_expiringAlerts.length})', _kRed),
      ('Opened (${_openedAlerts.length})', _kAmber),
      ('Dismissed', _kGrey),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == _activeTab;
          final color = tabs[i].$2;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : AppColors.border,
                ),
              ),
              child: Text(
                tabs[i].$1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildExpiringTab();
      case 1:
        return _buildOpenedTab();
      case 2:
        return _buildDismissedTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Expiring tab ─────────────────────────────────────────────────────────────

  Widget _buildExpiringTab() {
    if (_expiringAlerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            iconColor: _kGreen,
            title: 'No expiring alerts',
            subtitle: 'All your medicines are within their expiry window',
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_criticalAlerts.isNotEmpty) ...[
            _sectionLabel('CRITICAL — EXPIRES WITHIN 7 DAYS', _kRed),
            const SizedBox(height: 10),
            ..._criticalAlerts.map((a) => AlertCard(
                  alert: a,
                  onDismiss: () => _dismiss(a),
                  onUndo: () => _undo(a),
                  onViewMedicine: () => _showViewMedicineSnack(context),
                )),
            const SizedBox(height: 16),
          ],
          if (_warningAlerts.isNotEmpty) ...[
            _sectionLabel('EXPIRING WITHIN 30 DAYS', _kAmber),
            const SizedBox(height: 10),
            ..._warningAlerts.map((a) => AlertCard(
                  alert: a,
                  onDismiss: () => _dismiss(a),
                  onUndo: () => _undo(a),
                  onViewMedicine: () => _showViewMedicineSnack(context),
                )),
          ],
        ],
      ),
    );
  }

  // ── Opened tab ────────────────────────────────────────────────────────────────

  Widget _buildOpenedTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_openedAlerts.isNotEmpty) ...[
            _sectionLabel('OPENED MORE THAN 3 MONTHS AGO', _kAmber),
            const SizedBox(height: 10),
            ..._openedAlerts.map((a) => AlertCard(
                  alert: a,
                  onDismiss: () => _dismiss(a),
                  onUndo: () => _undo(a),
                  onViewMedicine: () => _showViewMedicineSnack(context),
                )),
            const SizedBox(height: 24),
          ],
          // Empty state below the list (or as full-page if list is empty)
          _buildOpenedEmptyState(),
        ],
      ),
    );
  }

  Widget _buildOpenedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: AppColors.textSecondary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No more opened alerts',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All other opened medicines are within\nthe 3-month window',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dismissed tab ─────────────────────────────────────────────────────────────

  Widget _buildDismissedTab() {
    if (_dismissedAlerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildEmptyState(
            icon: Icons.notifications_off_outlined,
            iconColor: _kGrey,
            title: 'No dismissed alerts',
            subtitle: 'Alerts you dismiss will appear here so you can undo them',
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('DISMISSED', _kGrey),
          const SizedBox(height: 10),
          ..._dismissedAlerts.map((a) => AlertCard(
                alert: a,
                onDismiss: () => _dismiss(a),
                onUndo: () => _undo(a),
                onViewMedicine: null,
              )),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kGrey),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewMedicineSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening medicine detail…')),
    );
  }
}
