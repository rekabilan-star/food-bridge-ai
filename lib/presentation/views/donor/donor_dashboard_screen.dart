import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'donate_food_screen.dart';
import 'qr_display_screen.dart';
import '../common/donation_tracking_screen.dart';
import '../../../core/utils/intent_utils.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonorDonations();
      context.read<EmergencyViewModel>().fetchActiveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final donationViewModel = context.watch<DonationViewModel>();
    final emergencyViewModel = context.watch<EmergencyViewModel>();
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await donationViewModel.fetchDonorDonations();
          await emergencyViewModel.fetchActiveRequests();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.name ?? "Donor"),
              const SizedBox(height: 32),
              _buildEmergencyRequests(emergencyViewModel),
              const SizedBox(height: 32),
              _buildActionCard(context),
              const SizedBox(height: 32),
              Text(
                "Your Active Donations",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              donationViewModel.isLoading && donationViewModel.donations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : donationViewModel.donations.isEmpty
                      ? _buildEmptyState()
                      : _buildDonationList(donationViewModel.donations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyRequests(EmergencyViewModel viewModel) {
    if (viewModel.requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign, color: Colors.red),
            const SizedBox(width: 8),
            Text("Emergency Requests", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.requests.length,
            itemBuilder: (context, index) {
              final request = viewModel.requests[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  color: Colors.red[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.withValues(alpha: 0.2))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(request.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: Text(request.priority, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(request.reason, style: TextStyle(color: Colors.grey[700], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Need: ${request.requiredMembers} members", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 30)),
                              child: const Text("HELP", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary,
          child: Text(name[0],
              style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello,", style: TextStyle(color: Colors.grey[600])),
            Text(name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volunteer_activism, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text(
            "Share Your Surplus Food",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Connect with nearby NGOs to serve those in need.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DonateFoodScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(160, 50),
            ),
            child: const Text("DONATE NOW"),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationList(List donations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                donation.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200], child: const Icon(Icons.fastfood)),
              ),
            ),
            title: Text(donation.foodName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Serves ${donation.membersServed} Members"),
            trailing: _buildStatusChip(donation.status),
            onTap: () {
                if (donation.status == 'waiting') {
                    // Show details
                } else if (donation.status == 'completed') {
                    // Show summary
                } else {
                    // Track or show QR
                    _showOptions(context, donation);
                }
            },
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context, dynamic donation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Donation Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text("Track NGO Partner"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)));
              },
            ),
            if (donation.assignedNgoPhone != null) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text("Call NGO Partner"),
                onTap: () {
                  Navigator.pop(context);
                  IntentUtils.makePhoneCall(donation.assignedNgoPhone);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.orange),
                title: const Text("WhatsApp NGO Partner"),
                onTap: () {
                  Navigator.pop(context);
                  IntentUtils.sendWhatsAppMessage(donation.assignedNgoPhone, "Hello, regarding my donation: ${donation.foodName}");
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.orange),
              title: const Text("Show Pickup QR"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(donation: donation)));
              },
            ),
            if (donation.status == 'waiting')
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text("Cancel Donation", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showCancelDialog(context, donation);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, dynamic donation) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Donation?"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Reason for cancellation"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP IT")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final success = await context.read<DonationViewModel>().cancelDonation(donation.id, controller.text);
              if (success) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("CANCEL DONATION"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'waiting': color = Colors.orange; break;
      case 'accepted': color = Colors.blue; break;
      case 'on_the_way': color = Colors.blue; break;
      case 'arrived': color = Colors.orange; break;
      case 'picked_up': color = Colors.purple; break;
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.no_food, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No donations yet", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
