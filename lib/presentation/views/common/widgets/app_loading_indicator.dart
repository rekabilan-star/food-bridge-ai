import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Design System Loading Indicator for FoodBridge AI.
/// Renders a centered, brand-themed activity indicator with optional message.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 28.0,
    this.color,
    this.padding = AppSpacing.paddingXl,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: effectiveColor,
                backgroundColor: effectiveColor.withValues(alpha: 0.15),
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              AppSpacing.vGapMd,
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
