import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// A horizontally-scrollable patient selector chip.
/// Shows a coloured avatar with initials, the patient's name, and a med count.
/// Highlights with a green border when [isSelected] is true.
///
/// Usage:
///   PatientChip(
///     initials: 'RK',
///     name: 'Ravi',
///     medCount: 5,
///     avatarColor: Color(0xFF4ECBA0),
///     isSelected: true,
///     onTap: () {},
///   )
class PatientChip extends StatelessWidget {
  final String initials;
  final String name;
  final int medCount;
  final Color avatarColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const PatientChip({
    super.key,
    required this.initials,
    required this.name,
    required this.medCount,
    required this.avatarColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name & med count
            Column(
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
                const SizedBox(height: 2),
                Text(
                  '$medCount meds',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
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
