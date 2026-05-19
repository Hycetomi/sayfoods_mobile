import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF5B1380); // The brand Deep Purple
  static const Color primaryLight = Color(0xFF7A29A6);
  static const Color primaryDark = Color(0xFF3F0A5C);

  // Background & Surfaces
  static const Color background = Color(0xFFFCFBFD); // Very subtle purple tint
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F3F7); // For elevated cards without shadow

  // Typography
  static const Color textPrimary = Color(0xFF1E1B20); // Not pure black, softer
  static const Color textSecondary = Color(0xFF757179);
  static const Color textDisabled = Color(0xFFB5B2B7);

  // Status & Feedback
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);

  // Dividers & Borders
  static const Color border = Color(0xFFEBE9ED);

  // Shimmer
  static const Color shimmerBase = Color(0xFFF5F3F7);
  static const Color shimmerHighlight = Color(0xFFFCFBFD);
}
