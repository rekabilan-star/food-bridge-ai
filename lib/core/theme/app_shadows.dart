import 'package:flutter/material.dart';

/// Design System Elevation & Shadow Tokens for FoodBridge AI.
/// Replaces excessive colorful blurs with restrained, accessible elevation.
class AppShadows {
  AppShadows._();

  /// Soft, subtle shadow for flat cards, search bars, and list items
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A1E152A), // 4% deep plum
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Standard card elevation
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D1E152A), // 5% deep plum
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Elevated shadow for floating action buttons, modals, dropdowns
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x141E152A), // 8% deep plum
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Button press / active shadow
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x265B21B6), // 15% primary violet
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Zero shadow
  static const List<BoxShadow> none = [];
}
