import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema global de Pollos Krosty Sado.
/// Hace que los widgets estándar (barras, diálogos, campos, botones, indicadores)
/// usen la paleta roja de la marca sin repetir estilos en cada pantalla.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryRed,
      primary: AppColors.primaryRed,
      onPrimary: Colors.white,
      secondary: AppColors.accentGreen,
      error: AppColors.primaryRed,
      surface: Colors.white,
    );
    final fieldRadius = BorderRadius.circular(10);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.rowDivider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFFA1A6B0)),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryRed),
        prefixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderLight),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryRed),
      dividerTheme: const DividerThemeData(color: AppColors.rowDivider, space: 1, thickness: 1),
    );
  }
}
