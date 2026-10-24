import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import 'ngo_donation_requests_screen.dart';
import 'ngo_tracking_screen.dart';
import 'donation_details_screen.dart';
import 'emergency_request_screen.dart';
import '../../../data/models/donation_model.dart';
import '../common/widgets/donation_card.dart';
import '../common/widgets/stat_card.dart';
import '../common/widgets/section_heading.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/app_loading_indicator.dart';
import '../common/widgets/user_profile_modal.dart';

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

    dVM.initSocket();
    nVM.initSocketListeners();
    await Future.wait([
      dVM.fetchNgoAssignedDonations(),
      dVM.fetchAvailableDonations(),
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
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(context, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 0. Welcome Header & Availability Toggle
                    _buildWelcomeHeader(context, user).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.md),

                    // 1. High Impact Emergency Broadcast Action
                    _buildEmergencyBroadcastCard(context).animate().scale(duration: 350.ms),

                    const SizedBox(height: AppSpacing.md),

                    // 2. AI Surplus Food Explorer Card
                    _buildSurplusExplorerCard(context, viewModel).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // 3. Operational Metrics
                    _buildMetricsSection(viewModel).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: AppSpacing.xl),

                    // 4. Active Rescue Tasks Section Header
                    SectionHeading(
                      title: "Active Rescue Tasks",
                      actionText: "Opportunities",
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Active Tasks List or Loading / Empty State
                    if (viewModel.isLoading && viewModel.assignedDonations.isEmpty)
                      const AppLoadingIndicator(message: "Loading active rescue assignments...")
                    else if (viewModel.assignedDonations.isEmpty)
                      _buildEmptyTasksState(context)
                    else
                      _buildActiveTasksList(viewModel.assignedDonations),

                    const SizedBox(height: 80),
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
      surfaceTintColor: AppColors.surfaceLight,
      backgroundColor: AppColors.surfaceLight,
      titleSpacing: AppSpacing.md,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            "Rescue Control",
            style: AppTypography.pageTitle.copyWith(fontSize: 18),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textPrimary),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              tooltip: "Notifications",
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
          tooltip: "Chats",
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
            radius: 15,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.name != null && user!.name.isNotEmpty ? user.name[0].toUpperCase() : "N",
              style: AppTypography.captionBold.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${user?.name ?? 'Partner'}",
                style: AppTypography.pageTitle.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "NGO Rescue Control & Dispatch",
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildAvailabilityToggle(context, user),
      ],
    );
  }

  Widget _buildAvailabilityToggle(BuildContext context, dynamic user) {
    String status = user?.availabilityStatus ?? 'Available';
    Color color = status == 'Available'
        ? AppColors.success
        : (status == 'Busy' ? AppColors.warning : AppColors.textSecondary);

    return PopupMenuButton<String>(
      onSelected: (value) {},
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Available', child: Text("🟢 Available")),
        const PopupMenuItem(value: 'Busy', child: Text("🟡 Busy")),
        const PopupMenuItem(value: 'Offline', child: Text("⚪ Offline")),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 6),
            Text(
              status,
              style: AppTypography.captionBold.copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBroadcastCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyRequestScreen()),
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BROADCAST EMERGENCY ALERT",
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Notify nearby donors of urgent community hunger needs",
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
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

  Widget _buildSurplusExplorerCard(BuildContext context, DonationViewModel vm) {
    final availableCount = vm.donations.length;
    final countText = availableCount > 0 ? "$availableCount opportunities available" : "Check surplus pickups nearby";

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()),
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Explore Surplus Opportunities",
                        style: AppTypography.sectionHeading.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countText,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
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

  Widget _buildMetricsSection(DonationViewModel vm) {
    final activeCount = vm.assignedDonations.where((d) => d.status != 'completed').length;
    final completedCount = vm.assignedDonations.where((d) => d.status == 'completed').length;
    final totalServings = vm.assignedDonations.fold<int>(0, (sum, d) => sum + d.membersServed);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: "Active Tasks",
            value: "$activeCount",
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatCard(
            label: "Rescues Done",
            value: "$completedCount",
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatCard(
            label: "Servings",
            value: totalServings > 0 ? "$totalServings" : "0",
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTasksList(List<DonationModel> donations) {
    final user = context.watch<AuthViewModel>().user;
    final double userLat = user?.latitude ?? 0;
    final double userLng = user?.longitude ?? 0;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        final status = _formatCardStatus(donation.status);

        String distText = "Within 20 km";
        String etaVal = "15 mins";
        if (userLat != 0 && userLng != 0 && donation.latitude != 0 && donation.longitude != 0) {
          final meters = Geolocator.distanceBetween(userLat, userLng, donation.latitude, donation.longitude);
          distText = "${(meters / 1000).toStringAsFixed(1)} km away";
          final mins = ((meters / 1000) / 30 * 60).round();
          etaVal = "${mins > 0 ? mins : 5} mins";
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

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: DonationCard(
            title: donation.foodName,
            subtitle: "${donation.membersServed} Served • Pickup: ${donation.pickupAddress}",
            status: status,
            timeAgo: timeAgoVal,
            etaText: etaVal,
            distanceText: distText,
            imageUrl: donation.imageUrl,
            onTrackTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)),
              );
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)),
              );
            },
          ),
        ).animate().fadeIn(
              duration: 350.ms,
              delay: Duration(milliseconds: (index * 60).clamp(0, 300)),
            );
      },
    );
  }

  String _formatCardStatus(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'waiting':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'In Transit';
      case 'arrived':
        return 'Arrived';
      case 'picked_up':
        return 'Picked Up';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return rawStatus;
    }
  }

  Widget _buildEmptyTasksState(BuildContext context) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: "No Active Rescue Tasks",
      message: "You have no food rescue missions assigned right now. Explore available surplus requests to claim food.",
      actionText: "EXPLORE SURPLUS FOOD",
      onActionPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()),
        );
      },
    );
  }
}
