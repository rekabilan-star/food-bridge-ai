import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';

import 'manage_ngos_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'donation_audit_screen.dart';
import 'admin_live_tracking_screen.dart';
import 'sms_logs_screen.dart';

import '../common/verification_scanner_screen.dart';
import '../common/widgets/user_profile_modal.dart';
import '../common/widgets/status_badge.dart';
import '../common/widgets/stat_card.dart';
import '../common/widgets/section_heading.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/utils/pdf_generator.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final adminVM = context.read<AdminViewModel>();
    final emergencyVM = context.read<EmergencyViewModel>();
    await Future.wait([
      adminVM.fetchDashboardStats(),
      emergencyVM.fetchActiveRequests(),
    ]);
    adminVM.initSocketListeners();
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final emergencyVM = context.watch<EmergencyViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final stats = adminVM.stats;
    final isLoading = adminVM.isLoading;
    final errorMessage = adminVM.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.adminColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdminHero(authVM),
                    AppSpacing.vGapLg,

                    if (emergencyVM.requests.isNotEmpty) ...[
                      _buildEmergencyAlertBanner(emergencyVM),
                      AppSpacing.vGapLg,
                    ],

                    if (errorMessage != null && stats.isEmpty)
                      _buildErrorState(errorMessage)
                    else ...[
                      // System Metrics
                      const SectionHeading(
                        title: "Operations Command",
                        subtitle: "Live network rescue throughput & approvals",
                      ),
                      AppSpacing.vGapMd,
                      if (isLoading && stats.isEmpty)
                        _buildLoadingGrid()
                      else
                        _buildOperationsGrid(stats['counts'] ?? {}),
                      AppSpacing.vGapXl,

                      // Lifecycle Status Distribution
                      const SectionHeading(
                        title: "Donation Lifecycle Pipeline",
                        subtitle: "Active distribution across all phases",
                      ),
                      AppSpacing.vGapMd,
                      _buildLifecyclePipeline(stats['counts'] ?? {}),
                      AppSpacing.vGapXl,

                      // Impact Analytics
                      const SectionHeading(
                        title: "Eco & Community Impact",
                        subtitle: "Cumulative social and environmental savings",
                      ),
                      AppSpacing.vGapMd,
                      _buildImpactCards(stats['impact'] ?? {}),
                      AppSpacing.vGapXl,

                      // Trends & Category Distribution Charts
                      const SectionHeading(
                        title: "Network Volume & Analytics",
                        subtitle: "7-day rescue cadence & item categories",
                      ),
                      AppSpacing.vGapMd,
                      _buildChartsSection(stats['charts'] ?? {}),
                      AppSpacing.vGapXl,

                      // Live Activity Feed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Live Mission Stream",
                                    style: AppTypography.sectionHeading,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.hGapSm,
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DonationAuditScreen()),
                            ),
                            child: Text(
                              "View All",
                              style: AppTypography.captionBold.copyWith(color: AppColors.adminColor),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      _buildActivityList(stats['recentActivity'] ?? []),
                      AppSpacing.vGapXl,

                      // Administrative Action Center
                      const SectionHeading(
                        title: "Administrative Control Center",
                        subtitle: "Auditing, approvals, fleet & governance",
                      ),
                      AppSpacing.vGapMd,
                      _buildQuickActionCards(context, stats['counts'] ?? {}),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final nVM = context.watch<NotificationViewModel>();
    return SliverAppBar(
      floating: true,
      pinned: true,
      titleSpacing: 12,
      backgroundColor: AppColors.adminColor,
      surfaceTintColor: AppColors.adminColor,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              "Operations Center",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Live Socket Sync Badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "LIVE SYNC",
                style: AppTypography.captionBold.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              tooltip: "Notifications",
            ),
            if (nVM.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    nVM.unreadCount > 9 ? '9+' : '${nVM.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          onPressed: () {
            UIUtils.showConfirmationDialog(
              context: context,
              title: "Log Out",
              message: "Are you sure you want to end your administrative session?",
              confirmText: "LOGOUT",
              confirmColor: AppColors.error,
              onConfirm: () {
                context.read<AuthViewModel>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            );
          },
          tooltip: "Logout",
        ),
        GestureDetector(
          onTap: () => UserProfileModal.show(context),
          child: Container(
            margin: const EdgeInsets.only(right: 14, left: 4),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white24,
              child: Text(
                (context.watch<AuthViewModel>().user?.name.isNotEmpty == true)
                    ? context.watch<AuthViewModel>().user!.name[0].toUpperCase()
                    : "A",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminHero(AuthViewModel authVM) {
    final name = authVM.user?.name ?? "Administrator";
    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderLg,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.adminColor, size: 28),
          ),
          AppSpacing.hGapBase,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Welcome, $name",
                      style: AppTypography.subsectionHeading,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.adminColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        "SUPER ADMIN",
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.adminColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Global Rescue Operations Online",
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertBanner(EmergencyViewModel emergencyVM) {
    final count = emergencyVM.requests.length;
    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          AppSpacing.hGapBase,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count Active Emergency Request${count > 1 ? 's' : ''}",
                  style: AppTypography.subsectionHeading.copyWith(color: const Color(0xFF991B1B)),
                ),
                Text(
                  "Immediate food assistance flagged by NGOs",
                  style: AppTypography.caption.copyWith(color: const Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showEmergencyRequestsSheet(context, emergencyVM),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            child: const Text("REVIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsGrid(Map counts) {
    final totalDonors = counts['totalDonors']?.toString() ?? "0";
    final totalNGOs = counts['totalNGOs']?.toString() ?? "0";
    final pendingNGOs = counts['pendingNGOs']?.toString() ?? "0";
    final completedDonations = counts['completedDonations']?.toString() ?? "0";
    final activeDonations = counts['activeDonations']?.toString() ?? "0";
    final todayDonations = counts['todayDonations']?.toString() ?? "0";

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        StatCard(
          label: "Total Donors",
          value: totalDonors,
          icon: Icons.group_rounded,
          iconColor: AppColors.primary,
          trendText: "Registered",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersScreen(initialRole: 'donor')),
          ),
        ),
        StatCard(
          label: "Active NGOs",
          value: totalNGOs,
          icon: Icons.domain_rounded,
          iconColor: AppColors.ngoColor,
          trendText: "Verified",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageNgosScreen(initialStatus: 'approved')),
          ),
        ),
        StatCard(
          label: "Pending Approvals",
          value: pendingNGOs,
          icon: Icons.pending_actions_rounded,
          iconColor: AppColors.warning,
          trendText: "Action Needed",
          isPositiveTrend: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageNgosScreen(initialStatus: 'pending')),
          ),
        ),
        StatCard(
          label: "Completed Rescues",
          value: completedDonations,
          icon: Icons.task_alt_rounded,
          iconColor: AppColors.success,
          trendText: "Delivered",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonationAuditScreen(initialStatus: 'completed')),
          ),
        ),
        StatCard(
          label: "Active Rescues",
          value: activeDonations,
          icon: Icons.local_shipping_rounded,
          iconColor: AppColors.info,
          trendText: "In-Progress",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonationAuditScreen(initialStatus: 'accepted')),
          ),
        ),
        StatCard(
          label: "Today's Volume",
          value: todayDonations,
          icon: Icons.today_rounded,
          iconColor: Colors.teal,
          trendText: "Past 24h",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonationAuditScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildLifecyclePipeline(Map counts) {
    final statusDist = counts['statusDistribution'] as List? ?? [];
    int getCount(String st) {
      for (final e in statusDist) {
        if (e is Map && (e['_id']?.toString().toLowerCase() ?? '') == st.toLowerCase()) {
          return (e['count'] is num) ? (e['count'] as num).toInt() : 0;
        }
      }
      return 0;
    }

    final waiting = getCount('waiting');
    final accepted = getCount('accepted');
    final inTransit = getCount('picked_up') + getCount('on_the_way') + getCount('arrived');
    final completed = counts['completedDonations'] as int? ?? getCount('completed');
    final cancelled = getCount('cancelled') + getCount('rejected');

    final phases = [
      {'label': 'Waiting', 'count': waiting, 'status': 'waiting', 'color': AppColors.warning},
      {'label': 'Accepted', 'count': accepted, 'status': 'accepted', 'color': AppColors.info},
      {'label': 'In-Transit', 'count': inTransit, 'status': 'picked_up', 'color': AppColors.primary},
      {'label': 'Delivered', 'count': completed, 'status': 'completed', 'color': AppColors.success},
      {'label': 'Cancelled', 'count': cancelled, 'status': 'cancelled', 'color': AppColors.error},
    ];

    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Real-time Pipeline Overview",
                  style: AppTypography.subsectionHeading.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Tap to filter",
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            children: phases.map((phase) {
              final color = phase['color'] as Color;
              final count = phase['count'] as int;
              final label = phase['label'] as String;
              final status = phase['status'] as String;

              return Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DonationAuditScreen(initialStatus: status)),
                  ),
                  borderRadius: AppRadius.borderMd,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$count',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCards(Map impact) {
    final mealsServed = impact['mealsServed']?.toString() ?? "0";
    final co2Saved = impact['co2Saved']?.toString() ?? "0";
    final foodSavedKg = impact['foodSavedKg']?.toString() ?? "0";
    final membersServed = impact['membersServed']?.toString() ?? "0";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildImpactItem("Meals Provided", mealsServed, Icons.restaurant_rounded, AppColors.success),
          _buildImpactItem("Food Diverted", "${foodSavedKg}kg", Icons.scale_rounded, AppColors.info),
          _buildImpactItem("CO₂ Offset", "${co2Saved}kg", Icons.cloud_done_rounded, const Color(0xFF0D9488)),
          _buildImpactItem("People Reached", membersServed, Icons.diversity_3_rounded, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String label, String value, IconData icon, Color color) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          AppSpacing.vGapMd,
          Text(
            value,
            style: AppTypography.pageTitle.copyWith(fontSize: 20, letterSpacing: -0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(Map chartData) {
    final daily = chartData['dailyDonations'] as List? ?? [];
    final categories = chartData['categories'] as List? ?? [];

    if (daily.isEmpty && categories.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: AppColors.border),
        ),
        child: const EmptyState(
          icon: Icons.bar_chart_rounded,
          title: "No Analytical Data",
          message: "Trend logs will render as donations and pickups occur.",
        ),
      );
    }

    return Column(
      children: [
        // Daily Spline Area Chart
        Container(
          height: 240,
          padding: AppSpacing.paddingBase,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.borderXl,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: SfCartesianChart(
            title: ChartTitle(
              text: '7-Day Rescue Operations Volume',
              textStyle: AppTypography.captionBold.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
              axisLine: AxisLine(width: 0),
              labelStyle: TextStyle(fontSize: 10),
            ),
            primaryYAxis: const NumericAxis(
              majorGridLines: MajorGridLines(width: 0.5, dashArray: [5, 5]),
              axisLine: AxisLine(width: 0),
              labelStyle: TextStyle(fontSize: 10),
            ),
            plotAreaBorderWidth: 0,
            tooltipBehavior: TooltipBehavior(enable: true, header: 'Rescues'),
            series: <CartesianSeries>[
              SplineAreaSeries<dynamic, String>(
                dataSource: daily,
                xValueMapper: (data, _) {
                  final String id = data['_id'] ?? '';
                  return id.length > 5 ? id.substring(5) : id;
                },
                yValueMapper: (data, _) => (data['count'] ?? 0).toDouble(),
                animationDuration: 0,
                gradient: LinearGradient(
                  colors: [
                    AppColors.adminColor.withValues(alpha: 0.35),
                    AppColors.adminColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: AppColors.adminColor,
                borderWidth: 2.5,
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty) ...[
          AppSpacing.vGapBase,
          Container(
            height: 240,
            padding: AppSpacing.paddingBase,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.borderXl,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: SfCircularChart(
              title: ChartTitle(
                text: 'Food Rescues by Category',
                textStyle: AppTypography.captionBold.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries>[
                DoughnutSeries<dynamic, String>(
                  dataSource: categories,
                  xValueMapper: (data, _) => data['_id'] ?? 'Other',
                  yValueMapper: (data, _) => (data['count'] ?? 0).toDouble(),
                  innerRadius: '58%',
                  animationDuration: 0,
                  enableTooltip: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityList(List activities) {
    if (activities.isEmpty) {
      return Container(
        padding: AppSpacing.paddingBase,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            "No recent activity logged",
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }

    final displayItems = activities.take(5).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final donor = item['donorId']?['name'] ?? 'Donor';
        final ngo = item['assignedNgoId']?['name'];
        final status = item['status'] ?? 'waiting';
        DateTime created;
        try {
          created = item['createdAt'] != null ? DateTime.parse(item['createdAt']).toLocal() : DateTime.now();
        } catch (_) {
          created = DateTime.now();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.subtle,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.adminColor.withValues(alpha: 0.1),
              child: const Icon(Icons.fastfood_rounded, color: AppColors.adminColor, size: 18),
            ),
            title: Text(
              item['foodName'] ?? "Rescue Mission",
              style: AppTypography.subsectionHeading.copyWith(fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  "By $donor ${ngo != null ? '• Assigned: $ngo' : ''}",
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(created),
                  style: AppTypography.caption.copyWith(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
            trailing: StatusBadge(status: status),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCards(BuildContext context, Map counts) {
    return Column(
      children: [
        _buildActionRow(
          _buildActionCard(
            "User Manager",
            "Donors, NGOs & volunteers",
            Icons.people_alt_rounded,
            AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
          ),
          _buildActionCard(
            "NGO Approvals",
            "${counts['pendingNGOs'] ?? 0} pending review",
            Icons.verified_user_rounded,
            AppColors.warning,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageNgosScreen())),
            badge: (counts['pendingNGOs'] as int? ?? 0) > 0 ? "${counts['pendingNGOs']}" : null,
          ),
        ),
        AppSpacing.vGapMd,
        _buildActionRow(
          _buildActionCard(
            "Donation Audit",
            "Monitor lifecycle & expiry",
            Icons.inventory_2_rounded,
            AppColors.success,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationAuditScreen())),
          ),
          _buildActionCard(
            "System Analytics",
            "Deep trends & impact logs",
            Icons.insights_rounded,
            AppColors.info,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen())),
          ),
        ),
        AppSpacing.vGapMd,
        _buildActionRow(
          _buildActionCard(
            "Fleet Live Map",
            "Real-time volunteer tracking",
            Icons.map_rounded,
            Colors.teal,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLiveTrackingScreen())),
          ),
          _buildActionCard(
            "SMS Audit Logs",
            "OTP & dispatch alerts",
            Icons.sms_rounded,
            Colors.indigo,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsLogsScreen())),
          ),
        ),
        AppSpacing.vGapMd,
        _buildActionRow(
          _buildActionCard(
            "Export PDF Report",
            "Audit records summary",
            Icons.picture_as_pdf_rounded,
            Colors.deepOrange,
            () => _exportSystemReport(context),
          ),
          _buildActionCard(
            "Verify Rescue QR",
            "Scan physical certificate",
            Icons.qr_code_scanner_rounded,
            AppColors.ngoColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScannerScreen())),
          ),
        ),
        AppSpacing.vGapMd,
        _buildActionCard(
          "Broadcast System Announcement",
          "Send emergency or maintenance alerts to targeted roles",
          Icons.campaign_rounded,
          AppColors.adminColor,
          () => _showAnnouncementDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        AppSpacing.hGapMd,
        Expanded(child: right),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderXl,
          child: Padding(
            padding: AppSpacing.paddingBase,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                AppSpacing.vGapMd,
                Text(
                  title,
                  style: AppTypography.subsectionHeading.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String targetRole = 'all';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
          backgroundColor: AppColors.surfaceLight,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(Icons.campaign_rounded, color: AppColors.adminColor, size: 22),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  "Broadcast Announcement",
                  style: AppTypography.subsectionHeading,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernTextField(
                  label: "Subject",
                  hint: "e.g., Scheduled Platform Maintenance",
                  controller: titleController,
                ),
                AppSpacing.vGapMd,
                ModernTextField(
                  label: "Announcement Message",
                  hint: "Enter the detailed broadcast message...",
                  controller: bodyController,
                  maxLines: 4,
                ),
                AppSpacing.vGapMd,
                Text("Target Audience", style: AppTypography.fieldLabel),
                AppSpacing.vGapXs,
                DropdownButtonFormField<String>(
                  initialValue: targetRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text("All Registered Users")),
                    DropdownMenuItem(value: 'donor', child: Text("Donors Only")),
                    DropdownMenuItem(value: 'ngo', child: Text("NGO Partners Only")),
                  ],
                  onChanged: (v) => setDialogState(() => targetRole = v!),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SecondaryButton(
              text: "CANCEL",
              onPressed: () => Navigator.pop(dialogCtx),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              text: "BROADCAST",
              onPressed: () async {
                if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                  UIUtils.showSnackBar(context, "Please provide subject and message");
                  return;
                }

                final viewModel = context.read<AdminViewModel>();
                UIUtils.showLoadingDialog(context);

                try {
                  await viewModel.sendAnnouncement(
                    titleController.text.trim(),
                    bodyController.text.trim(),
                    targetRole: targetRole,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    Navigator.pop(dialogCtx); // Close dialog
                    UIUtils.showSnackBar(context, "Announcement broadcast to $targetRole!");
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    UIUtils.showErrorDialog(context, "Broadcast failed: $e");
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportSystemReport(BuildContext context) async {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
          backgroundColor: AppColors.surfaceLight,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.deepOrange, size: 22),
              ),
              AppSpacing.hGapSm,
              Text("Export Audit PDF", style: AppTypography.subsectionHeading),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Filter date range for operational records audit report.",
                style: AppTypography.bodySmall,
              ),
              AppSpacing.vGapBase,
              ListTile(
                title: Text(
                  startDate == null ? "Select Start Date" : DateFormat('dd MMM yyyy').format(startDate!),
                  style: AppTypography.bodyMedium,
                ),
                leading: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => startDate = picked);
                },
                tileColor: AppColors.backgroundLight,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              AppSpacing.vGapSm,
              ListTile(
                title: Text(
                  endDate == null ? "Select End Date" : DateFormat('dd MMM yyyy').format(endDate!),
                  style: AppTypography.bodyMedium,
                ),
                leading: const Icon(Icons.event_rounded, size: 18, color: AppColors.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: startDate ?? DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
                tileColor: AppColors.backgroundLight,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SecondaryButton(text: "CANCEL", onPressed: () => Navigator.pop(dialogCtx)),
            const SizedBox(width: 8),
            PrimaryButton(
              text: "GENERATE",
              onPressed: () async {
                final viewModel = context.read<AdminViewModel>();
                Navigator.pop(dialogCtx);
                UIUtils.showLoadingDialog(context);

                try {
                  final donations = await viewModel.fetchReportData(
                    start: startDate?.toIso8601String(),
                    end: endDate?.toIso8601String(),
                  );
                  final file = await PdfGenerator.generateSystemSummary(donations);

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    await OpenFile.open(file.path);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    UIUtils.showErrorDialog(context, "Failed to generate audit report: $e");
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyRequestsSheet(BuildContext context, EmergencyViewModel emergencyVM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (sheetCtx) => Container(
        padding: AppSpacing.pagePadding,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                AppSpacing.hGapSm,
                Text("Emergency Food Rescues", style: AppTypography.sectionHeading),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            Expanded(
              child: ListView.builder(
                itemCount: emergencyVM.requests.length,
                itemBuilder: (ctx, i) {
                  final req = emergencyVM.requests[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: AppSpacing.paddingBase,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(req.title, style: AppTypography.subsectionHeading),
                            StatusBadge(label: req.priority.toUpperCase(), color: AppColors.error),
                          ],
                        ),
                        AppSpacing.vGapXs,
                        Text("NGO: ${req.ngoName ?? req.ngoId}", style: AppTypography.captionBold),
                        Text("Meals needed: ${req.requiredMembers} • Type: ${req.foodType}", style: AppTypography.caption),
                        Text("Address: ${req.address}", style: AppTypography.caption),
                        AppSpacing.vGapSm,
                        if (req.status != 'fulfilled')
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                final ok = await emergencyVM.fulfillRequest(req.id);
                                if (context.mounted && ok) {
                                  UIUtils.showSnackBar(context, "Emergency request marked fulfilled");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("MARK FULFILLED"),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.adminColor),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 36),
          AppSpacing.vGapSm,
          Text("Metrics Stream Offline", style: AppTypography.subsectionHeading.copyWith(color: AppColors.error)),
          AppSpacing.vGapXs,
          Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          AppSpacing.vGapBase,
          PrimaryButton(
            text: "RETRY CONNECTION",
            onPressed: _refreshData,
            height: 40,
          ),
        ],
      ),
    );
  }
}
