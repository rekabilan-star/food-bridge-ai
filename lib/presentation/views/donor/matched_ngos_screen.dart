import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/app_loading_indicator.dart';
import '../common/widgets/empty_state.dart';

class MatchedNgosScreen extends StatefulWidget {
  final String? donationId;
  const MatchedNgosScreen({super.key, this.donationId});

  @override
  State<MatchedNgosScreen> createState() => _MatchedNgosScreenState();
}

class _MatchedNgosScreenState extends State<MatchedNgosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.donationId != null && widget.donationId!.isNotEmpty) {
        context.read<DonationViewModel>().fetchDonationRecommendations(widget.donationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "AI Rescue Matching",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (widget.donationId != null && widget.donationId!.isNotEmpty) {
                context.read<DonationViewModel>().fetchDonationRecommendations(widget.donationId!);
              }
            },
          ),
        ],
      ),
      body: Consumer<DonationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildLoadingState();
          }

          if (viewModel.recommendations.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFreshnessBanner(viewModel.currentDonation),
              Expanded(child: _buildNgoList(viewModel.recommendations)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: AppLoadingIndicator(
        message: "AI evaluating distance, urgency,\nand NGO capacity for the best rescue mission...",
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: EmptyState(
          icon: Icons.psychology_outlined,
          title: "No Immediate Matches",
          message: "We couldn't find active NGOs within 15km matching high-confidence criteria. Your donation remains visible to all eligible partners in the public rescue pool.",
          actionText: "BACK TO DASHBOARD",
          onActionPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildFreshnessBanner(DonationModel? donation) {
    if (donation == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final total = donation.bestBeforeTime.difference(donation.preparedTime).inMinutes;
    final left = donation.bestBeforeTime.difference(now).inMinutes;
    final double freshness = (left / (total > 0 ? total : 1)).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: AppSpacing.pagePadding,
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: freshness < 0.3
              ? [AppColors.error, const Color(0xFFB91C1C)]
              : AppColors.primaryGradient,
        ),
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DONATION FRESHNESS",
                    style: AppTypography.badge.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    "${(freshness * 100).toInt()}% Quality Remaining",
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Icon(
                freshness < 0.3 ? Icons.warning_amber_rounded : Icons.eco_rounded,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              value: freshness,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            freshness < 0.3
                ? "Critical: Finding fastest rescue possible"
                : "Healthy shelf life: Optimizing for best partner",
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildNgoList(List<Map<String, dynamic>> ngos) {
    return ListView.builder(
      padding: AppSpacing.pageHorizontal,
      itemCount: ngos.length,
      itemBuilder: (context, index) {
        final ngo = ngos[index];
        final double score = (ngo['score'] ?? 0).toDouble();
        final int confidence = ngo['confidence'] ?? 0;
        final bool isTopMatch = index == 0 && score > 70;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: isTopMatch ? AppColors.primary : AppColors.border,
              width: isTopMatch ? 2.0 : 1.0,
            ),
            boxShadow: isTopMatch ? AppShadows.card : AppShadows.subtle,
          ),
          child: Column(
            children: [
              if (isTopMatch)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Text(
                    "AI RECOMMENDED TOP MATCH",
                    textAlign: TextAlign.center,
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              _buildNgoHeader(ngo, score, !isTopMatch),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: AppSpacing.paddingBase,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsRow(ngo),
                    AppSpacing.vGapBase,
                    _buildAiExplanation(ngo['explanation'] ?? '', confidence),
                    AppSpacing.vGapBase,
                    _buildReasonsList(ngo['reasons'] as List? ?? []),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 120).ms).slideY(begin: 0.08, end: 0);
      },
    );
  }

  Widget _buildNgoHeader(Map<String, dynamic> ngo, double score, bool roundTop) {
    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: roundTop ? const BorderRadius.vertical(top: Radius.circular(16)) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngo['name'] ?? 'NGO Partner',
                  style: AppTypography.subsectionHeading,
                ),
                Text(
                  ngo['availability'] == 'Available' ? 'Ready for Pickup' : 'Busy (On Route)',
                  style: AppTypography.captionBold.copyWith(
                    fontSize: 11,
                    color: ngo['availability'] == 'Available' ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          _buildScoreBadge(score),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: score / 100,
                backgroundColor: AppColors.border,
                color: _getScoreColor(score),
                strokeWidth: 4,
              ),
            ),
            Text(
              score.toInt().toString(),
              style: AppTypography.captionBold.copyWith(
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        Text(
          "MATCH",
          style: AppTypography.badge.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> ngo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem(Icons.location_on_outlined, "${ngo['distanceKm']} km", "Distance"),
        _buildMetricItem(Icons.access_time_rounded, ngo['etaText'] ?? '--', "Est. Arrival"),
        _buildMetricItem(Icons.verified_user_outlined, "${confidencePercentage(ngo)}%", "Confidence"),
      ],
    );
  }

  int confidencePercentage(Map<String, dynamic> ngo) => ngo['confidence'] ?? 0;

  Widget _buildMetricItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        AppSpacing.vGapXs,
        Text(val, style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildAiExplanation(String text, int confidence) {
    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.info, size: 16),
              AppSpacing.hGapSm,
              Text(
                "AI Analysis ($confidence% match confidence)",
                style: AppTypography.captionBold.copyWith(color: AppColors.info),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsList(List reasons) {
    return Column(
      children: reasons.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                r.toString(),
                style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.info;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
