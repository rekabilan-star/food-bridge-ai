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
import '../../../core/utils/ui_utils.dart';
import 'donate_food_screen.dart';
import 'qr_display_screen.dart';
import '../common/donation_tracking_screen.dart';
import '../common/donation_history_screen.dart';
import '../common/profile_screen.dart';
import '../common/widgets/stat_card.dart';
import '../common/widgets/donation_card.dart';
import '../common/widgets/donor_badges_card.dart';
import '../common/widgets/user_profile_modal.dart';
import '../common/widgets/floating_bottom_nav.dart';
import '../common/widgets/shimmer_loading.dart';
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2. Primary Action Hero Banner (+ Donate Food)
                              _buildPrimaryDonateHero(context).animate().fadeIn(duration: 400.ms),

                              const SizedBox(height: 20),

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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StatCard(
                                      value: "${donationViewModel.donations.fold<int>(0, (sum, d) => sum + d.membersServed)}",
                                      label: "Meals Shared",
                                      icon: Icons.restaurant_rounded,
                                      iconColor: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StatCard(
                                      value: user?.averageRating != null && user!.averageRating > 0 
                                          ? user.averageRating.toStringAsFixed(1) 
                                          : "${donationViewModel.donations.where((d) => d.status == 'completed').length * 10}",
                                      label: "Impact Score",
                                      icon: Icons.star_rounded,
                                      iconColor: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 4. Donor Achievement Badges
                              const DonorBadgesCard(totalMeals: 85).animate().fadeIn(delay: 200.ms),

                              const SizedBox(height: 24),

                              // 4. Urgent Emergency Rescue Requests (if active)
                              if (emergencyViewModel.requests.isNotEmpty) ...[
                                _buildEmergencySection(emergencyViewModel),
                                const SizedBox(height: 24),
                              ],

                              // 5. Recent Active Donations Feed
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Active Donations",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                                      );
                                    },
                                    child: const Text(
                                      "View All",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

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
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      title: const Text(
        "FoodBridge AI",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: -0.5,
          color: AppColors.primary,
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
        const SizedBox(width: 4),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildPrimaryDonateHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7E22CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Share Surplus Food",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Instant dispatch to verified NGO rescue drivers nearby.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DonateFoodScreen()));
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("DONATE FOOD NOW", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.volunteer_activism_rounded, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(EmergencyViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 18),
            SizedBox(width: 6),
            Text(
              "URGENT RESCUE ALERTS",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.warning,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 135,
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              request.priority,
                              style: const TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.reason,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("HELP NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).padding.bottom + 24,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "URGENT RESCUE ALERT",
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          request.ngoName ?? "Emergency Relief Team",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.priority,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.reason,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DonateFoodScreen(emergencyRequest: request),
                      ),
                    );
                  },
                  icon: const Icon(Icons.volunteer_activism_rounded, color: Colors.white),
                  label: const Text(
                    "DONATE FOOD FOR THIS RESCUE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
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
                  icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                  label: const Text(
                    "PLEDGE IMMEDIATE SUPPORT",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
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
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 18),
            const Text(
              "Donation Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            if (donation.status == 'waiting') ...[
              _buildModalTile(context, "Edit Details", Icons.edit_outlined, AppColors.primary, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DonateFoodScreen(donation: donation)));
              }),
              const SizedBox(height: 10),
              _buildModalTile(context, "Cancel Listing", Icons.delete_outline_rounded, AppColors.error, () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, donation);
              }),
            ],
            if (donation.status != 'waiting')
              _buildModalTile(context, "Track Live Map", Icons.map_outlined, AppColors.primary, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)));
              }),
            const SizedBox(height: 10),
            _buildModalTile(context, "Handover QR Code", Icons.qr_code_2_rounded, AppColors.warning, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(donation: donation)));
            }),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildModalTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Donation?"),
        content: const Text("This action will remove your donation listing."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP")),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<DonationViewModel>().deleteDonation(donation.id);
              if (success) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
            ),
            child: const Text("CANCEL LISTING"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism_rounded, size: 44, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          const Text(
            "No Active Donations",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap 'DONATE FOOD NOW' above to share food",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
