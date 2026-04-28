import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/medicine.dart';

// Re-export BadgeStyle so that files which import badge_chip.dart
// (e.g. medicine_list_card.dart) continue to see BadgeStyle without changes.
export '../../../models/medicine.dart' show BadgeStyle;

/// A compact pill-shaped badge chip using the semantic colour system.
///
/// Each [BadgeStyle] maps to a specific fill + text pair from the design spec:
///   available    → primaryLight fill, primaryDark text   (#E1F5EE / #085041)
///   expiring     → dangerLight fill,  danger text        (#FCEBEB / #A32D2D)
///   opened       → warningLight fill, warning text       (#FAEEDA / #854F0B)
///   prescription → rxBlueLight fill,  rxBlue text        (#E6F1FB / #185FA5)
///   neutral      → surface fill,      muted text         (#F1EFE8 / #5F5E5A)
///
/// When [filled] is true (used for the top-status badge on the detail screen)
/// the chip gets a solid coloured background instead of the light fill.
class BadgeChip extends StatelessWidget {
  final String label;
  final BadgeStyle style;
  final bool filled;

  const BadgeChip({
    super.key,
    required this.label,
    required this.style,
    this.filled = false,
  });

  // ── Semantic colour pairs ─────────────────────────────────────────────────────

  Color get _fillColor {
    if (filled) return _solidColor;
    switch (style) {
      case BadgeStyle.available:    return AppColors.primaryLight;
      case BadgeStyle.expiring:     return AppColors.dangerLight;
      case BadgeStyle.opened:       return AppColors.warningLight;
      case BadgeStyle.prescription: return AppColors.rxBlueLight;
      case BadgeStyle.neutral:      return AppColors.surface;
    }
  }

  Color get _textColor {
    if (filled) return Colors.white;
    switch (style) {
      case BadgeStyle.available:    return AppColors.primaryDark;
      case BadgeStyle.expiring:     return AppColors.danger;
      case BadgeStyle.opened:       return AppColors.warning;
      case BadgeStyle.prescription: return AppColors.rxBlue;
      case BadgeStyle.neutral:      return const Color(0xFF5F5E5A);
    }
  }

  /// Solid background colour used when [filled] is true.
  Color get _solidColor {
    switch (style) {
      case BadgeStyle.available:    return AppColors.primary;
      case BadgeStyle.expiring:     return AppColors.danger;
      case BadgeStyle.opened:       return AppColors.warning;
      case BadgeStyle.prescription: return AppColors.rxBlue;
      case BadgeStyle.neutral:      return AppColors.textSecondary;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
