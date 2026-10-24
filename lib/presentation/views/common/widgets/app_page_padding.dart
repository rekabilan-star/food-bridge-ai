import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Design System Standard Page Padding Wrapper for FoodBridge AI.
/// Enforces consistent screen horizontal margins (20 logical pixels) and safe areas.
class AppPagePadding extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const AppPagePadding({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppSpacing.pagePadding;

    if (scrollable) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics ?? const BouncingScrollPhysics(),
        padding: effectivePadding,
        child: child,
      );
    }

    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
