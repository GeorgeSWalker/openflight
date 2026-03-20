import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OpenFlight design tokens.
abstract final class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF2A2A2A);
  static const accent = Color(0xFF00E676); // OpenFlight Green
  static const accentDim = Color(0xFF00C853);
  static const onAccent = Color(0xFF000000);
  static const onSurface = Color(0xFFE0E0E0);
  static const onSurfaceMuted = Color(0xFF9E9E9E);
  static const error = Color(0xFFCF6679);
  static const warning = Color(0xFFFFC107);
  static const divider = Color(0xFF2C2C2C);

  // Connection status
  static const connected = accent;
  static const connecting = warning;
  static const disconnected = error;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = Radius.circular(8.0);
  static const md = Radius.circular(12.0);
  static const lg = Radius.circular(16.0);
  static const xl = Radius.circular(24.0);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      letterSpacing: -1.5,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceMuted,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceMuted,
      letterSpacing: 0.8,
    ),
  );

  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentDim,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.md),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.onSurface),
    ),
    dividerColor: AppColors.divider,
    iconTheme: const IconThemeData(color: AppColors.onSurfaceMuted),
  );
}
