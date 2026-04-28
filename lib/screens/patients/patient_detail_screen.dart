import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../dashboard/components/medicine_tile.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;

class PatientDetailScreen extends StatefulWidget {
  final PatientData patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  // Keep a live copy so add/edit/delete reflects immediately.
  late PatientData _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  Future<void> _reload() async {
    // Re-merge stored patients + medicines to get fresh medicine list.
    final storedFuture    = DataService.instance.getPatients();
    final medicinesFuture = DataService.instance.getMedicines();
    final stored    = await storedFuture;
    final medicines = await medicinesFuture;

    if (!mounted) return;

    final merged = PatientData.merge(stored: stored, medicines: medicines);
    final updated = merged.firstWhere(
      (p) => p.name == _patient.name,
      orElse: () => _patient,
    );
    setState(() => _patient = updated);
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete patient?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This removes ${_patient.name} from your patient list. Their medicines will not be deleted.',
          style: const TextStyle(fontSize: 14, color: _kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _kGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (_patient.id.isNotEmpty) {
      await DataService.instance.deletePatient(_patient.id);
    }

    if (mounted) context.pop(true); // signal caller to reload
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
            Expanded(
              child: RefreshIndicator(
                color: _kGreen,
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildStatusRow(),
                      const SizedBox(height: 28),
                      _buildMedicinesSection(),
                      if (_patient.isExplicit) ...[
                        const SizedBox(height: 40),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chevron_left_rounded, color: _kGreen, size: 24),
                Text(
                  'Patients',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Patient',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Mirror space for centering the title
          const SizedBox(width: 72),
        ],
      ),
    );
  }

  // ── Hero — avatar + name + relationship ───────────────────────────────────

  Widget _buildHero() {
    return Center(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _patient.avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _patient.avatarColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _patient.initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            _patient.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          // Relationship badge
          if (_patient.relationship.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _patient.relationship,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Status row ────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    if (_patient.medicineCount == 0) {
      return _buildInfoBanner(
        icon: Icons.medication_outlined,
        iconColor: _kGrey,
        text: 'No medicines linked yet.',
        bgColor: _kCard,
      );
    }

    if (!_patient.hasAlerts) {
      return _buildInfoBanner(
        icon: Icons.check_circle_rounded,
        iconColor: _kGreen,
        text: 'All medicines are in good shape.',
        bgColor: AppColors.primaryLight,
        textColor: AppColors.primaryDark,
      );
    }

    return Row(
      children: [
        if (_patient.expiringCount > 0)
          Expanded(
            child: _buildStatChip(
              label: 'Expiring soon',
              value: '${_patient.expiringCount}',
              bg:    AppColors.dangerLight,
              fg:    AppColors.danger,
            ),
          ),
        if (_patient.expiringCount > 0 && _patient.openedCount > 0)
          const SizedBox(width: 12),
        if (_patient.openedCount > 0)
          Expanded(
            child: _buildStatChip(
              label: 'Opened 3+ mo',
              value: '${_patient.openedCount}',
              bg:    AppColors.warningLight,
              fg:    AppColors.warning,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bgColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor ?? _kGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: fg.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // ── Medicines section ─────────────────────────────────────────────────────

  Widget _buildMedicinesSection() {
    return Column(
      children: [
        // Section header with Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEDICINES (${_patient.medicineCount})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _kGrey,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await context.push(
                  AppRoutes.medicinesAdd,
                  extra: {'patient': _patient.name},
                );
                _reload();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: _kGreen, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add medicine',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Medicine tiles
        if (_patient.medicines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: _kGreen, size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No medicines yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap "Add medicine" above to log one.',
                    style: TextStyle(fontSize: 13, color: _kGrey),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _patient.medicines.map((med) {
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
                patient:      med.patient,
                acquiredDate: med.acquiredDate,
                status:       tileStatus,
                expiryDate:   'Exp ${med.expiryLabel}',
                onTap: () async {
                  await context.push(AppRoutes.medicineDetail, extra: med);
                  _reload();
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Delete button ─────────────────────────────────────────────────────────

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: const Center(
          child: Text(
            'Delete patient',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
