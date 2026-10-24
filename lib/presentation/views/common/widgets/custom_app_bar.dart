import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_icons.dart';

/// Design System Consistent App Bar for FoodBridge AI.
/// Provides a standardized back button, centered title, and clean elevation-free styling.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: IconButton(
                  icon: const Icon(
                    AppIcons.back,
                    color: AppColors.textPrimary,
                    size: AppIcons.sizeSm,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                  padding: EdgeInsets.zero,
                  tooltip: 'Back',
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: AppTypography.pageTitle.copyWith(fontSize: 18),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
