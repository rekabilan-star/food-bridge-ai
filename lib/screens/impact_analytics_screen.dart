import 'package:flutter/material.dart';

class ImpactAnalyticsScreen extends StatelessWidget {
  const ImpactAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Environmental Impact',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImpactSummaryCard(),
            const SizedBox(height: 24),
            const Text('Community Contribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMetricCard(
                'Meals Provided', '1,240', Icons.restaurant_rounded, Colors.orange),
            _buildMetricCard('Water Saved', '45,000 Liters',
                Icons.water_drop_rounded, Colors.blue),
            _buildMetricCard('CO2 Reduction', '850 kg', Icons.cloud_done_rounded,
                Colors.green),
            _buildMetricCard(
                'Waste Diverted', '2.4 Tons', Icons.recycling_rounded, Colors.teal),
            _buildMetricCard(
                'Beneficiaries Helped', '45 NGOs', Icons.favorite_rounded, Colors.red),
            const SizedBox(height: 24),
            const Text('Environmental Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildWideStatCard('Carbon Footprint Reduced', '1.2 Metric Tons',
                Icons.eco, Colors.green),
            const SizedBox(height: 24),
            const Text('Reports & Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInsightCard(
              context,
              'October Impact Report',
              'You saved enough food to feed a small village for 3 days!',
              'View Details',
              Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text('Impact Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLeaderboard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    final List<Map<String, dynamic>> leaders = [
      {'name': 'Hotel Saravana', 'impact': '1,240 kg', 'rank': 1},
      {'name': 'A2B Sweets', 'impact': '980 kg', 'rank': 2},
      {'name': 'Paradise Biryani', 'impact': '850 kg', 'rank': 3},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: leaders
            .map((leader) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: leader['rank'] == 1
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Text(leader['rank'].toString(),
                        style: TextStyle(
                            color: leader['rank'] == 1
                                ? Colors.amber.shade900
                                : Colors.grey)),
                  ),
                  title: Text(leader['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(leader['impact'],
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildImpactSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Your Total Impact',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Text(
            '342 kg Waste Saved',
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Top 5% of Donors',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              Text(value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildWideStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14)),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, String title, String body,
      String action, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Divider(height: 24),
          TextButton(
            onPressed: () => _showDetailedReport(context),
            child: Text(action,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDetailedReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Impact Insight',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Period: Oct 1 - Oct 31, 2023',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    _buildSummaryRow('Food Saved', '124 kg', '+12% from last month'),
                    _buildSummaryRow(
                        'Meals Served', '310 meals', 'Benefiting 45 children'),
                    _buildSummaryRow(
                        'CO2 Diverted', '250 kg', 'Equal to planting 12 trees'),
                    const SizedBox(height: 32),
                    const Text('Top Performing NGOs',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const ListTile(
                      leading: CircleAvatar(child: Text('1')),
                      title: Text('Helping Hands'),
                      subtitle: Text('Accepted 12 donations'),
                      trailing: Icon(Icons.star, color: Colors.amber),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('DOWNLOAD PDF REPORT'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(sub,
              style: const TextStyle(
                  color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
