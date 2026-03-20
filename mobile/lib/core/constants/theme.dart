import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OpenFlight design tokens.
abstract final class AppColors {
  // Base surfaces — deep navy-black for rich glassmorphism depth
  static const background = Color(0xFF090C14);
  static const surface = Color(0xFF0F1420);
  static const surfaceVariant = Color(0xFF151C2C);

  // Accent — OpenFlight green
  static const accent = Color(0xFF00E676);
  static const accentDim = Color(0xFF00C853);
  static const onAccent = Color(0xFF000000);

  // Text
  static const onSurface = Color(0xFFE8ECF4);
  static const onSurfaceMuted = Color(0xFF7A8499);

  // Semantic
  static const error = Color(0xFFFF6B81);
  static const warning = Color(0xFFFFC107);

  // Structural
  static const divider = Color(0xFF1C2338);

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
  static const md = Radius.circular(14.0);
  static const lg = Radius.circular(20.0);
  static const xl = Radius.circular(30.0);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      letterSpacing: -2.0,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      letterSpacing: -1.0,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      letterSpacing: -0.3,
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
      height: 1.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceMuted,
      letterSpacing: 1.0,
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
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(AppRadius.md),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.accent : AppColors.onSurfaceMuted,
        );
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.12),
      trackHeight: 2,
    ),
    dividerColor: AppColors.divider,
    iconTheme: const IconThemeData(color: AppColors.onSurfaceMuted),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
  );
}
