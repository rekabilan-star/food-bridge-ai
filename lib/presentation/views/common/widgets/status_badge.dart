import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/ui_utils.dart';

/// Design System Status Badge for FoodBridge AI.
/// Renders an accessible, soft-tinted pill badge for donation and entity statuses.
class StatusBadge extends StatelessWidget {
  final String? status;
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    this.status,
    this.label,
    this.color,
    this.backgroundColor,
    this.icon,
    this.showDot = false,
  });

  IconData _resolveIcon(String? rawStatus) {
    if (rawStatus == null) return AppIcons.waiting;
    final lower = rawStatus.toLowerCase();
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('claimed')) {
      return AppIcons.delivered;
    }
    if (lower.contains('picked') || lower.contains('route') || lower.contains('transit') || lower.contains('arrived')) {
      return AppIcons.transit;
    }
    if (lower.contains('accepted') || lower.contains('matched') || lower.contains('assigned')) {
      return AppIcons.check;
    }
    if (lower.contains('cancel') || lower.contains('reject')) {
      return AppIcons.close;
    }
    if (lower.contains('expired')) {
      return Icons.timer_off_rounded;
    }
    return AppIcons.waiting;
  }

  Color _resolveColor(String? rawStatus) {
    if (rawStatus == null) return AppColors.warning;
    final lower = rawStatus.toLowerCase();
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('claimed')) {
      return AppColors.success;
    }
    if (lower.contains('picked') || lower.contains('route') || lower.contains('transit') || lower.contains('arrived')) {
      return AppColors.primary;
    }
    if (lower.contains('accepted') || lower.contains('matched') || lower.contains('assigned')) {
      return AppColors.info;
    }
    if (lower.contains('cancel') || lower.contains('reject') || lower.contains('expired')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveText = label ?? StatusUtils.formatStatusLabel(status);
    final effectiveColor = color ?? _resolveColor(status);
    final effectiveBg = backgroundColor ?? effectiveColor.withValues(alpha: 0.12);
    final effectiveIcon = icon ?? (showDot ? null : _resolveIcon(status));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: AppRadius.borderFull,
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 1),
          ] else if (effectiveIcon != null) ...[
            Icon(
              effectiveIcon,
              size: 13,
              color: effectiveColor,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              effectiveText,
              style: AppTypography.badge.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
