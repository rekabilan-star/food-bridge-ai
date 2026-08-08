import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/api_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('System Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Network Health'),
                  _buildStatCards(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Impact Metrics'),
                  _buildImpactGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Donation Trends'),
                  _buildDonationChart(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Category Distribution'),
                  _buildFoodCategoryChart(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCards() {
    final counts = _data['counts'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _statCard('Total Donors', '${counts['totalDonors']}', Icons.person, Colors.blue),
        _statCard('Active NGOs', '${counts['totalNGOs']}', Icons.business, Colors.orange),
        _statCard('Active Rescue', '${counts['activeDonations']}', Icons.local_shipping, Colors.green),
        _statCard('Pending Verification', '${counts['pendingNGOs']}', Icons.verified_user, Colors.red),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale();
  }

  Widget _buildImpactGrid() {
    final impact = _data['impact'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _impactMiniCard('Meals Served', '${impact['mealsServed']}', Colors.deepOrange),
        _impactMiniCard('Food Saved', '${impact['foodSavedKg']}kg', Colors.green),
        _impactMiniCard('CO2 Diverted', '${impact['co2Saved']}kg', Colors.teal),
        _impactMiniCard('People Helped', '${impact['membersServed']}', Colors.indigo),
      ],
    );
  }

  Widget _impactMiniCard(String label, String val, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationChart() {
    final List<dynamic> rawData = _data['charts']?['dailyDonations'] ?? [];
    if (rawData.isEmpty) return _buildEmptyState('No donation trends');

    final List<_ChartData> chartData = rawData.map((d) {
      final String id = d['_id'] ?? '';
      final String label = id.contains('-') ? id.split('-').last : id;
      return _ChartData(label, (d['count'] ?? 0).toDouble());
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
        primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0)),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<_ChartData, String>>[
          SplineAreaSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            animationDuration: 1000,
            gradient: LinearGradient(
              colors: [Colors.blue.withValues(alpha: 0.3), Colors.blue.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: Colors.blue,
            borderWidth: 3,
          )
        ],
      ),
    );
  }

  Widget _buildFoodCategoryChart() {
    final List<dynamic> rawData = _data['charts']?['categories'] ?? [];
    if (rawData.isEmpty) return _buildEmptyState('No category distribution');

    final List<_PieData> chartData = rawData.map((d) => _PieData(d['_id'] ?? 'Other', (d['count'] ?? 0).toDouble())).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
      ),
      child: SfCircularChart(
        legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<_PieData, String>>[
          DoughnutSeries<_PieData, String>(
            dataSource: chartData,
            xValueMapper: (_PieData data, _) => data.x,
            yValueMapper: (_PieData data, _) => data.y,
            innerRadius: '60%',
            animationDuration: 1000,
            dataLabelSettings: const DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

class _PieData {
  _PieData(this.x, this.y);
  final String x;
  final double y;
}
