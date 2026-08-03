import 'package:flutter/material.dart';

/// Paleta centralizada de Pollos Krosty Sado.
/// Tenerla en un solo lugar permite re-tematizar todas las pantallas a la vez.
class AppColors {
  AppColors._();

  static const Color primaryRed = Color(0xFFB8202E);
  static const Color primaryRedDark = Color(0xFF8E1722);
  static const Color accentGreen = Color(0xFF1E7A46);

  static const Color background = Color(0xFFF3F4F6);
  static const Color cardBackground = Colors.white;

  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color borderLight = Color(0xFFD7DAE0);
  static const Color borderFocus = primaryRed;

  static const Color tableHeaderBg = Color(0xFFF8F9FB);
  static const Color rowDivider = Color(0xFFEDEEF1);

  static const Color badgeBackground = Color(0xFF394150);
  static const Color badgeText = Colors.white;
}
