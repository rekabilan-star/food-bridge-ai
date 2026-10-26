import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'primary_button.dart';

/// Design System Empty State component for FoodBridge AI.
/// Provides a consistent, polished empty or zero-data illustration/icon placeholder with optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final EdgeInsetsGeometry padding;
  final Color? iconColor;

  const EmptyState({
    super.key,
    this.icon = AppIcons.empty,
    required this.title,
    this.message,
    this.actionText,
    this.onActionPressed,
    this.padding = AppSpacing.paddingXxl,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.primary;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Soft Tinted Icon Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppIcons.sizeXxl,
                color: effectiveColor,
              ),
            ),
            AppSpacing.vGapLg,
            Text(
              title,
              style: AppTypography.sectionHeading,
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty) ...[
              AppSpacing.vGapSm,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (actionText != null && onActionPressed != null) ...[
              AppSpacing.vGapXl,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: PrimaryButton(
                  text: actionText!,
                  onPressed: onActionPressed,
                  height: 48,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
