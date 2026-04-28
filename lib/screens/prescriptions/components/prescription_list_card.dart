import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// One prescription card in the list.
/// Shows: cause (title), date (right), hospital · doctor (subtitle),
/// patient avatar + name, document icon, medicine count badge, chevron.
class PrescriptionListCard extends StatelessWidget {
  final String cause;
  final String date;
  final String hospital;
  final String doctor;
  final String patientName;
  final String patientInitials;
  final Color patientAvatarColor;
  final int medicineCount;
  final VoidCallback? onTap;

  const PrescriptionListCard({
    super.key,
    required this.cause,
    required this.date,
    required this.hospital,
    required this.doctor,
    required this.patientName,
    required this.patientInitials,
    required this.patientAvatarColor,
    required this.medicineCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: cause + date ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cause,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // ── Row 2: hospital · doctor ────────────────────────────────────
            Text(
              '$hospital · $doctor',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // ── Row 3: avatar + name  |  doc icon  |  med count  |  chevron ─
            Row(
              children: [
                // Patient avatar
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: patientAvatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patientInitials,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Document icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.rxBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: AppColors.rxBlue,
                  ),
                ),
                const SizedBox(width: 8),

                // Medicine count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$medicineCount meds',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
