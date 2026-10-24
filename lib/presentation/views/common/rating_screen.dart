import 'package:flutter/material.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/modern_text_field.dart';
import 'widgets/primary_button.dart';

class RatingScreen extends StatefulWidget {
  final String donationId;
  final String toUserId;
  final String toUserName;

  const RatingScreen({
    super.key,
    required this.donationId,
    required this.toUserId,
    required this.toUserName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitRating() async {
    if (_rating == 0) {
      UIUtils.showErrorDialog(context, "Please select a star rating");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await RatingRepository().submitRating(
        donationId: widget.donationId,
        toUserId: widget.toUserId,
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      if (mounted) {
        UIUtils.showSuccessDialog(context, "Thank you for your feedback!", onOk: () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Rate Experience"),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            AppSpacing.vGapLg,
            // Recipient Profile Avatar
            CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.volunteer_activism_rounded, size: 46, color: AppColors.primary),
            ),
            AppSpacing.vGapBase,
            Text(
              "How was your experience with",
              style: AppTypography.caption,
            ),
            AppSpacing.vGapXs,
            Text(
              widget.toUserName,
              style: AppTypography.sectionHeading.copyWith(fontSize: 20),
            ),
            AppSpacing.vGapXl,

            // Interactive Star Rating Container
            Container(
              padding: AppSpacing.paddingBase,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: AppColors.border, width: 1.0),
                boxShadow: AppShadows.subtle,
              ),
              child: Column(
                children: [
                  Text(
                    _rating == 0
                        ? "Tap stars to rate"
                        : _rating == 5
                            ? "Outstanding! ⭐⭐⭐⭐⭐"
                            : _rating >= 4
                                ? "Very Good! ⭐⭐⭐⭐"
                                : _rating >= 3
                                    ? "Good! ⭐⭐⭐"
                                    : "Needs Improvement",
                    style: AppTypography.captionBold.copyWith(
                      color: _rating >= 4 ? AppColors.success : (_rating >= 3 ? AppColors.warning : AppColors.textSecondary),
                    ),
                  ),
                  AppSpacing.vGapSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 38,
                        icon: Icon(
                          starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: starValue <= _rating ? AppColors.warning : AppColors.border,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                      );
                    }),
                  ),
                ],
              ),
            ),

            AppSpacing.vGapXl,

            ModernTextField(
              controller: _reviewController,
              label: "Write a review (optional)",
              hint: "What did you like or what can be improved?",
              prefixIcon: Icons.rate_review_outlined,
              maxLines: 4,
            ),

            AppSpacing.vGapXxl,

            PrimaryButton(
              text: "SUBMIT FEEDBACK",
              isLoading: _isLoading,
              onPressed: _submitRating,
            ),
          ],
        ),
      ),
    );
  }
}
