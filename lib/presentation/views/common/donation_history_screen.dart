import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'donation_tracking_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/donation_card.dart';
import 'widgets/modern_text_field.dart';
import 'widgets/shimmer_loading.dart';
import 'widgets/empty_state.dart';
import '../../../core/utils/ui_utils.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonorDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dVM = context.watch<DonationViewModel>();
    final donations = dVM.donations;

    final filteredDonations = donations.where((d) {
      final matchesSearch = d.foodName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedFilter == "All") return matchesSearch;
      if (_selectedFilter == "Active") return matchesSearch && (d.status == 'waiting' || d.status == 'accepted');
      if (_selectedFilter == "Completed") return matchesSearch && d.status == 'completed';
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(
        title: "Donation History",
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DonationViewModel>().fetchDonorDonations();
        },
        color: AppColors.primary,
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  ModernTextField(
                    label: "Search",
                    hint: "Search history by food name or address...",
                    prefixIcon: Icons.search_rounded,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  AppSpacing.vGapMd,
                  Row(
                    children: [
                      _buildFilterChip("All"),
                      AppSpacing.hGapSm,
                      _buildFilterChip("Active"),
                      AppSpacing.hGapSm,
                      _buildFilterChip("Completed"),
                    ],
                  ),
                ],
              ),
            ),

            // Donations List Stream / ListView
            Expanded(
              child: dVM.isLoading && donations.isEmpty
                  ? const Padding(
                      padding: AppSpacing.pagePadding,
                      child: ShimmerListLoading(count: 4),
                    )
                  : filteredDonations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: filteredDonations.length,
                          itemBuilder: (context, index) {
                            final donation = filteredDonations[index];
                            final diff = DateTime.now().difference(donation.preparedTime.toLocal());
                            String timeAgoVal = "Recently";
                            if (diff.inSeconds < 60) {
                              timeAgoVal = "Just now";
                            } else if (diff.inMinutes < 60) {
                              timeAgoVal = "${diff.inMinutes} mins ago";
                            } else if (diff.inHours < 24) {
                              timeAgoVal = "${diff.inHours} hrs ago";
                            } else if (diff.inDays < 7) {
                              timeAgoVal = "${diff.inDays} days ago";
                            }

                            return DonationCard(
                              title: donation.foodName,
                              subtitle: "${donation.membersServed} Served • ${donation.category}",
                              status: StatusUtils.formatStatusLabel(donation.status),
                              timeAgo: timeAgoVal,
                              imageUrl: donation.imageUrl,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DonationTrackingScreen(donationId: donation.id),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.08, end: 0);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: "No Donations Found",
        message: "Your donation activity and records will appear here.",
      ),
    );
  }
}
