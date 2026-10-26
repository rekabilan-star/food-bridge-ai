import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/utils/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/stat_card.dart';
import '../common/widgets/section_heading.dart';
import '../common/widgets/empty_state.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService().dio.get('admin/dashboard');
      if (mounted) {
        setState(() {
          _data = response.data['data'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = {};
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "System Analytics & Metrics",
          style: AppTypography.pageTitle.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStats,
            tooltip: "Refresh Analytics",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: AppColors.adminColor,
        child: _isLoading && _data.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
            : _errorMessage != null && _data.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        iconColor: AppColors.error,
                        title: "Analytics Unavailable",
                        message: _errorMessage,
                        actionText: "RETRY",
                        onActionPressed: _fetchStats,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(
                          title: "Network Ecosystem",
                          subtitle: "Real-time user engagement and active fleets",
                        ),
                        AppSpacing.vGapMd,
                        _buildStatCards(),
                        AppSpacing.vGapXl,

                        const SectionHeading(
                          title: "Eco-Social Impact",
                          subtitle: "Verified sustainability achievements",
                        ),
                        AppSpacing.vGapMd,
                        _buildImpactGrid(),
                        AppSpacing.vGapXl,

                        const SectionHeading(
                          title: "Rescue Operations Trend",
                          subtitle: "7-day rescue volume activity",
                        ),
                        AppSpacing.vGapMd,
                        _buildDonationChart(),
                        AppSpacing.vGapXl,

                        const SectionHeading(
                          title: "Food Category Distribution",
                          subtitle: "Breakdown of rescued items",
                        ),
                        AppSpacing.vGapMd,
                        _buildFoodCategoryChart(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCards() {
    final counts = _data['counts'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.25,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          label: "Total Donors",
          value: "${counts['totalDonors'] ?? 0}",
          icon: Icons.person_rounded,
          iconColor: AppColors.primary,
        ),
        StatCard(
          label: "Active NGOs",
          value: "${counts['totalNGOs'] ?? 0}",
          icon: Icons.business_rounded,
          iconColor: AppColors.ngoColor,
        ),
        StatCard(
          label: "Active Rescues",
          value: "${counts['activeDonations'] ?? 0}",
          icon: Icons.local_shipping_rounded,
          iconColor: AppColors.info,
        ),
        StatCard(
          label: "Pending NGOs",
          value: "${counts['pendingNGOs'] ?? 0}",
          icon: Icons.verified_user_rounded,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildImpactGrid() {
    final impact = _data['impact'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildImpactItem("Meals Served", "${impact['mealsServed'] ?? 0}", AppColors.success),
        _buildImpactItem("Food Saved", "${impact['foodSavedKg'] ?? 0}kg", AppColors.info),
        _buildImpactItem("CO₂ Diverted", "${impact['co2Saved'] ?? 0}kg", const Color(0xFF0D9488)),
        _buildImpactItem("People Helped", "${impact['membersServed'] ?? 0}", AppColors.primary),
      ],
    );
  }

  Widget _buildImpactItem(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            val,
            style: AppTypography.subsectionHeading.copyWith(color: color, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
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

  Widget _buildDonationChart() {
    final List<dynamic> rawData = _data['charts']?['dailyDonations'] ?? [];
    if (rawData.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: AppColors.border),
        ),
        child: const EmptyState(
          icon: Icons.show_chart_rounded,
          title: "No Daily Trend Data",
          message: "Data points will accumulate as rescues take place.",
        ),
      );
    }

    final List<_ChartData> chartData = rawData.map((d) {
      final String id = d['_id'] ?? '';
      final String label = id.contains('-') ? id.split('-').last : id;
      return _ChartData(label, (d['count'] ?? 0).toDouble());
    }).toList();

    return Container(
      height: 280,
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorGridLines: MajorGridLines(width: 0.5, dashArray: [5, 5]),
          labelStyle: TextStyle(fontSize: 10),
        ),
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<_ChartData, String>>[
          SplineAreaSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
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
    );
  }

  Widget _buildFoodCategoryChart() {
    final List<dynamic> rawData = _data['charts']?['categories'] ?? [];
    if (rawData.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: AppColors.border),
        ),
        child: const EmptyState(
          icon: Icons.pie_chart_outline_rounded,
          title: "No Categories Recorded",
          message: "Categories will populate once donations are created.",
        ),
      );
    }

    final List<_PieData> chartData = rawData
        .map((d) => _PieData(d['_id'] ?? 'Other', (d['count'] ?? 0).toDouble()))
        .toList();

    return Container(
      height: 280,
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(fontSize: 10),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<_PieData, String>>[
          DoughnutSeries<_PieData, String>(
            dataSource: chartData,
            xValueMapper: (_PieData data, _) => data.x,
            yValueMapper: (_PieData data, _) => data.y,
            innerRadius: '60%',
            animationDuration: 0,
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String x;
  final double y;
  _ChartData(this.x, this.y);
}

class _PieData {
  final String x;
  final double y;
  _PieData(this.x, this.y);
}
