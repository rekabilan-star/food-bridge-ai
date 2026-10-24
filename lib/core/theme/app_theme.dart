import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized Material 3 Theme for FoodBridge AI.
/// Connects all Design System tokens into a unified, accessible light theme.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: AppColors.primary,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.borderActive,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    // -----------------------------------------------------------
    // Typography
    // -----------------------------------------------------------
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: AppTypography.displayLarge,
      titleLarge: AppTypography.pageTitle,
      titleMedium: AppTypography.sectionHeading,
      titleSmall: AppTypography.subsectionHeading,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.fieldLabel,
      labelSmall: AppTypography.caption,
    ),

    // -----------------------------------------------------------
    // App Bar
    // -----------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      titleTextStyle: AppTypography.pageTitle.copyWith(fontSize: 18),
    ),

    // -----------------------------------------------------------
    // Card Theme
    // -----------------------------------------------------------
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      shadowColor: Colors.transparent,
    ),

    // -----------------------------------------------------------
    // Button Themes
    // -----------------------------------------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E0F0),
        disabledForegroundColor: const Color(0xFF9E95AD),
        minimumSize: const Size(double.infinity, 54),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        elevation: 0,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFF9E95AD),
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        elevation: 0,
        textStyle: AppTypography.button.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.button.copyWith(fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
    ),

    // -----------------------------------------------------------
    // Input Fields
    // -----------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderLg,
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderLg,
        borderSide: BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderLg,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderLg,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderLg,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.base),
      hintStyle: AppTypography.fieldHint,
      labelStyle: AppTypography.bodyMedium,
      floatingLabelStyle: AppTypography.fieldLabel.copyWith(color: AppColors.primary),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.textSecondary,
    ),

    // -----------------------------------------------------------
    // Dialogs & Bottom Sheets
    // -----------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      titleTextStyle: AppTypography.sectionHeading,
      contentTextStyle: AppTypography.bodyMedium,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      modalBackgroundColor: Colors.white,
    ),

    // -----------------------------------------------------------
    // Chips & Badges
    // -----------------------------------------------------------
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      disabledColor: const Color(0xFFF1EEF8),
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.accent,
      labelStyle: AppTypography.caption,
      secondaryLabelStyle: AppTypography.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      side: const BorderSide(color: AppColors.border, width: 1.2),
    ),

    // -----------------------------------------------------------
    // Dividers
    // -----------------------------------------------------------
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: AppSpacing.base,
    ),
  );

  static ThemeData darkTheme = lightTheme;
}
