import 'package:flutter/material.dart';

/// Design System Spacing Tokens for FoodBridge AI.
/// Strictly follows the 8, 12, 16, 20, 24, and 32 logical pixel scale.
class AppSpacing {
  AppSpacing._();

  /// 4.0 - Micro spacing (icon-text gaps, badge padding)
  static const double xs = 4.0;

  /// 8.0 - Small spacing (item gap, internal chip padding)
  static const double sm = 8.0;

  /// 12.0 - Medium-small spacing (compact card padding, field gap)
  static const double md = 12.0;

  /// 16.0 - Base standard spacing (standard card padding, list item gap)
  static const double base = 16.0;

  /// 20.0 - Large spacing (page horizontal padding, section gap)
  static const double lg = 20.0;

  /// 24.0 - Extra large spacing (screen margins, modal padding)
  static const double xl = 24.0;

  /// 32.0 - Double extra large spacing (hero padding, empty state margins)
  static const double xxl = 32.0;

  // -------------------------------------------------------------
  // Convenient EdgeInsets Tokens
  // -------------------------------------------------------------
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingBase = EdgeInsets.all(base);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  /// Standard screen page padding: 20px horizontal, 16px vertical
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg, vertical: base);

  /// Horizontal-only page margin
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical-only page spacing
  static const EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: base);

  // -------------------------------------------------------------
  // Vertical SizedBox Spacers
  // -------------------------------------------------------------
  static const SizedBox vGapXs = SizedBox(height: xs);
  static const SizedBox vGapSm = SizedBox(height: sm);
  static const SizedBox vGapMd = SizedBox(height: md);
  static const SizedBox vGapBase = SizedBox(height: base);
  static const SizedBox vGapLg = SizedBox(height: lg);
  static const SizedBox vGapXl = SizedBox(height: xl);
  static const SizedBox vGapXxl = SizedBox(height: xxl);

  // -------------------------------------------------------------
  // Horizontal SizedBox Spacers
  // -------------------------------------------------------------
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapBase = SizedBox(width: base);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
  static const SizedBox hGapXxl = SizedBox(width: xxl);
}
