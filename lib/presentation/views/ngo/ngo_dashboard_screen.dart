import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'ngo_donation_requests_screen.dart';
import 'ngo_tracking_screen.dart';
import 'emergency_request_screen.dart';
import '../../../data/models/donation_model.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchNgoAssignedDonations();
      context.read<EmergencyViewModel>().fetchActiveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final viewModel = context.watch<DonationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO Dashboard"),
        actions: [
          _buildAvailabilityToggle(context, user),
          IconButton(
            onPressed: () async {
              await context.read<AuthViewModel>().logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final donationVM = context.read<DonationViewModel>();
          final emergencyVM = context.read<EmergencyViewModel>();
          await donationVM.fetchNgoAssignedDonations();
          await emergencyVM.fetchActiveRequests();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.name ?? "NGO Partner"),
              const SizedBox(height: 24),
              _buildEmergencyButton(context),
              const SizedBox(height: 24),
              _buildStatusCard(context),
              const SizedBox(height: 32),
              const Text("Your Active Tasks",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (viewModel.isLoading && viewModel.assignedDonations.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.assignedDonations.isEmpty)
                _buildEmptyState()
              else
                _buildActiveTasksList(viewModel.assignedDonations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle(BuildContext context, dynamic user) {
    String status = user?.availabilityStatus ?? 'Available';
    Color color = status == 'Available' ? Colors.green : (status == 'Busy' ? Colors.orange : Colors.grey);

    return PopupMenuButton<String>(
      onSelected: (value) {
        // In real app, call a viewModel method to update status
        // context.read<AuthViewModel>().updateAvailability(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Available', child: Text("Available")),
        const PopupMenuItem(value: 'Busy', child: Text("Busy")),
        const PopupMenuItem(value: 'Offline', child: Text("Offline")),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 6),
            Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyRequestScreen())),
      icon: const Icon(Icons.campaign, color: Colors.white),
      label: const Text("CREATE EMERGENCY REQUEST"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56)),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.ngoColor,
            child: Text(name[0],
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hello,", style: TextStyle(color: Colors.grey[600])),
          Text(name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ngoColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.ngoColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active,
                color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("New Requests Nearby",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        "Click to view AI recommended food rescue opportunities.",
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTasksList(List<DonationModel> tasks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                task.imageUrl,
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.restaurant)),
              ),
            ),
            title: Text(task.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Status: ${task.status.replaceAll('_', ' ')}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: task.id)));
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(children: [
            Icon(Icons.local_shipping_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No active pickups",
                style: TextStyle(color: Colors.grey[600])),
          ]),
        ),
      ),
    );
  }
}
