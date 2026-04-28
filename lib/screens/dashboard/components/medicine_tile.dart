import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// Status badge type for a medicine entry.
enum MedicineStatus { available, opened, expiring }

/// A dark card showing one medicine: lock icon, name, patient, acquisition date,
/// a coloured status badge, and expiry date.
///
/// Usage:
///   MedicineTile(
///     name: 'Paracetamol 500mg',
///     patient: 'Ravi Kumar',
///     acquiredDate: 'Got Apr 12',
///     status: MedicineStatus.available,
///     expiryDate: 'Exp Jun 26',
///   )
class MedicineTile extends StatelessWidget {
  final String name;
  final String patient;
  final String acquiredDate;
  final MedicineStatus status;
  final String expiryDate;
  final VoidCallback? onTap;

  const MedicineTile({
    super.key,
    required this.name,
    required this.patient,
    required this.acquiredDate,
    required this.status,
    required this.expiryDate,
    this.onTap,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _statusLabel {
    switch (status) {
      case MedicineStatus.available:
        return 'Available';
      case MedicineStatus.opened:
        return 'Opened';
      case MedicineStatus.expiring:
        return 'Expiring!';
    }
  }

  Color get _statusColor {
    switch (status) {
      case MedicineStatus.available:
        return AppColors.primary;
      case MedicineStatus.opened:
        return AppColors.warning;
      case MedicineStatus.expiring:
        return AppColors.danger;
    }
  }

  Color get _expiryTextColor =>
      status == MedicineStatus.expiring
          ? AppColors.danger
          : AppColors.textSecondary;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Medicine / lock icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFECEAE3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Name + patient · date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$patient · $acquiredDate',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Badge + expiry
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status badge pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  expiryDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: _expiryTextColor,
                    fontWeight: status == MedicineStatus.expiring
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
