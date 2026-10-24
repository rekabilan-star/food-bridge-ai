import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// Design System Donation Card for FoodBridge AI.
/// Renders food donation status, thumbnail, stepper and live actions.
class DonationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String timeAgo;
  final IconData icon;
  final String? imageUrl;
  final String? etaText;
  final String? distanceText;
  final VoidCallback? onTap;
  final VoidCallback? onTrackTap;
  final VoidCallback? onCallTap;

  const DonationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.timeAgo,
    this.icon = Icons.restaurant_rounded,
    this.imageUrl,
    this.etaText,
    this.distanceText,
    this.onTap,
    this.onTrackTap,
    this.onCallTap,
  });

  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (File(trimmed).existsSync()) {
      return trimmed;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootServer$cleanPath';
  }

  String _formatCardStatus(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'waiting' || lower == 'available' || lower == 'pending') return 'Pending';
    if (lower == 'accepted' || lower == 'matched' || lower == 'assigned') return 'Accepted';
    if (lower.contains('picked') || lower.contains('transit') || lower.contains('route') || lower.contains('arrived')) return 'In Transit';
    if (lower.contains('complete') || lower.contains('claimed') || lower.contains('delivered')) return 'Completed';
    if (lower.contains('cancel') || lower.contains('reject')) return 'Cancelled';
    if (lower.contains('expired')) return 'Expired';
    return raw.toUpperCase();
  }

  int _getStatusStepIndex() {
    final lower = status.toLowerCase();
    if (lower == 'completed' || lower == 'claimed' || lower == 'delivered') {
      return 3;
    }
    if (lower == 'picked_up' ||
        lower == 'picked up' ||
        lower == 'on_the_way' ||
        lower == 'arrived' ||
        lower == 'in_transit' ||
        lower == 'en_route') {
      return 2;
    }
    if (lower == 'accepted' || lower == 'matched' || lower == 'assigned') {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final stepIndex = _getStatusStepIndex();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Thumbnail + Info + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadingThumbnail(),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.subsectionHeading,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: status, label: _formatCardStatus(status)),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Real-Time Stepper
                _buildProgressStepper(stepIndex),

                if (etaText != null || distanceText != null || onTrackTap != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (etaText != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      "ETA: $etaText",
                                      style: AppTypography.badge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (distanceText != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 2),
                                  Text(
                                    distanceText!,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (onTrackTap != null)
                        InkWell(
                          onTap: onTrackTap,
                          borderRadius: AppRadius.borderSm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Track Live",
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingThumbnail() {
    final resolved = _resolveImageUrl(imageUrl);
    final isLocal = imageUrl != null && imageUrl!.isNotEmpty && File(imageUrl!).existsSync();

    if (resolved.isNotEmpty || isLocal) {
      return ClipRRect(
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: 48,
          height: 48,
          color: AppColors.surfaceLight,
          child: isLocal
              ? Image.file(File(imageUrl!), fit: BoxFit.cover)
              : Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.accent,
                      child: Icon(icon, color: AppColors.primary, size: 22),
                    );
                  },
                ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadius.borderMd,
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildProgressStepper(int currentStep) {
    final steps = ["Waiting", "Accepted", "Picked Up", "Completed"];

    return Row(
      children: List.generate(steps.length, (index) {
        final isPassed = index <= currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed ? AppColors.primary : AppColors.border,
                            border: isCurrent
                                ? Border.all(color: AppColors.secondary, width: 3)
                                : null,
                          ),
                          child: isPassed
                              ? const Icon(Icons.check, size: 8, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: index < currentStep ? AppColors.primary : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isPassed ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
