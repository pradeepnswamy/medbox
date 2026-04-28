import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/alert_item.dart';

// Re-export so that dashboard_screen.dart can reference AlertSeverity
// via its existing import of this file.
export '../../../models/alert_item.dart' show AlertSeverity;

/// A tappable alert row with a coloured background, dot indicator,
/// title, subtitle, and a trailing chevron.
///
/// Usage:
///   AlertTile(
///     severity: AlertSeverity.critical,
///     title: 'Amoxicillin 250mg expiring',
///     subtitle: 'Expires Apr 20 · Ravi Kumar · 4 days left',
///     onTap: () {},
///   )
class AlertTile extends StatelessWidget {
  final AlertSeverity severity;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const AlertTile({
    super.key,
    required this.severity,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  Color get _dotColor =>
      severity == AlertSeverity.critical
          ? AppColors.danger
          : AppColors.warning;

  Color get _bgColor =>
      severity == AlertSeverity.critical
          ? AppColors.dangerLight
          : AppColors.warningLight;

  Color get _titleColor =>
      severity == AlertSeverity.critical
          ? AppColors.danger
          : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Coloured dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _titleColor.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _dotColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
