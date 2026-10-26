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
  final RatingRepository? repository;

  const RatingScreen({
    super.key,
    required this.donationId,
    required this.toUserId,
    required this.toUserName,
    this.repository,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = false;

  final List<String> _quickTags = [
    "Punctual Handover",
    "High Food Quality",
    "Accurate Portion",
    "Courteous Partner",
    "Smooth Coordination",
  ];
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _toggleQuickTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }

      // Sync tags into review text if desired
      final currentText = _reviewController.text.trim();
      final existingTagsText = _selectedTags.join(', ');
      if (currentText.isEmpty || _quickTags.any((t) => currentText.contains(t))) {
        _reviewController.text = existingTagsText;
      }
    });
  }

  void _submitRating() async {
    if (_rating == 0) {
      UIUtils.showErrorDialog(context, "Please select a star rating (1-5 stars) to proceed.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = widget.repository ?? RatingRepository();
      await repo.submitRating(
        donationId: widget.donationId,
        toUserId: widget.toUserId,
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      if (mounted) {
        UIUtils.showSuccessDialog(
          context,
          "Thank you for your rating! Your feedback strengthens the rescue network.",
          onOk: () {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            // Recipient Profile Card
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingBase,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderXl,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.subtle,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      widget.toUserName.isNotEmpty ? widget.toUserName[0].toUpperCase() : 'U',
                      style: AppTypography.pageTitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  AppSpacing.vGapBase,
                  Text(
                    widget.toUserName,
                    style: AppTypography.sectionHeading.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderFull,
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      "COMPLETED RESCUE MISSION",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.vGapXl,

            // Interactive Star Rating Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderXl,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Text(
                    _rating == 0
                        ? "Tap stars to rate"
                        : _rating == 5
                            ? "Outstanding! ⭐⭐⭐⭐⭐"
                            : _rating == 4
                                ? "Great Collaboration! ⭐⭐⭐⭐"
                                : _rating == 3
                                    ? "Good Effort ⭐⭐⭐"
                                    : _rating == 2
                                        ? "Fair — Needed Coordination ⭐⭐"
                                        : "Needs Improvement ⭐",
                    style: AppTypography.captionBold.copyWith(
                      fontSize: 13,
                      color: _rating >= 4
                          ? AppColors.success
                          : (_rating >= 3 ? AppColors.warning : (_rating > 0 ? AppColors.error : AppColors.textSecondary)),
                    ),
                  ),
                  AppSpacing.vGapMd,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        icon: Icon(
                          starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: starValue <= _rating ? const Color(0xFFF59E0B) : AppColors.border,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                        tooltip: "$starValue Star",
                      );
                    }),
                  ),
                ],
              ),
            ),

            AppSpacing.vGapXl,

            // Quick Feedback Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Highlights",
                style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
              ),
            ),
            AppSpacing.vGapSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  showCheckmark: false,
                  onSelected: (_) => _toggleQuickTag(tag),
                );
              }).toList(),
            ),

            AppSpacing.vGapXl,

            ModernTextField(
              controller: _reviewController,
              label: "Written Review (Optional)",
              hint: "Share details regarding food quality, packaging, punctuality, or communication...",
              prefixIcon: Icons.rate_review_outlined,
              maxLines: 4,
            ),

            AppSpacing.vGapXxl,

            PrimaryButton(
              text: "SUBMIT FEEDBACK",
              isLoading: _isLoading,
              onPressed: _submitRating,
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }
}
