import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DonationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String timeAgo;
  final IconData icon;
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
    this.etaText,
    this.distanceText,
    this.onTap,
    this.onTrackTap,
    this.onCallTap,
  });

  int _getStatusStepIndex() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'available':
      case 'requested':
        return 0;
      case 'accepted':
      case 'matched':
      case 'assigned':
        return 1;
      case 'picked up':
      case 'in_progress':
      case 'en_route':
        return 2;
      case 'completed':
      case 'claimed':
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;

    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('completed') || lowerStatus.contains('claimed') || lowerStatus.contains('delivered')) {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
    } else if (lowerStatus.contains('picked') || lowerStatus.contains('progress') || lowerStatus.contains('route')) {
      statusBgColor = const Color(0xFFF3E5F5);
      statusTextColor = AppColors.primary;
    } else if (lowerStatus.contains('accepted') || lowerStatus.contains('matched') || lowerStatus.contains('assigned')) {
      statusBgColor = const Color(0xFFE3F2FD);
      statusTextColor = Colors.blue.shade800;
    } else {
      statusBgColor = const Color(0xFFFFF3E0);
      statusTextColor = Colors.orange.shade900;
    }

    final stepIndex = _getStatusStepIndex();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Real-Time Progress Stepper (Swiggy / Flipkart Style)
                _buildProgressStepper(stepIndex),

                if (etaText != null || distanceText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (etaText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                "ETA: $etaText",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (etaText != null && distanceText != null)
                        const SizedBox(width: 8),
                      if (distanceText != null)
                        Row(
                          children: [
                            Icon(Icons.near_me_rounded, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              distanceText!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      const Spacer(),
                      if (onTrackTap != null)
                        InkWell(
                          onTap: onTrackTap,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  "Track Live",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
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

  Widget _buildProgressStepper(int currentStep) {
    final steps = ["Requested", "Matched", "En Route", "Delivered"];

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
                            color: isPassed ? AppColors.primary : Colors.grey.shade300,
                            border: isCurrent ? Border.all(color: AppColors.accent, width: 3) : null,
                          ),
                          child: isPassed
                              ? const Icon(Icons.check, size: 8, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: index < currentStep ? AppColors.primary : Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isPassed ? AppColors.textPrimary : Colors.grey.shade400,
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

