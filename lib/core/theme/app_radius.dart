import 'package:flutter/material.dart';

/// Design System Corner Radius Tokens for FoodBridge AI.
/// Standardizes values around 12, 16, and 20 logical pixels.
class AppRadius {
  AppRadius._();

  /// 6.0 - Micro radius for sub-badges or small tags
  static const double xs = 6.0;

  /// 8.0 - Small radius for chips and compact controls
  static const double sm = 8.0;

  /// 12.0 - Medium radius for input fields, filter chips, compact cards
  static const double md = 12.0;

  /// 16.0 - Standard radius for buttons, regular cards, dialogs
  static const double lg = 16.0;

  /// 20.0 - Large radius for hero cards, modal sheets, floating nav
  static const double xl = 20.0;

  /// 999.0 - Full rounded pill or circular avatar
  static const double full = 999.0;

  // -------------------------------------------------------------
  // BorderRadius Tokens
  // -------------------------------------------------------------
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));

  // -------------------------------------------------------------
  // Sheet-specific Radius (Top-only)
  // -------------------------------------------------------------
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
