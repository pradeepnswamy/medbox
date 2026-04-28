import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// A dark card showing one prescription: title, patient avatar + name,
/// date, and medicine count.
///
/// Usage:
///   PrescriptionTile(
///     title: 'Viral Fever',
///     patientInitials: 'RK',
///     patientName: 'Ravi Kumar',
///     avatarColor: Color(0xFF4ECBA0),
///     date: '12 Apr 2025',
///     medicineCount: 3,
///   )
class PrescriptionTile extends StatelessWidget {
  final String title;
  final String patientInitials;
  final String patientName;
  final Color avatarColor;
  final String date;
  final int medicineCount;
  final VoidCallback? onTap;

  const PrescriptionTile({
    super.key,
    required this.title,
    required this.patientInitials,
    required this.patientName,
    required this.avatarColor,
    required this.date,
    required this.medicineCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + date (top row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Patient avatar + name  +  medicine count (bottom row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: avatarColor,
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
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$medicineCount medicines',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
