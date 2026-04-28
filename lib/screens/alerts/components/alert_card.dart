import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../alert_data.dart';

/// A single alert card — works for both expiring and opened-too-long alerts.
/// Dismissed cards are rendered in a grey/muted style with an Undo button.
///
/// [onDismiss] is called when the Dismiss button is tapped.
/// [onUndo]    is called when the Undo button is tapped (dismissed card only).
/// [onViewMedicine] navigates to the Medicine Detail screen.
class AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onDismiss;
  final VoidCallback onUndo;
  final VoidCallback? onViewMedicine;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onUndo,
    this.onViewMedicine,
  });

  // ── Colour helpers ────────────────────────────────────────────────────────────

  Color get _accent => alert.isDismissed ? AppColors.textSecondary : alert.accentColor;
  Color get _cardBg => alert.isDismissed ? AppColors.surface : alert.cardBg;
  Color get _textColor => alert.isDismissed ? AppColors.textSecondary : alert.accentColor;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: name · days pill · action button ───────────────────────
          Row(
            children: [
              // Medicine name
              Expanded(
                child: Text(
                  alert.medicineName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: alert.isDismissed ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Days pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(alert.isDismissed ? 0.15 : 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alert.daysLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alert.isDismissed ? AppColors.textSecondary : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dismiss / Undo button
              GestureDetector(
                onTap: alert.isDismissed ? onUndo : onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withOpacity(0.6)),
                  ),
                  child: Text(
                    alert.isDismissed ? 'Undo' : 'Dismiss',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Row 2: description text ──────────────────────────────────────
          Text(
            alert.description,
            style: TextStyle(fontSize: 12, color: _textColor),
          ),
          const SizedBox(height: 10),

          // ── Row 3: patient avatar + name  |  View medicine → ────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: alert.isDismissed
                          ? AppColors.border
                          : alert.patientAvatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        alert.patientInitials,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    alert.patientName,
                    style: TextStyle(
                      fontSize: 12,
                      color: alert.isDismissed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // View medicine link (hidden when dismissed)
              if (!alert.isDismissed)
                GestureDetector(
                  onTap: onViewMedicine,
                  child: const Row(
                    children: [
                      Text(
                        'View medicine',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
