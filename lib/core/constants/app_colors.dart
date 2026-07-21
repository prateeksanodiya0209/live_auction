import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Deep Royal Dark & Gold Accents
  static const Color background = Color(0xFF0F0E17);
  static const Color surface = Color(0xFF1B1A26);
  static const Color surfaceLight = Color(0xFF272538);
  static const Color cardBg = Color(0xFF222034);

  // Accent Colors
  static const Color primary = Color(0xFFFFB800); // Gold Accent
  static const Color primaryDark = Color(0xFFE6A300);
  static const Color accent = Color(0xFF7F56D9); // Violet Glow
  static const Color accentLight = Color(0xFF9E77ED);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFE);
  static const Color textSecondary = Color(0xFFA7A6BA);
  static const Color textMuted = Color(0xFF6E6D7A);

  // Functional Status Colors
  static const Color success = Color(0xFF12B76A);
  static const Color error = Color(0xFFF04438);
  static const Color warning = Color(0xFFF79009);
  static const Color info = Color(0xFF2E90FA);

  // Border & Divider Colors
  static const Color border = Color(0xFF2D2B3F);
  static const Color borderFocused = Color(0xFFFFB800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7F56D9), Color(0xFF9E77ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF252338), Color(0xFF1B1A26)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
