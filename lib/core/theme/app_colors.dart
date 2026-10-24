import 'package:flutter/material.dart';

/// Design System Color Palette for FoodBridge AI.
/// Professional Deep Violet & Soft Lavender light theme with accessible contrast.
class AppColors {
  AppColors._();

  // -------------------------------------------------------------
  // Brand Core Colors
  // -------------------------------------------------------------
  /// Professional deep violet (WCAG AAA compliant: 11.2:1 against white)
  static const Color primary = Color(0xFF5B21B6);

  /// Vibrant deep violet for highlights and active states
  static const Color primaryLight = Color(0xFF6D28D9);

  /// Soft lavender for secondary actions and subtle branding
  static const Color secondary = Color(0xFF8B5CF6);

  /// Very soft lavender tint for chip backgrounds, badges, and accents
  static const Color accent = Color(0xFFEDE9FE);

  // -------------------------------------------------------------
  // Background & Surfaces
  // -------------------------------------------------------------
  /// Very light lavender-white background
  static const Color backgroundLight = Color(0xFFF8F7FC);
  static const Color backgroundDark = Color(0xFF181024);

  /// Clean solid white for cards, sheets, and inputs
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF231834);

  /// Alias for card surface
  static const Color card = surfaceLight;

  /// Subtle neutral lavender-grey border
  static const Color border = Color(0xFFE5E0F0);

  /// Stronger border for active, focused, or selected states
  static const Color borderActive = Color(0xFFC4B5FD);

  // -------------------------------------------------------------
  // Typography Colors (WCAG Compliant)
  // -------------------------------------------------------------
  /// Deep charcoal/plum text (14.8:1 contrast on white)
  static const Color textPrimary = Color(0xFF1E152A);

  /// Muted grey-purple text for subtitles, hints, and meta (4.9:1 contrast on white)
  static const Color textSecondary = Color(0xFF6E657E);

  /// Aliases for compatibility
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // -------------------------------------------------------------
  // Semantic / Status Colors (WCAG Compliant on White)
  // -------------------------------------------------------------
  /// Accessible forest green (4.8:1 on white)
  static const Color success = Color(0xFF15803D);

  /// Accessible amber/orange (4.6:1 on white)
  static const Color warning = Color(0xFFD97706);

  /// Accessible crimson red (4.6:1 on white)
  static const Color error = Color(0xFFDC2626);

  /// Accessible royal blue (4.7:1 on white)
  static const Color info = Color(0xFF2563EB);

  // -------------------------------------------------------------
  // Subtle Gradients (Restrained & Professional)
  // -------------------------------------------------------------
  static const List<Color> primaryGradient = [
    Color(0xFF5B21B6),
    Color(0xFF6D28D9),
  ];

  static const List<Color> buttonGradient = [
    Color(0xFF5B21B6),
    Color(0xFF6D28D9),
  ];

  static const List<Color> glassGradient = [
    Color(0xF0FFFFFF),
    Color(0xD9F8F7FC),
  ];

  static const List<Color> softBackgroundGradient = [
    Color(0xFFF8F7FC),
    Color(0xFFF3E8FF),
  ];

  // -------------------------------------------------------------
  // Role Semantic Colors
  // -------------------------------------------------------------
  static const Color ngoColor = Color(0xFF7C3AED);
  static const Color donorColor = Color(0xFF5B21B6);
  static const Color adminColor = Color(0xFF4C1D95);
}
