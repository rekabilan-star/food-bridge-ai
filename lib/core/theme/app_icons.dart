import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Design System Icon Tokens & Conventions for FoodBridge AI.
/// Enforces the Material Rounded icon family and standard sizing/color rules.
class AppIcons {
  AppIcons._();

  // -------------------------------------------------------------
  // Icon Sizing Scale
  // -------------------------------------------------------------
  /// 16px - Micro icons (inline badges, timestamps, tags)
  static const double sizeXs = 16.0;

  /// 20px - Small icons (app bar actions, text field prefixes, small buttons)
  static const double sizeSm = 20.0;

  /// 24px - Standard icons (navigation items, action buttons, card headers)
  static const double sizeMd = 24.0;

  /// 28px - Large icons (featured list tiles, section highlights)
  static const double sizeLg = 28.0;

  /// 36px - Extra large icons (modal headers, prominent status indicators)
  static const double sizeXl = 36.0;

  /// 48px - Feature icons (empty states, success confirmations)
  static const double sizeXxl = 48.0;

  // -------------------------------------------------------------
  // Standard Action Icons (Material Rounded)
  // -------------------------------------------------------------
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData filter = Icons.filter_list_rounded;

  // -------------------------------------------------------------
  // Navigation Icons
  // -------------------------------------------------------------
  static const IconData homeActive = Icons.home_rounded;
  static const IconData homeInactive = Icons.home_outlined;
  static const IconData donationsActive = Icons.inventory_2_rounded;
  static const IconData donationsInactive = Icons.inventory_2_outlined;
  static const IconData messagesActive = Icons.chat_bubble_rounded;
  static const IconData messagesInactive = Icons.chat_bubble_outline_rounded;
  static const IconData profileActive = Icons.person_rounded;
  static const IconData profileInactive = Icons.person_outline_rounded;
  static const IconData notificationActive = Icons.notifications_rounded;
  static const IconData notificationInactive = Icons.notifications_none_rounded;

  // -------------------------------------------------------------
  // Status Icons
  // -------------------------------------------------------------
  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData waiting = Icons.schedule_rounded;
  static const IconData transit = Icons.local_shipping_rounded;
  static const IconData delivered = Icons.task_alt_rounded;

  // -------------------------------------------------------------
  // Feature Icons
  // -------------------------------------------------------------
  static const IconData food = Icons.restaurant_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData phone = Icons.phone_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData qrCode = Icons.qr_code_rounded;
  static const IconData analytics = Icons.insights_rounded;
  static const IconData empty = Icons.inbox_rounded;
}

/// A standard icon container that renders an icon inside a soft tinted background.
class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppIconContainer({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = AppIcons.sizeSm,
    this.padding = 10.0,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBg = backgroundColor ?? effectiveColor.withValues(alpha: 0.1);
    final effectiveRadius = borderRadius ?? AppRadius.borderMd;

    Widget container = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
      ),
      child: Icon(
        icon,
        size: size,
        color: effectiveColor,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: container,
        ),
      );
    }

    return container;
  }
}
