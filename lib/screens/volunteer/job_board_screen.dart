import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/donation_request.dart';

class VolunteerJobBoard extends StatelessWidget {
  const VolunteerJobBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Deliveries'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DonationRequest>>(
        stream: DataService().donationStream,
        initialData: DataService().currentDonations,
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          // In this real-time flow, volunteers see tasks accepted by NGOs
          final available = all.where((d) => d.status == 'accepted_by_ngo').toList();

          if (available.isEmpty) {
            return const Center(child: Text('No deliveries available at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: available.length,
            itemBuilder: (context, index) {
              final job = available[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.delivery_dining, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Pickup: ${job.address} • ${job.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reward: 50 pts', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                          ElevatedButton(
                            onPressed: () {
                              DataService().updateDonationStatus(job.id, 'assigned_to_volunteer');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delivery Accepted! Navigation started.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('ACCEPT DELIVERY'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
