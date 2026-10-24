import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Design System Secondary / Outline Action Button for FoodBridge AI.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDisabled ? const Color(0xFFF8F7FC) : Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDisabled ? const Color(0xFFE5E0F0) : (borderColor ?? AppColors.border),
          width: 1.5,
        ),
        boxShadow: isDisabled ? AppShadows.none : AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isDisabled ? const Color(0xFF9E95AD) : (textColor ?? AppColors.textPrimary),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  text,
                  style: AppTypography.button.copyWith(
                    color: isDisabled ? const Color(0xFF9E95AD) : (textColor ?? AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
