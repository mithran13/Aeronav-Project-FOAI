import 'package:flutter/material.dart';

class AppColors {
  // Dark Navy Cockpit Backgrounds
  static const Color spaceNavy = Color(0xFF070B19);
  static const Color cockpitDark = Color(0xFF0D1527);
  static const Color cardBg = Color(0xFF131D33);
  static const Color cardGlass = Color(0xCC131D33);
  static const Color surfaceOverlay = Color(0xFF1F2D4D);
  static const Color borderSubtle = Color(0xFF2B3C63);

  // Light Mode Tokens
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Electric Blue & Aviation Accents
  static const Color electricBlue = Color(0xFF0284C7);
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color electricAmber = Color(0xFFFF9F1C);
  static const Color emergencyRed = Color(0xFFFF4757);
  static const Color radarGreen = Color(0xFF10B981);
  static const Color magentaWarning = Color(0xFFF15BB5);

  // Legacy fallback alias for cyan transition -> now maps to Electric Blue
  static const Color neonCyan = Color(0xFF0284C7);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHud = Color(0xFF38BDF8);

  // Flight Plan Status Colors
  static const Color statusDraft = Color(0xFF94A3B8);
  static const Color statusFiled = Color(0xFF0284C7);
  static const Color statusDispatched = Color(0xFFFF9F1C);
  static const Color statusInFlight = Color(0xFF38BDF8);
  static const Color statusCompleted = Color(0xFF10B981);

  // Gradients
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xDF192645), Color(0xBF0D1527)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricBlueGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
