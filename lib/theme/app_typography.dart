import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get h1 => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get h3 => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body1 => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get body2 => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      );

  // Monospace Cockpit Telemetry HUD Font Style
  static TextStyle get hudDisplay => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.neonCyan,
        letterSpacing: 1.5,
      );

  static TextStyle get hudMetric => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.electricAmber,
        letterSpacing: 1.0,
      );

  static TextStyle get hudLabel => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.skyBlue,
        letterSpacing: 1.2,
      );
}
