import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import 'badge_chip.dart';

/// One medicine card in the list. The [attentionColor] adds a coloured left
/// border accent around the card (danger for expiring, warning for opened).
/// Pass null for normal "Available" cards.
///
/// [badges] is an ordered list of (label, style) pairs rendered as pill chips.
class MedicineListCard extends StatelessWidget {
  final String name;
  /// Optional patient name shown below the medicine name.
  /// Null when no patient is associated (OTC / shared medicine).
  final String? patientName;
  final String acquiredDate;
  final String expiryLabel;
  final Color expiryColor;
  final List<(String, BadgeStyle)> badges;
  final Color? attentionColor;
  final VoidCallback? onTap;

  const MedicineListCard({
    super.key,
    required this.name,
    this.patientName,
    required this.acquiredDate,
    required this.expiryLabel,
    required this.expiryColor,
    required this.badges,
    this.attentionColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttention = attentionColor != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: hasAttention
              ? Border.all(color: attentionColor!.withOpacity(0.5), width: 1.5)
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasAttention
                    ? attentionColor!.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_rounded,
                size: 24,
                color: hasAttention ? attentionColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),

            // Centre: name, patient·date, badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + expiry label (top row)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        expiryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: expiryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Patient · acquired date
                  Text(
                    patientName != null
                        ? '$patientName · $acquiredDate'
                        : acquiredDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badge row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges
                        .map((b) => BadgeChip(label: b.$1, style: b.$2))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Trailing chevron
            const Padding(
              padding: EdgeInsets.only(top: 2, left: 6),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
