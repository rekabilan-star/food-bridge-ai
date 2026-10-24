import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/status_badge.dart';

class QrDisplayScreen extends StatelessWidget {
  final DonationModel donation;
  const QrDisplayScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final cleanId = donation.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final displayId = cleanId.length >= 6
        ? cleanId.substring(cleanId.length - 6)
        : cleanId;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Pickup Verification"),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Show this QR to the NGO Partner",
                style: AppTypography.sectionHeading,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXs,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  "This ensures the food is safely handed over to the verified rescue team.",
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ),
              AppSpacing.vGapXl,

              // QR Box
              Container(
                padding: AppSpacing.paddingXl,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.borderXl,
                  border: Border.all(color: AppColors.border, width: 1.0),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: donation.qrCode ?? "No-QR",
                      version: QrVersions.auto,
                      size: 220.0,
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      donation.foodName,
                      style: AppTypography.subsectionHeading,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      "Donation ID: #$displayId",
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),

              AppSpacing.vGapXl,

              // Dynamic Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                    ),
                    AppSpacing.hGapMd,
                    Flexible(
                      child: Text(
                        "Waiting for NGO pickup scan...",
                        style: AppTypography.captionBold.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.vGapLg,
              StatusBadge(status: donation.status),
            ],
          ),
        ),
      ),
    );
  }
}
