import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/donation_request.dart';
import 'volunteer/live_tracking_screen.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Donation History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<List<DonationRequest>>(
              stream: DataService().donationStream,
              initialData: DataService().currentDonations,
              builder: (context, snapshot) {
                final donations = snapshot.data ?? [];
                final filtered = donations.where((d) => 
                  d.foodName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  d.restaurantName.toLowerCase().contains(searchQuery.toLowerCase())
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No donations found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildDonationCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search food or restaurant...',
          prefixIcon: const Icon(Icons.search, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildDonationCard(DonationRequest donation) {
    Color statusColor = donation.status == 'pending' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(donation.foodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(donation.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.restaurant, donation.restaurantName),
            _buildInfoRow(Icons.location_on, donation.address),
            _buildInfoRow(Icons.monitor_weight, donation.quantity),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (donation.status == 'accepted_by_ngo')
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LiveTrackingScreen(destination: 'Your Location', donationId: donation.id))),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('TRACK'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showQRVerification(donation),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('VERIFY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }

  void _showQRVerification(DonationRequest donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 200),
            const SizedBox(height: 12),
            Text('Donation ID: ${donation.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
      ),
    );
  }
}
