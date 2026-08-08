import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Premium Soft Lavender Theme
  static const Color primary = Color(0xFFA855F7); // Rich Lavender
  static const Color secondary = Color(0xFFC084FC); // Soft Purple
  static const Color accent = Color(0xFFDDD6FE); // Light Lavender Accent
  
  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8F5FF); // Soft Off-White Lavender
  static const Color backgroundDark = Color(0xFF181024);
  static const Color surfaceLight = Color(0xFFFFFFFF); // Solid White Card
  static const Color surfaceDark = Color(0xFF231834);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFECE7FF); // Subtle Lavender Border

  // Text Colors
  static const Color textPrimary = Color(0xFF3B2F63); // Deep Purple Gray
  static const Color textSecondary = Color(0xFF7C6F9B); // Muted Purple Gray
  static const Color textPrimaryLight = Color(0xFF3B2F63);
  static const Color textSecondaryLight = Color(0xFF7C6F9B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF8B5CF6);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFFA855F7),
    Color(0xFFC084FC),
  ];

  static const List<Color> buttonGradient = [
    Color(0xFFA855F7),
    Color(0xFFC084FC),
  ];

  static const List<Color> glassGradient = [
    Color(0xCCFFFFFF),
    Color(0x99F8F5FF),
  ];

  static const List<Color> softBackgroundGradient = [
    Color(0xFFF8F5FF),
    Color(0xFFF3E8FF),
  ];

  // Role Colors
  static const Color ngoColor = Color(0xFF9333EA);
  static const Color donorColor = Color(0xFFA855F7);
  static const Color adminColor = Color(0xFF7E22CE);
}
