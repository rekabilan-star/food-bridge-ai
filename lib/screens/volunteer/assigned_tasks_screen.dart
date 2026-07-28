import 'package:flutter/material.dart';
import 'live_tracking_screen.dart';
import 'qr_scanner_view.dart';
import '../../services/data_service.dart';
import '../../models/donation_request.dart';

class AssignedTasksScreen extends StatelessWidget {
  const AssignedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Delivery Tasks'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DonationRequest>>(
        stream: DataService().donationStream,
        initialData: DataService().currentDonations,
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final assignedTasks = allTasks.where((t) => t.status == 'assigned_to_volunteer').toList();

          if (assignedTasks.isEmpty) {
            return const Center(child: Text('No active tasks assigned to you.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignedTasks.length,
            itemBuilder: (context, index) {
              final task = assignedTasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.delivery_dining, color: Colors.white),
                  ),
                  title: Text('Pickup: ${task.restaurantName}'),
                  subtitle: Text('Status: ${task.status.replaceAll('_', ' ').toUpperCase()}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTaskStep(Icons.location_on, 'Go to Pickup Location', task.address, true),
                          _buildTaskStep(Icons.qr_code_scanner, 'Verify Pickup', 'Scan Donor QR Code', false),
                          _buildTaskStep(Icons.navigation, 'Deliver to NGO', 'Aurobindo Orphanage', false),
                          _buildTaskStep(Icons.verified, 'Verify Delivery', 'Scan NGO QR Code', false),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LiveTrackingScreen(
                                    destination: 'Aurobindo Orphanage',
                                    donationId: task.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('START NAVIGATION'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              _showQRScanner(context, task.id);
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('SCAN TO VERIFY'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskStep(IconData icon, String title, String sub, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: isDone ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.black)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  void _showQRScanner(BuildContext context, String taskId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerView(title: 'Verify Pickup/Delivery'),
      ),
    );

    if (result == true) {
      // Simulation: Update status on successful scan
      DataService().updateDonationStatus(taskId, 'picked_up');
    }
  }
}
