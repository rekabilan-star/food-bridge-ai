import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'ngo_donation_requests_screen.dart';
import 'ngo_tracking_screen.dart';
import 'emergency_request_screen.dart';
import '../../../data/models/donation_model.dart';
import '../common/widgets/shimmer_loading.dart';
import '../common/widgets/donation_card.dart';
import '../common/widgets/user_profile_modal.dart';

import 'dart:async';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  @override
  void initState() {
    super.initState();
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
      dVM.fetchNgoAssignedDonations(),
      eVM.fetchActiveRequests(),
      nVM.fetchNotifications(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final viewModel = context.watch<DonationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.ngoColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(context, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. High Impact Emergency Broadcast Button
                    _buildEmergencyButton(context).animate().scale(duration: 350.ms),

                    const SizedBox(height: 16),

                    // 2. AI Surplus Food Explorer Card
                    _buildStatusCard(context).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    // 3. Operational Metrics Ribbon
                    _buildMetricsRibbon(viewModel).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 24),

                    // 4. Active Rescue Tasks Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text(
                              "Active Rescue Tasks",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.circle, color: Colors.green, size: 8),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()));
                          },
                          child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ngoColor)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Active Tasks List or Loading
                    if (viewModel.isLoading && viewModel.assignedDonations.isEmpty)
                      const ShimmerListLoading()
                    else if (viewModel.assignedDonations.isEmpty)
                      _buildEmptyState()
                    else
                      _buildActiveTasksList(viewModel.assignedDonations),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic user) {
    final nVM = context.watch<NotificationViewModel>();
    return SliverAppBar(
      floating: true,
      pinned: true,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      titleSpacing: 12,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.ngoColor, size: 22),
            SizedBox(width: 6),
            Text(
              "Rescue Control",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, color: AppColors.ngoColor),
            ),
          ],
        ),
      ),
      actions: [
        _buildAvailabilityToggle(context, user),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 24, color: AppColors.textPrimary),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (nVM.unreadCount > 0)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.pushNamed(context, '/chats'),
        ),
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
            backgroundColor: AppColors.ngoColor,
            child: Text(
              user?.name != null && user!.name.isNotEmpty ? user.name[0].toUpperCase() : "N",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildAvailabilityToggle(BuildContext context, dynamic user) {
    String status = user?.availabilityStatus ?? 'Available';
    Color color = status == 'Available' ? Colors.green : (status == 'Busy' ? Colors.orange : Colors.grey);

    return PopupMenuButton<String>(
      onSelected: (value) {},
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Available', child: Text("🟢 Available")),
        const PopupMenuItem(value: 'Busy', child: Text("🟡 Busy")),
        const PopupMenuItem(value: 'Offline', child: Text("🔴 Offline")),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 6),
            Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyRequestScreen())),
        icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
        label: const Text("BROADCAST EMERGENCY ALERT", style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w900, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEA2027),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ngoColor, Color(0xFF7E22CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ngoColor.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen())),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Explore Surplus Requests", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                      SizedBox(height: 2),
                      Text("AI matched 4 food pickups nearby", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRibbon(DonationViewModel vm) {
    return Row(
      children: [
        _buildMiniMetricCard("Active Pickups", "${vm.assignedDonations.length}", Icons.local_shipping_rounded, AppColors.ngoColor),
        const SizedBox(width: 10),
        _buildMiniMetricCard("Meals Rescued", "450+", Icons.restaurant_rounded, Colors.green),
        const SizedBox(width: 10),
        _buildMiniMetricCard("Avg Time", "12 mins", Icons.timer_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildMiniMetricCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTasksList(List<DonationModel> donations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        final status = donation.status == 'waiting' ? 'Pending' : (donation.status == 'picked_up' ? 'En Route' : donation.status);
        return DonationCard(
          title: donation.foodName,
          subtitle: "${donation.membersServed} Served • Pickup: ${donation.pickupAddress}",
          status: status,
          timeAgo: "10 mins ago",
          etaText: "ETA: 14 mins",
          distanceText: "2.4 km away",
          onTrackTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)));
          },
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)));
          },
        );
      },
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
          Icon(Icons.assignment_outlined, size: 44, color: AppColors.ngoColor.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          const Text(
            "No Active Rescue Tasks",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap 'Explore Surplus Requests' above to claim food",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
