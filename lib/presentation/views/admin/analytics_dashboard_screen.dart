import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Analytics'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCards(),
            const SizedBox(height: 20),
            _buildDonationChart(),
            const SizedBox(height: 20),
            _buildFoodCategoryChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _statCard('Total Saved', '1,250 kg', Icons.eco, Colors.green),
        _statCard('Meals Served', '4,800', Icons.restaurant, Colors.orange),
        _statCard('Active NGOs', '42', Icons.business, Colors.blue),
        _statCard('Volunteers', '128', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildDonationChart() {
    final List<_ChartData> data = [
      _ChartData('Mon', 12),
      _ChartData('Tue', 18),
      _ChartData('Wed', 15),
      _ChartData('Thu', 25),
      _ChartData('Fri', 22),
      _ChartData('Sat', 30),
      _ChartData('Sun', 28),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        title: const ChartTitle(text: 'Weekly Donations Trend'),
        series: <CartesianSeries<_ChartData, String>>[
          SplineSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData sales, _) => sales.x,
            yValueMapper: (_ChartData sales, _) => sales.y,
            name: 'Donations',
            color: Colors.blue,
            width: 4,
            markerSettings: const MarkerSettings(isVisible: true),
          )
        ],
      ),
    );
  }

  Widget _buildFoodCategoryChart() {
    final List<_PieData> data = [
      _PieData('Cooked Food', 45, Colors.orange),
      _PieData('Vegetables', 25, Colors.green),
      _PieData('Grains', 20, Colors.brown),
      _PieData('Others', 10, Colors.grey),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SfCircularChart(
        title: const ChartTitle(text: 'Donation Categories'),
        legend: const Legend(isVisible: true),
        series: <CircularSeries<_PieData, String>>[
          PieSeries<_PieData, String>(
            dataSource: data,
            xValueMapper: (_PieData data, _) => data.x,
            yValueMapper: (_PieData data, _) => data.y,
            pointColorMapper: (_PieData data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

class _PieData {
  _PieData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
