import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OpenFlight design tokens — mockup v2 palette.
abstract final class AppColors {
  // Base surfaces
  static const background = Color(0xFF0F1419);
  static const surfaceContainerLowest = Color(0xFF0A0F13);
  static const surfaceContainerLow = Color(0xFF171C21);
  static const surfaceContainer = Color(0xFF1B2025);
  static const surfaceContainerHigh = Color(0xFF252A30);
  static const surfaceContainerHighest = Color(0xFF30353A);

  // Legacy aliases kept for backward compatibility
  static const surface = surfaceContainerLow;
  static const surfaceVariant = surfaceContainerHigh;

  // Primary — OpenFlight green
  static const accent = Color(0xFF66DF75);
  static const accentDim = Color(0xFF4ABF58);
  static const onAccent = Color(0xFF0A1A0C);

  // Secondary — periwinkle blue
  static const secondary = Color(0xFFA6C8FF);

  // Text
  static const onSurface = Color(0xFFE2E8E0);
  static const onSurfaceVariant = Color(0xFFBDCAB9);
  static const onSurfaceMuted = Color(0xFF879484);

  // Borders
  static const outlineVariant = Color(0xFF3E4A3C);
  static const outline = Color(0xFF879484);

  // Semantic
  static const error = Color(0xFFFF6B81);
  static const warning = Color(0xFFFFC107);

  // Structural
  static const divider = Color(0xFF252A30);

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

  // Space Grotesk for display/headline numbers, Inter for body
  final textTheme = base.textTheme.copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      color: AppColors.onSurface,
      letterSpacing: -2.5,
      height: 1.0,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      letterSpacing: -1.5,
      height: 1.0,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      letterSpacing: -1.0,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      letterSpacing: -0.3,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceVariant,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceMuted,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceMuted,
      letterSpacing: 0.8,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceMuted,
      letterSpacing: 1.2,
    ),
  );

  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceContainerLow,
      onSurface: AppColors.onSurface,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(AppRadius.md),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
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
      indicatorColor: AppColors.accent.withValues(alpha: 0.15),
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
      inactiveTrackColor: AppColors.surfaceContainerHigh,
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.12),
      trackHeight: 2,
    ),
    dividerColor: AppColors.divider,
    iconTheme: const IconThemeData(color: AppColors.onSurfaceMuted),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerHigh,
      labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.all(AppRadius.sm),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
        borderRadius: BorderRadius.all(AppRadius.sm),
      ),
    ),
  );
}
