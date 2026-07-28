import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/route_optimization_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../delivery/live_tracking_map_screen.dart';
import 'package:intl/intl.dart';

class VolunteerRouteScreen extends StatefulWidget {
  const VolunteerRouteScreen({super.key});

  @override
  State<VolunteerRouteScreen> createState() => _VolunteerRouteScreenState();
}

class _VolunteerRouteScreenState extends State<VolunteerRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteOptimizationViewModel>().fetchOptimizedRoute();
    });
  }

  void _navigateToTracking(String donationId) async {
    final donationVM = context.read<DonationViewModel>();
    await donationVM.fetchDonationDetails(donationId);
    if (donationVM.currentDonation != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveTrackingMapScreen(donation: donationVM.currentDonation!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Delivery Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RouteOptimizationViewModel>().fetchOptimizedRoute(),
          ),
        ],
      ),
      body: Consumer<RouteOptimizationViewModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (model.errorMessage != null) {
            return Center(child: Text(model.errorMessage!));
          }

          if (model.tasks.isEmpty) {
            return const Center(child: Text('No active tasks assigned.'));
          }

          return ListView.builder(
            itemCount: model.tasks.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final task = model.tasks[index];
              final bool isPickup = task['type'] == 'pickup';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPickup ? Colors.green[100] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPickup ? 'PICKUP' : 'DELIVERY',
                              style: TextStyle(
                                color: isPickup ? Colors.green[800] : Colors.blue[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            'Stop #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task['foodName'] ?? 'Food Donation',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task['address'] ?? 'Address unknown',
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isPickup && task['bestBeforeTime'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${DateFormat('hh:mm a').format(DateTime.parse(task['bestBeforeTime']))}',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navigateToTracking(task['id']),
                          child: Text(isPickup ? 'GO TO PICKUP' : 'GO TO DELIVERY'),
                        ),
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
