import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design System Typography Tokens for FoodBridge AI.
/// Powered by GoogleFonts.poppins with accessible contrast and clean hierarchy.
class AppTypography {
  AppTypography._();

  /// 28pt, bold - Prominent screen hero titles
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  /// 22pt, bold - Standard page/screen titles
  static TextStyle pageTitle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  /// 18pt, semi-bold - Major section headings
  static TextStyle sectionHeading = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.35,
  );

  /// 16pt, semi-bold - Sub-section headings and card titles
  static TextStyle subsectionHeading = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  /// 16pt, regular - Primary body text
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 14pt, regular - Secondary body text and item descriptions
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  /// 12pt, regular - Compact secondary descriptions
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// 14pt, semi-bold - Form field labels
  static TextStyle fieldLabel = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 14pt, regular - Form field placeholder / hint text
  static TextStyle fieldHint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary.withValues(alpha: 0.7),
    height: 1.3,
  );

  /// 12pt, medium - Accessible status chips, metadata badges, timestamps
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// 12pt, bold - Emphasized metadata, tags, and small labels
  static TextStyle captionBold = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 11pt, bold - Micro badges and status pills
  static TextStyle badge = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    height: 1.2,
  );

  /// 15pt, semi-bold - Primary & secondary button labels
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
  );
}
