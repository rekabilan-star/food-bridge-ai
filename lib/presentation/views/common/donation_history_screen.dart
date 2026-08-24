import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/donation_card.dart';
import 'widgets/modern_text_field.dart';
import 'widgets/shimmer_loading.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  ModernTextField(
                    label: "",
                    hint: "Search history...",
                    prefixIcon: Icons.search_rounded,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildFilterChip("All"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Active"),
                      const SizedBox(width: 8),
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
                      padding: EdgeInsets.all(20.0),
                      child: ShimmerListLoading(count: 4),
                    )
                  : filteredDonations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Selected donation: ${donation.foodName}")),
                                );
                              },
                            ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded, size: 54, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Donations Found",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your donation activity will appear here.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
