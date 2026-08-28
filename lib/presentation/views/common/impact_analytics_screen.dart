import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/utils/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/impact_certificate_dialog.dart';

class ImpactAnalyticsScreen extends StatefulWidget {
  const ImpactAnalyticsScreen({super.key});

  @override
  State<ImpactAnalyticsScreen> createState() => _ImpactAnalyticsScreenState();
}

class _ImpactAnalyticsScreenState extends State<ImpactAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService().dio.get('user/impact-analytics');
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
          _isLoading = false;
        });
      }
    }
  }

  void _showCertificate(BuildContext context) {
    final user = context.read<AuthViewModel>().user;
    ImpactCertificateDialog.show(
      context,
      userName: user?.name ?? "Food Rescuer",
      userRole: user?.role.toString().split('.').last ?? "Donor",
      totalKg: _data['totalWeightSaved']?.toDouble() ?? 45.0,
      mealsProvided: _data['mealsProvided'] ?? 340,
      co2Reduced: _data['co2Reduction']?.toDouble() ?? 288.4,
      waterSaved: (_data['waterSaved']?.toDouble() ?? 1420.0).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final isNGO = user?.role.toString().split('.').last == 'ngo';
    final primaryColor = isNGO ? AppColors.ngoColor : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, isNGO, primaryColor),
            _isLoading 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainImpactCard(isNGO, primaryColor),
                        const SizedBox(height: 48),
                        if (isNGO) ...[
                          _buildSectionHeader('EFFICIENCY METRICS'),
                          _buildNgoStatsRow(),
                          const SizedBox(height: 48),
                        ],
                        _buildSectionHeader('LIFETIME CONTRIBUTION'),
                        const SizedBox(height: 20),
                        _buildMetricsGrid(),
                        const SizedBox(height: 48),
                        _buildSectionHeader('RESCUE TRENDS'),
                        const SizedBox(height: 20),
                        _buildMonthlyChart(primaryColor),
                        const SizedBox(height: 48),
                        _buildSectionHeader('RESOURCE COMPOSITION'),
                        const SizedBox(height: 20),
                        _buildCategoryChart(),
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

  Widget _buildAppBar(BuildContext context, bool isNGO, Color color) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      surfaceTintColor: Colors.white,
      title: Text(isNGO ? 'Rescue Intel' : 'Impact Analytics', 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
      actions: [
        IconButton(
          icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
          tooltip: "Download Impact Certificate",
          onPressed: () => _showCertificate(context),
        ),
        IconButton(icon: const Icon(Icons.refresh_rounded, size: 22), onPressed: _fetchData),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, 
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey));
  }

  Widget _buildMainImpactCard(bool isNGO, Color primaryColor) {
    final weight = _data['totalWeightSaved']?.toDouble() ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFF686DE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(isNGO ? Icons.auto_graph_rounded : Icons.eco_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          Text(
            isNGO ? 'TOTAL VOLUME RESCUED' : 'TOTAL WASTE DIVERTED',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
                color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
                ),
                child: Text(
                  isNGO ? 'ELITE RESCUER STATUS' : 'COMMUNITY HERO STATUS',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showCertificate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CERTIFICATE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildNgoStatsRow() {
    final metrics = _data['ngoMetrics'] ?? {};
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          _buildSmallStatCard('RESCUE RATE', '${metrics['completionRate'] ?? 98}%', Icons.verified_rounded, Colors.blue),
          const SizedBox(width: 16),
          _buildSmallStatCard('AVG PICKUP', '${metrics['avgPickupTime'] ?? 14}m', Icons.speed_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.0,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: [
        _buildMetricItem('Meals Provided', '${_data['mealsProvided'] ?? 340}', Icons.restaurant_rounded, Colors.orange),
        _buildMetricItem('CO2 Reduced', '${(_data['co2Reduction']?.toDouble() ?? 288.4).toStringAsFixed(1)}kg', Icons.cloud_done_rounded, Colors.teal),
        _buildMetricItem('Donations', '${_data['totalDonations'] ?? 18}', Icons.volunteer_activism_rounded, Colors.redAccent),
        _buildMetricItem('Water Saved', '${(_data['waterSaved']?.toDouble() ?? 1420.0).toInt()}L', Icons.water_drop_rounded, Colors.blueAccent),
      ],
    );
  }

  Widget _buildMetricItem(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildMonthlyChart(Color primaryColor) {
    final List<dynamic> monthly = _data['charts']?['monthly'] ?? [];
    if (monthly.isEmpty) {
      return _buildEmptyChart('No trend data available');
    }
    
    final chartData = monthly.map((m) {
      final monthIndex = m['_id'] is int ? m['_id'] : 1;
      return _ChartData(_getMonthName(monthIndex), (m['meals'] ?? 0).toDouble());
    }).toList();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), axisLine: AxisLine(width: 0)),
        primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 0.5, dashArray: [5, 5]), axisLine: AxisLine(width: 0)),
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          ColumnSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            color: primaryColor,
            animationDuration: 1000,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            width: 0.5,
          )
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildCategoryChart() {
    final List<dynamic> categories = _data['charts']?['categories'] ?? [];
    if (categories.isEmpty) {
       return _buildEmptyChart('No category data available');
    }

    final chartData = categories.map((c) => _ChartData(c['_id'] ?? 'Other', (c['count'] ?? 0).toDouble())).toList();

    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: SfCircularChart(
        legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries>[
          DoughnutSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            innerRadius: '70%',
            animationDuration: 1000,
            dataLabelSettings: const DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
          )
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  String _getMonthName(int month) {
    if (month < 1 || month > 12) return "N/A";
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
