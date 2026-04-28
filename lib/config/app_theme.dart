import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central theme configuration for MedBox.
/// Usage: `theme: AppTheme.light` in MaterialApp.
abstract final class AppTheme {

  // ── Root theme ────────────────────────────────────────────────────────────────

  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary:    AppColors.primary,
        secondary:  AppColors.rxBlue,
        error:      AppColors.danger,
        surface:    AppColors.card,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      AppColors.card,
        selectedItemColor:    AppColors.primary,
        unselectedItemColor:  AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:   TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.border,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }

  // Keep 'dark' as an alias so any remaining callers don't break
  static ThemeData get dark => light;

  // ── Text styles ───────────────────────────────────────────────────────────────

  /// Large screen title, e.g. "Medicines", "Prescriptions"
  static const TextStyle screenTitle = TextStyle(
    fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );

  /// Section title inside a screen
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );

  /// Small ALL-CAPS grey section label, e.g. "OVERVIEW", "VISIT DETAILS"
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.2, color: AppColors.textSecondary,
  );

  /// Primary body text on cards
  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );

  /// Secondary / muted body text
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13, color: AppColors.textSecondary,
  );

  /// Compact caption used for dates, counts, subtitles
  static const TextStyle caption = TextStyle(
    fontSize: 12, color: AppColors.textSecondary,
  );

  /// Bold card title (medicine name, prescription cause)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  /// Primary-coloured "See all" / link text
  static const TextStyle link = TextStyle(
    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600,
  );

  /// Back-navigation label (primary teal, medium weight)
  static const TextStyle backLabel = TextStyle(
    fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500,
  );

  // ── Input decorations ─────────────────────────────────────────────────────────

  /// Standard search bar / text field container decoration
  static BoxDecoration get searchBarDecoration => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );

  /// Inline form field decoration (inside a card section, no border)
  static InputDecoration formFieldDecoration({
    required String hint,
    bool isDense = true,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAFADA6)),
        border: InputBorder.none,
        isDense: isDense,
        contentPadding: EdgeInsets.zero,
      );

  // ── Icon container helper ─────────────────────────────────────────────────────

  static BoxDecoration iconContainerDecoration(Color bg, {double radius = 10}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      );
}
