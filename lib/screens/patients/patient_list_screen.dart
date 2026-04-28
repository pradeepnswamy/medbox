import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../../widgets/offline_retry_widget.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kGreen = AppColors.primary;
const _kLabel = AppColors.textSecondary;

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  // Null while loading; populated from both Firestore patients + medicine data.
  List<PatientData>? _patients;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() { _error = null; _patients = null; });
    try {
      // Fire both requests in parallel with explicit typed futures to avoid
      // Future.wait collapsing the return type to List<Object>.
      final storedFuture    = DataService.instance.getPatients();
      final medicinesFuture = DataService.instance.getMedicines();

      final stored    = await storedFuture;
      final medicines = await medicinesFuture;

      if (mounted) {
        setState(() {
          _patients = PatientData.merge(
            stored:    stored,
            medicines: medicines,
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _patients = [];
        _error = 'Could not load patients. Check your connection and retry.';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtered list ─────────────────────────────────────────────────────────

  List<PatientData> get _filtered {
    final all = _patients ?? [];
    final q   = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),

      // FAB → Add Patient screen
      floatingActionButton: FloatingActionButton(
        heroTag: 'patients-fab',
        onPressed: () async {
          final saved = await context.push<bool>(AppRoutes.patientsAdd);
          if (saved == true) _reload();
        },
        backgroundColor: _kGreen,
        shape: const CircleBorder(),
        tooltip: 'Add patient',
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        'Patients',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: _kLabel, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search patients...',
                hintStyle: TextStyle(color: _kLabel, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_error != null) {
      return OfflineRetryWidget(onRetry: _reload, message: _error);
    }
    if (_patients == null) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }

    final patients = _filtered;
    if (patients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        color: _kGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_buildEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: _kGreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: patients.length + 1, // +1 for the count header
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${patients.length} PATIENT${patients.length == 1 ? '' : 'S'}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _kLabel,
                ),
              ),
            );
          }
          return _buildPatientCard(patients[i - 1]);
        },
      ),
    );
  }

  // ── Patient card ──────────────────────────────────────────────────────────

  Widget _buildPatientCard(PatientData patient) {
    return GestureDetector(
      onTap: () async {
        await context.push(AppRoutes.patientDetail, extra: patient);
        _reload();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: patient.hasAlerts
                ? (patient.expiringCount > 0
                    ? AppColors.dangerBorder
                    : AppColors.warningBorder)
                : AppColors.border,
            width: patient.hasAlerts ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: patient.avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + meta + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (patient.relationship.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            patient.relationship,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    patient.medicineCount == 0
                        ? 'No medicines yet'
                        : '${patient.medicineCount} medicine${patient.medicineCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13, color: _kLabel),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(patient),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: _kLabel, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(PatientData patient) {
    if (patient.medicineCount == 0) {
      return Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: _kLabel, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Add a medicine to get started',
            style: TextStyle(fontSize: 12, color: _kLabel),
          ),
        ],
      );
    }
    if (!patient.hasAlerts) {
      return Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'All medicines OK',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 6, runSpacing: 4,
      children: [
        if (patient.expiringCount > 0)
          _statusChip('${patient.expiringCount} expiring',
              AppColors.dangerLight, AppColors.danger),
        if (patient.openedCount > 0)
          _statusChip('${patient.openedCount} opened',
              AppColors.warningLight, AppColors.warning),
      ],
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isSearch = _searchCtrl.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No patients found' : 'No patients yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search'
                  : 'Tap + to add your first patient.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kLabel),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  final saved =
                      await context.push<bool>(AppRoutes.patientsAdd);
                  if (saved == true) _reload();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Add first patient',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
