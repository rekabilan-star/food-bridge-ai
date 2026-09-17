import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import 'manage_ngos_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'donation_audit_screen.dart';
import '../common/verification_scanner_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/utils/pdf_generator.dart';
import '../common/widgets/user_profile_modal.dart';

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
    final vm = context.read<AdminViewModel>();
    await vm.fetchDashboardStats();
    vm.initSocketListeners();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final stats = viewModel.stats;
    final isLoading = viewModel.isLoading;

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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection().animate().fadeIn().slideX(begin: -0.05, end: 0),

                    const SizedBox(height: 24),

                    // Operations Control Grid
                    _buildSectionTitle("Operations Control"),
                    const SizedBox(height: 12),
                    if (isLoading && stats.isEmpty)
                      _buildLoadingGrid()
                    else
                      _buildSummaryGrid(stats['counts'] ?? {}),
                    
                    const SizedBox(height: 28),

                    // Impact Analytics Cards
                    _buildSectionTitle("Impact Analytics"),
                    const SizedBox(height: 12),
                    _buildImpactCards(stats['impact'] ?? {}),
                    
                    const SizedBox(height: 28),

                    // System Volume Trends Chart
                    _buildSectionTitle("System Trends & Volume"),
                    const SizedBox(height: 12),
                    _buildCharts(stats['charts'] ?? {}),
                    
                    const SizedBox(height: 28),

                    // Live Activity Stream
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text(
                              "Live Activity Stream",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.circle, color: Colors.green, size: 8),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationAuditScreen())),
                          child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildActivityList(stats['recentActivity'] ?? []),
                    
                    const SizedBox(height: 28),

                    // Administrative Quick Actions
                    _buildSectionTitle("Administrative Actions"),
                    const SizedBox(height: 12),
                    _buildQuickActions(context, stats['counts'] ?? {}),

                    const SizedBox(height: 50),
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
      stretch: true,
      expandedHeight: 110,
      backgroundColor: AppColors.adminColor,
      surfaceTintColor: AppColors.adminColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "Command Center",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.adminColor, Color(0xFF4834D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
              SizedBox(width: 4),
              Text("LIVE SYNC", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (nVM.unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
          onPressed: () {
            context.read<AuthViewModel>().logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          tooltip: "Logout",
        ),
        GestureDetector(
          onTap: () => UserProfileModal.show(context),
          child: const CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white24,
            child: Text(
              "A",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.hub_rounded, color: AppColors.adminColor, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("System Operations Dashboard", style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text("Global Network Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.textPrimary),
    );
  }

  Widget _buildSummaryGrid(Map counts) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildStatCard("Total Donors", counts['totalDonors']?.toString() ?? "0", Icons.group_rounded, Colors.blue, "+12%"),
        _buildStatCard("Active NGOs", counts['totalNGOs']?.toString() ?? "0", Icons.business_rounded, Colors.purple, "Verified"),
        _buildStatCard("Verifications", counts['pendingNGOs']?.toString() ?? "0", Icons.verified_user_rounded, Colors.orange, "Pending"),
        _buildStatCard("Rescue Ops", counts['completedDonations']?.toString() ?? "0", Icons.task_alt_rounded, Colors.green, "Completed"),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(trend, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().scale(delay: 100.ms);
  }

  Widget _buildImpactCards(Map impact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildWideImpactCard("Meals Served", impact['mealsServed']?.toString() ?? "0", Icons.restaurant_rounded, Colors.green),
          _buildWideImpactCard("Carbon Offset", "${impact['co2Saved'] ?? 0}kg", Icons.cloud_done_rounded, Colors.blue),
          _buildWideImpactCard("Food Diverted", "${impact['foodSavedKg'] ?? 0}kg", Icons.scale_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildWideImpactCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCharts(Map chartData) {
    final daily = chartData['dailyDonations'] as List? ?? [];
    final categories = chartData['categories'] as List? ?? [];
    
    if (daily.isEmpty && categories.isEmpty) {
       return Container(
         height: 180,
         width: double.infinity,
         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
         child: const Center(child: Text("No volume data available", style: TextStyle(color: Colors.grey, fontSize: 12))),
       );
    }

    return Column(
      children: [
        // Daily Spline Area Chart
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: SfCartesianChart(
            title: const ChartTitle(text: '7-Day Food Rescue Volume', textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), axisLine: AxisLine(width: 0), labelStyle: TextStyle(fontSize: 9)),
            primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 0.5, dashArray: [5, 5]), axisLine: AxisLine(width: 0), labelStyle: TextStyle(fontSize: 9)),
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
                animationDuration: 1200,
                gradient: LinearGradient(
                  colors: [AppColors.adminColor.withValues(alpha: 0.3), AppColors.adminColor.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: AppColors.adminColor,
                borderWidth: 3,
                markerSettings: const MarkerSettings(isVisible: true, width: 4, height: 4, color: AppColors.adminColor),
              )
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Category Pie Chart
        if (categories.isNotEmpty)
          Container(
            height: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: SfCircularChart(
              title: const ChartTitle(text: 'Rescue Distribution by Category', textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap, textStyle: TextStyle(fontSize: 9)),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries>[
                PieSeries<dynamic, String>(
                  dataSource: categories,
                  xValueMapper: (data, _) => data['_id'] ?? 'Other',
                  yValueMapper: (data, _) => (data['count'] ?? 0).toDouble(),
                  dataLabelSettings: const DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside, textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  enableTooltip: true,
                  explode: true,
                  explodeIndex: 0,
                )
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActivityList(List activities) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 5 ? 5 : activities.length,
      itemBuilder: (context, index) {
        final item = activities[index];
        final statusColor = _getStatusColor(item['status']);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(_getStatusIcon(item['status']), color: statusColor, size: 18),
            ),
            title: Text(item['foodName'] ?? "Rescue Mission", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(
              "By ${item['donorId']?['name'] ?? 'Donor'} • ${DateFormat('jm').format(DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now())}", 
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            trailing: _buildStatusTag(item['status'] ?? 'waiting'),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: (index * 50).clamp(0, 250))).slideY(begin: 0.08, end: 0, duration: 300.ms, delay: Duration(milliseconds: (index * 50).clamp(0, 250)), curve: Curves.easeOut);
      },
    );
  }

  Widget _buildStatusTag(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map counts) {
    return Column(
      children: [
        _buildActionRow(
          _buildModernActionCard("User Manager", "Total: ${counts['totalDonors'] ?? 0}", Icons.group_rounded, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()));
          }),
          _buildModernActionCard("NGO Approvals", "Pending: ${counts['pendingNGOs'] ?? 0}", Icons.verified_user_rounded, Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageNgosScreen()));
          }),
        ),
        const SizedBox(height: 12),
        _buildActionRow(
          _buildModernActionCard("Donation Audit", "View all posts", Icons.inventory_2_rounded, Colors.green, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationAuditScreen()));
          }),
          _buildModernActionCard("System Analytics", "System trends", Icons.analytics_rounded, Colors.indigo, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()));
          }),
        ),
        const SizedBox(height: 12),
        _buildActionRow(
          _buildModernActionCard("Export PDF", "System Summary", Icons.picture_as_pdf_rounded, Colors.red, () => _exportSystemReport(context)),
          _buildModernActionCard("Verify Rescue", "Scan certificate", Icons.qr_code_scanner_rounded, Colors.teal, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScannerScreen()));
          }),
        ),
        const SizedBox(height: 12),
        _buildModernActionCard("Broadcast Alert", "Alert all users", Icons.campaign_rounded, Colors.purple, () => _showAnnouncementDialog(context)),
      ],
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String targetRole = 'all';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Broadcast System Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Subject", hintText: "e.g., Scheduled Maintenance")),
                const SizedBox(height: 12),
                TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(labelText: "Message", hintText: "Enter the announcement body...")),
                const SizedBox(height: 20),
                const Text("Target Audience", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: targetRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text("All Active Users")),
                    DropdownMenuItem(value: 'donor', child: Text("Donors Only")),
                    DropdownMenuItem(value: 'ngo', child: Text("NGO Partners Only")),
                  ],
                  onChanged: (v) => setDialogState(() => targetRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || bodyController.text.isEmpty) return;
                
                final viewModel = context.read<AdminViewModel>();
                UIUtils.showLoadingDialog(context);
                
                try {
                  // Requirement: Backend must enforce role filtering
                  await viewModel.sendAnnouncement(titleController.text, bodyController.text, targetRole: targetRole);
                  if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Announcement sent to $targetRole recipients!")));
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    UIUtils.showErrorDialog(context, "Broadcast failed: $e");
                  }
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
              child: const Text("SEND"),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Export Operational Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a date range for the audit report.", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              ListTile(
                title: Text(startDate == null ? "Pick Start Date" : DateFormat('dd MMM yyyy').format(startDate!)),
                leading: const Icon(Icons.calendar_today_rounded, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
                  if (picked != null) setDialogState(() => startDate = picked);
                },
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(endDate == null ? "Pick End Date" : DateFormat('dd MMM yyyy').format(endDate!)),
                leading: const Icon(Icons.event_rounded, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: startDate ?? DateTime(2023), lastDate: DateTime.now());
                  if (picked != null) setDialogState(() => endDate = picked);
                },
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                final viewModel = context.read<AdminViewModel>();
                Navigator.pop(context); // Close selection
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
                    UIUtils.showErrorDialog(context, "Failed to generate report: $e");
                  }
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
              child: const Text("GENERATE PDF"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildModernActionCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case 'completed': return Colors.teal;
      case 'waiting': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch(status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'waiting': return Icons.timer_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.local_shipping_rounded;
    }
  }

  Widget _buildLoadingGrid() {
    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
  }
}
