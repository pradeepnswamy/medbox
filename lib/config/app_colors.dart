import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — teal
  static const Color primary       = Color(0xFF1D9E75);
  static const Color primaryLight  = Color(0xFFE1F5EE);
  static const Color primaryDark   = Color(0xFF085041);

  // Prescription — blue
  static const Color rxBlue        = Color(0xFF185FA5);
  static const Color rxBlueLight   = Color(0xFFE6F1FB);
  static const Color rxBlueDark    = Color(0xFF0C447C);

  // Critical — red
  static const Color danger        = Color(0xFFA32D2D);
  static const Color dangerLight   = Color(0xFFFCEBEB);
  static const Color dangerBorder  = Color(0xFFF09595);

  // Caution — amber
  static const Color warning       = Color(0xFF854F0B);
  static const Color warningLight  = Color(0xFFFAEEDA);
  static const Color warningBorder = Color(0xFFEF9F27);

  // Neutrals
  static const Color textPrimary   = Color(0xFF2C2C2A);
  static const Color textSecondary = Color(0xFF888780);
  static const Color surface       = Color(0xFFF1EFE8);  // page background
  static const Color card          = Color(0xFFFFFFFF);  // card background
  static const Color border        = Color(0xFFD3D1C7);

  // Patient avatar palette (same hues, will contrast on white cards)
  static const List<Color> avatarPalette = [
    Color(0xFF1D9E75), Color(0xFFF48FB1), Color(0xFFFF8A65),
    Color(0xFF185FA5), Color(0xFFF5A623), Color(0xFF9C27B0),
  ];

  // ── Overview / stat card fills ────────────────────────────────────────────────
  static const Color statMint      = Color(0xFFD0F0E8);
  static const Color statMintText  = Color(0xFF085041);
  static const Color statMintSub   = Color(0xFF1D9E75);

  static const Color statPink      = Color(0xFFFDE8E8);
  static const Color statPinkText  = Color(0xFFA32D2D);
  static const Color statPinkSub   = Color(0xFFD94F55);

  static const Color statAmber     = Color(0xFFFDF0D8);
  static const Color statAmberText = Color(0xFF854F0B);
  static const Color statAmberSub  = Color(0xFFEF9F27);
}
