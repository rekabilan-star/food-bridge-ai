import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/standard_card.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import '../common/widgets/app_loading_indicator.dart';
import '../common/widgets/empty_state.dart';
import 'donation_details_screen.dart';

class NgoDonationRequestsScreen extends StatefulWidget {
  const NgoDonationRequestsScreen({super.key});

  @override
  State<NgoDonationRequestsScreen> createState() => _NgoDonationRequestsScreenState();
}

class _NgoDonationRequestsScreenState extends State<NgoDonationRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dVM = context.read<DonationViewModel>();
      dVM.initSocket();
      dVM.fetchAvailableDonations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(
        title: "Nearby Opportunities",
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<DonationViewModel>().fetchAvailableDonations(
            search: _searchController.text.trim(),
          );
        },
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildAiBanner(),
            Expanded(
              child: Consumer<DonationViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading && viewModel.donations.isEmpty) {
                    return const AppLoadingIndicator(
                      message: "Searching for surplus food opportunities...",
                    );
                  }

                  if (viewModel.donations.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: EmptyState(
                          icon: Icons.explore_off_rounded,
                          title: "No Available Donations",
                          message: _searchController.text.isNotEmpty
                              ? "No food donations match '${_searchController.text}'. Try another search query."
                              : "No food rescue opportunities nearby within 20 KM at this moment. Check back soon!",
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    itemCount: viewModel.donations.length,
                    itemBuilder: (context, index) {
                      final donation = viewModel.donations[index];
                      return _buildOpportunityCard(donation)
                          .animate()
                          .fadeIn(
                            duration: 350.ms,
                            delay: Duration(milliseconds: (index * 50).clamp(0, 300)),
                          )
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 350.ms,
                            delay: Duration(milliseconds: (index * 50).clamp(0, 300)),
                            curve: Curves.easeOut,
                          );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: ModernTextField(
        controller: _searchController,
        label: "Search Surplus Food",
        hint: "Search by food name or category...",
        prefixIcon: Icons.search_rounded,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          context.read<DonationViewModel>().fetchAvailableDonations(search: value.trim());
        },
      ),
    );
  }

  Widget _buildAiBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.35),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Ranked by proximity within 20 KM, food freshness, and rescue urgency.",
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveFoodImageUrl(String? url) {
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

  Widget _buildOpportunityCard(DonationModel donation) {
    final rawUrl = donation.imageUrl;
    final resolvedUrl = _resolveFoodImageUrl(rawUrl);
    final isLocalFile = rawUrl.isNotEmpty && File(rawUrl).existsSync();

    final user = context.watch<AuthViewModel>().user;
    final double userLat = user?.latitude ?? 0;
    final double userLng = user?.longitude ?? 0;
    String distBadge = "WITHIN 20 KM";
    if (userLat != 0 && userLng != 0 && donation.latitude != 0 && donation.longitude != 0) {
      final meters = Geolocator.distanceBetween(userLat, userLng, donation.latitude, donation.longitude);
      distBadge = "${(meters / 1000).toStringAsFixed(1)} KM AWAY";
    }

    final isExpired = donation.isExpired;
    final bestBeforeFormatted = DateFormat('hh:mm a').format(donation.bestBeforeTime);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: StandardCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image + Title + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: AppColors.accent.withValues(alpha: 0.25),
                    child: resolvedUrl.isEmpty
                        ? const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 32)
                        : (isLocalFile
                            ? Image.file(File(rawUrl), fit: BoxFit.cover)
                            : Image.network(
                                resolvedUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 32),
                              )),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              distBadge,
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              isExpired ? "EXPIRED" : "BEST BEFORE $bestBeforeFormatted",
                              style: AppTypography.captionBold.copyWith(
                                color: isExpired ? AppColors.error : AppColors.warning,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        donation.foodName,
                        style: AppTypography.subsectionHeading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              donation.pickupAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 16),

            // Servings + Category Row
            Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  "Serves ${donation.membersServed} people",
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    donation.category,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Action Button
            if (isExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    "Food Donation Expired — Rescue Closed",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              PrimaryButton(
                text: "ACCEPT DONATION",
                icon: Icons.check_circle_rounded,
                isLoading: _isAccepting,
                onPressed: _isAccepting ? null : () => _acceptDonationDirectly(donation),
              ),
          ],
        ),
      ),
    );
  }

  void _acceptDonationDirectly(DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text("Accept Donation?", style: AppTypography.sectionHeading),
          ],
        ),
        content: Text(
          "Accept '${donation.foodName}' (${donation.membersServed} servings)?\n\nThis task will be assigned to your organization and added to your Rescue Control dashboard.",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          SecondaryButton(
            text: "CANCEL",
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: AppSpacing.xs),
          PrimaryButton(
            text: "CONFIRM",
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isAccepting = true);
              final viewModel = context.read<DonationViewModel>();
              final success = await viewModel.updateDonationStatus(donation.id, 'accepted');
              if (!mounted) return;
              setState(() => _isAccepting = false);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Donation Accepted! Navigating to Rescue Control..."),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(context, '/ngo-dashboard', (route) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.errorMessage ?? "Failed to accept donation"),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
