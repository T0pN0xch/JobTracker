import 'package:flutter/material.dart';

import '../models/job_application.dart';

class AppColors {
  static const background = Color(0xFFE4DCFF);
  static const surface = Color(0xFFFAF8FF);
  static const primary = Color(0xFF6B5FD6);
  static const primaryLight = Color(0xFFD9D0FF);
  static const border = Color(0xFFCFC6FF);
  static const textPrimary = Color(0xFF1E1B4B);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static (Color bg, Color text) forStatus(JobStatus status) {
    switch (status) {
      case JobStatus.wishlist:
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case JobStatus.applied:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case JobStatus.phoneScreen:
        return (const Color(0xFFCCFBF1), const Color(0xFF0F766E));
      case JobStatus.interview:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case JobStatus.offer:
        return (const Color(0xFFD1FAE5), const Color(0xFF065F46));
      case JobStatus.rejected:
        return (const Color(0xFFFFE4E6), const Color(0xFFBE123C));
      case JobStatus.withdrawn:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  static Color avatarBg(String company) {
    const palette = [
      Color(0xFFFFDDD6),
      Color(0xFFFFEDD8),
      Color(0xFFFFF9C4),
      Color(0xFFD4EDDA),
      Color(0xFFCFE2FF),
      Color(0xFFE9D7FD),
      Color(0xFFFFD6F0),
      Color(0xFFD0F0F0),
    ];
    final i = (company.isEmpty ? 0 : company.codeUnitAt(0)) % palette.length;
    return palette[i];
  }

  static Color avatarText(String company) {
    const palette = [
      Color(0xFFC0392B),
      Color(0xFFD35400),
      Color(0xFFF39C12),
      Color(0xFF27AE60),
      Color(0xFF2980B9),
      Color(0xFF8E44AD),
      Color(0xFFD63384),
      Color(0xFF0097A7),
    ];
    final i = (company.isEmpty ? 0 : company.codeUnitAt(0)) % palette.length;
    return palette[i];
  }
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorSchemeSeed: AppColors.primary,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null,
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x22000000),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primary),
        actionsIconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBE123C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBE123C), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.textMuted,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
      dividerTheme:
          const DividerThemeData(color: Color(0xFFD4CAFF), space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 4,
      ),
    );
  }
}
