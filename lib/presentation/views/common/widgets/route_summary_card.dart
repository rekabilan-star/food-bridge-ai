import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Reusable card displaying Road-Aware Route Distance, ETA, and Source attribution.
class RouteSummaryCard extends StatelessWidget {
  final double distanceKm;
  final int durationMins;
  final String routingSource;
  final bool isLoading;
  final DateTime? lastUpdated;
  final VoidCallback? onRefresh;

  const RouteSummaryCard({
    super.key,
    required this.distanceKm,
    required this.durationMins,
    this.routingSource = "OSRM",
    this.isLoading = false,
    this.lastUpdated,
    this.onRefresh,
  });

  String _formatLastUpdated() {
    if (lastUpdated == null) return "Live";
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 45) return "Updated just now";
    if (diff.inMinutes < 60) return "Updated ${diff.inMinutes}m ago";
    return "Updated recently";
  }

  @override
  Widget build(BuildContext context) {
    final bool isRoadAware = routingSource.toUpperCase() == "OSRM";
    final bool hasRoute = distanceKm > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Distance badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      hasRoute ? "${distanceKm.toStringAsFixed(1)} km" : "Calculating...",
                      style: AppTypography.subsectionHeading.copyWith(fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    if (hasRoute)
                      Text(
                        "• ~${durationMins > 0 ? durationMins : 1} min${durationMins == 1 ? '' : 's'}",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isRoadAware
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        isRoadAware ? "Road Route (OSRM)" : "Direct Estimate",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isRoadAware ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatLastUpdated(),
                        style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading spinner or Refresh action
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
              tooltip: "Refresh route",
              onPressed: onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
