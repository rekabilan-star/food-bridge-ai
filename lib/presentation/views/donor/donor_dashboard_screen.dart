import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../../data/repositories/emergency_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/ui_utils.dart';
import 'donate_food_screen.dart';
import 'qr_display_screen.dart';
import '../common/donation_tracking_screen.dart';
import '../common/verification_scanner_screen.dart';
import '../common/donation_history_screen.dart';
import '../common/profile_screen.dart';
import '../common/widgets/stat_card.dart';
import '../common/widgets/donation_card.dart';
import '../common/widgets/donor_badges_card.dart';
import '../common/widgets/user_profile_modal.dart';
import '../common/widgets/floating_bottom_nav.dart';
import '../common/widgets/shimmer_loading.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/section_heading.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import '../chat/chat_list_screen.dart';

import 'dart:async';

class DonorDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const DonorDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  late int _currentNavIndex;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final dVM = context.read<DonationViewModel>();
    final eVM = context.read<EmergencyViewModel>();
    final nVM = context.read<NotificationViewModel>();

    dVM.initSocket();
    nVM.initSocketListeners();
    await Future.wait([
      dVM.fetchDonorDonations(),
      eVM.fetchActiveRequests(),
      nVM.fetchNotifications(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final donationViewModel = context.watch<DonationViewModel>();
    final emergencyViewModel = context.watch<EmergencyViewModel>();
    final userVM = context.watch<AuthViewModel>();
    final user = userVM.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _currentNavIndex,
              children: [
                // TAB 0: Clean Essential Donor Dashboard
                RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // 1. Clean App Bar
                      _buildCleanAppBar(context, user?.name ?? "Donor"),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2. Primary Action Hero Banner (+ Donate Food)
                              _buildPrimaryDonateHero(context).animate().fadeIn(duration: 400.ms),

                              AppSpacing.vGapLg,

                              // 3. Core Impact Statistics Row (3 StatCards, overflow-free)
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      value: "${donationViewModel.donations.length}",
                                      label: "Donations",
                                      icon: Icons.card_giftcard_rounded,
                                      iconColor: AppColors.primary,
                                    ),
                                  ),
                                  AppSpacing.hGapSm,
                                  Expanded(
                                    child: StatCard(
                                      value: "${donationViewModel.donations.fold<int>(0, (sum, d) => sum + d.membersServed)}",
                                      label: "Meals Shared",
                                      icon: Icons.restaurant_rounded,
                                      iconColor: AppColors.secondary,
                                    ),
                                  ),
                                  AppSpacing.hGapSm,
                                  Expanded(
                                    child: StatCard(
                                      value: user?.averageRating != null && user!.averageRating > 0
                                          ? user.averageRating.toStringAsFixed(1)
                                          : "${donationViewModel.donations.where((d) => d.status == 'completed').length * 10}",
                                      label: "Impact Score",
                                      icon: Icons.star_rounded,
                                      iconColor: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.vGapLg,

                              // 4. Donor Achievement Badges
                              const DonorBadgesCard(totalMeals: 85).animate().fadeIn(delay: 200.ms),

                              AppSpacing.vGapXl,

                              // 5. Urgent Emergency Rescue Requests (if active)
                              if (emergencyViewModel.requests.isNotEmpty) ...[
                                _buildEmergencySection(emergencyViewModel),
                                AppSpacing.vGapXl,
                              ],

                              // 6. Recent Active Donations Feed
                              SectionHeading(
                                title: "Active Donations",
                                actionText: "View All",
                                onActionTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                                  );
                                },
                              ),
                              AppSpacing.vGapSm,

                              // Donations List with progress steppers
                              donationViewModel.isLoading && donationViewModel.donations.isEmpty
                                  ? const ShimmerListLoading(count: 3)
                                  : donationViewModel.donations.isEmpty
                                      ? _buildEmptyState()
                                      : _buildDonationsList(donationViewModel.donations),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 1: History
                const DonationHistoryScreen(),

                // TAB 2: Chat
                const ChatListScreen(),

                // TAB 3: Profile
                const ProfileScreen(),
              ],
            ),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
              onAddTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonateFoodScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanAppBar(BuildContext context, String userName) {
    final nVM = context.watch<NotificationViewModel>();

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      surfaceTintColor: AppColors.surfaceLight,
      backgroundColor: AppColors.surfaceLight,
      title: Text(
        "FoodBridge AI",
        style: AppTypography.pageTitle.copyWith(
          color: AppColors.primary,
          fontSize: 20,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 24, color: AppColors.textPrimary),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (nVM.unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScannerScreen())),
          tooltip: "Verify Certificate",
        ),
        AppSpacing.hGapXs,
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22, color: AppColors.textPrimary),
          onPressed: () {
            context.read<AuthViewModel>().logout();
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
          tooltip: "Logout",
        ),
        GestureDetector(
          onTap: () => UserProfileModal.show(context),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : "D",
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        AppSpacing.hGapMd,
      ],
    );
  }

  Widget _buildPrimaryDonateHero(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Share Surplus Food",
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  "Instant dispatch to verified NGO rescue drivers nearby.",
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                AppSpacing.vGapBase,
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DonateFoodScreen()));
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    "DONATE FOOD NOW",
                    style: AppTypography.button.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          const Icon(Icons.volunteer_activism_rounded, size: 56, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(EmergencyViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 18),
            AppSpacing.hGapXs,
            Text(
              "URGENT RESCUE ALERTS",
              style: AppTypography.badge.copyWith(
                color: AppColors.warning,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.requests.length,
            itemBuilder: (context, index) {
              final request = viewModel.requests[index];
              return GestureDetector(
                onTap: () => _showEmergencyModal(context, request),
                child: Container(
                  width: 270,
                  margin: const EdgeInsets.only(right: 12),
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.2),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: AppTypography.subsectionHeading.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.hGapXs,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderXs,
                            ),
                            child: Text(
                              request.priority,
                              style: AppTypography.badge.copyWith(
                                color: AppColors.warning,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        request.reason,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _showEmergencyModal(context, request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 32),
                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                          ),
                          child: Text(
                            "HELP NOW",
                            style: AppTypography.badge.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEmergencyModal(BuildContext context, EmergencyRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.sheetTop,
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.base,
            bottom: MediaQuery.of(bottomSheetContext).padding.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 24),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "URGENT RESCUE ALERT",
                          style: AppTypography.badge.copyWith(
                            color: AppColors.warning,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          request.ngoName ?? "Emergency Relief Team",
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      request.priority,
                      style: AppTypography.badge.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapBase,
              Text(
                request.title,
                style: AppTypography.sectionHeading,
              ),
              AppSpacing.vGapSm,
              Text(
                request.reason,
                style: AppTypography.bodyMedium,
              ),
              AppSpacing.vGapLg,
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildModalDetailRow(Icons.restaurant_rounded, "Food Type", request.foodType.isNotEmpty ? request.foodType : "Cooked Meals"),
                    const Divider(height: 16),
                    _buildModalDetailRow(Icons.groups_rounded, "Meals Needed", "${request.requiredMembers} Servings"),
                    const Divider(height: 16),
                    _buildModalDetailRow(Icons.location_on_rounded, "Delivery Location", request.address),
                  ],
                ),
              ),
              AppSpacing.vGapXl,
              PrimaryButton(
                text: "DONATE FOOD FOR THIS RESCUE",
                icon: Icons.volunteer_activism_rounded,
                onPressed: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonateFoodScreen(emergencyRequest: request),
                    ),
                  );
                },
              ),
              AppSpacing.vGapSm,
              SecondaryButton(
                text: "PLEDGE IMMEDIATE SUPPORT",
                icon: Icons.check_circle_outline_rounded,
                onPressed: () async {
                  Navigator.pop(bottomSheetContext);
                  UIUtils.showLoadingDialog(context);
                  final success = await context.read<EmergencyViewModel>().fulfillRequest(request.id);
                  if (context.mounted) {
                    Navigator.pop(context); // pop loading dialog
                    if (success) {
                      UIUtils.showSuccessDialog(
                        context,
                        "Thank you! Your emergency pledge has been recorded. The emergency team has been notified.",
                        onOk: () => _refreshData(),
                      );
                    } else {
                      UIUtils.showErrorDialog(
                        context,
                        context.read<EmergencyViewModel>().errorMessage ?? "Failed to register response. Please try again.",
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        AppSpacing.hGapSm,
        Text(
          label,
          style: AppTypography.caption,
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationsList(List donations) {
    final user = context.watch<AuthViewModel>().user;
    final double userLat = user?.latitude ?? 0;
    final double userLng = user?.longitude ?? 0;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donations.length > 5 ? 5 : donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        final status = StatusUtils.formatStatusLabel(donation.status);

        final double donorLat = donation.latitude != 0 ? donation.latitude : userLat;
        final double donorLng = donation.longitude != 0 ? donation.longitude : userLng;
        final double targetLat = donation.ngoLat ?? 0;
        final double targetLng = donation.ngoLng ?? 0;

        String distText = "Distance unavailable";
        String etaVal = status == 'Pending' ? '15 mins' : '10 mins';

        if (donorLat != 0 && donorLng != 0 && targetLat != 0 && targetLng != 0) {
          final meters = Geolocator.distanceBetween(donorLat, donorLng, targetLat, targetLng);
          distText = "${(meters / 1000).toStringAsFixed(1)} km away";
          final mins = ((meters / 1000) / 30 * 60).round();
          etaVal = "${mins > 0 ? mins : 5} mins";
        } else if (donorLat != 0 && donorLng != 0) {
          distText = "Pickup ready";
        }

        final diff = DateTime.now().difference(donation.preparedTime.toLocal());
        String timeAgoVal = "Recently";
        if (diff.inSeconds < 60) {
          timeAgoVal = "Just now";
        } else if (diff.inMinutes < 60) {
          timeAgoVal = "${diff.inMinutes} mins ago";
        } else if (diff.inHours < 24) {
          timeAgoVal = "${diff.inHours} hrs ago";
        }

        return DonationCard(
          title: donation.foodName,
          subtitle: "${donation.membersServed} Served • ${donation.checklist.foodType.isNotEmpty ? donation.checklist.foodType : (donation.category.isNotEmpty ? donation.category : 'Cooked Meal')}",
          status: status,
          timeAgo: timeAgoVal,
          etaText: etaVal,
          distanceText: distText,
          imageUrl: donation.imageUrl,
          onTrackTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)));
          },
          onTap: () => _showOptions(context, donation),
        ).animate().fadeIn(duration: 350.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 300))).slideY(begin: 0.08, end: 0, duration: 350.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 300)), curve: Curves.easeOut);
      },
    );
  }

  void _showOptions(BuildContext context, dynamic donation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: AppSpacing.paddingXl,
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.sheetTop,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
            ),
            AppSpacing.vGapBase,
            Text(
              "Donation Options",
              style: AppTypography.sectionHeading,
            ),
            AppSpacing.vGapBase,
            if (donation.status == 'waiting') ...[
              _buildModalTile(context, "Edit Details", Icons.edit_outlined, AppColors.primary, () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DonateFoodScreen(donation: donation)));
              }),
              AppSpacing.vGapSm,
              _buildModalTile(context, "Cancel Listing", Icons.delete_outline_rounded, AppColors.error, () {
                Navigator.pop(bottomSheetContext);
                _showDeleteConfirmDialog(context, donation);
              }),
            ],
            if (donation.status != 'waiting')
              _buildModalTile(context, "Track Live Map", Icons.map_outlined, AppColors.primary, () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)));
              }),
            AppSpacing.vGapSm,
            _buildModalTile(context, "Handover QR Code", Icons.qr_code_2_rounded, AppColors.warning, () {
              Navigator.pop(bottomSheetContext);
              Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(donation: donation)));
            }),
            AppSpacing.vGapBase,
          ],
        ),
      ),
    );
  }

  Widget _buildModalTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                AppSpacing.hGapMd,
                Text(
                  title,
                  style: AppTypography.subsectionHeading.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, dynamic donation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        title: Text("Cancel Donation?", style: AppTypography.sectionHeading),
        content: Text(
          "This action will remove your donation listing.",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "KEEP",
              style: AppTypography.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<DonationViewModel>().deleteDonation(donation.id);
              if (success && context.mounted) {
                _refreshData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              minimumSize: const Size(90, 40),
            ),
            child: Text(
              "CANCEL LISTING",
              style: AppTypography.button.copyWith(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: AppSpacing.paddingXl,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: AppShadows.subtle,
      ),
      child: EmptyState(
        icon: Icons.volunteer_activism_rounded,
        title: "No Active Donations",
        message: "Tap 'DONATE FOOD NOW' above to share surplus food with nearby NGO partners.",
        padding: EdgeInsets.zero,
      ),
    );
  }
}
