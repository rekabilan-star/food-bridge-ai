import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'manage_ngos_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AdminViewModel>().stats;
    final isLoading = context.watch<AdminViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Control Center"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminViewModel>().fetchDashboardStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "System Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isLoading && stats.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard("Total Donors", stats['totalDonors']?.toString() ?? "0", Icons.person, Colors.blue),
                    _buildStatCard("NGO Partners", stats['totalNGOs']?.toString() ?? "0", Icons.handshake, Colors.orange),
                    _buildStatCard("Pending NGOs", stats['pendingNGOs']?.toString() ?? "0", Icons.pending_actions, Colors.red, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageNgosScreen()));
                    }),
                    _buildStatCard("Active Tasks", stats['activeDonations']?.toString() ?? "0", Icons.local_shipping, Colors.green),
                    _buildStatCard("Completed", stats['completedDonations']?.toString() ?? "0", Icons.check_circle, Colors.teal),
                    _buildStatCard("Today", stats['todayDonations']?.toString() ?? "0", Icons.today, Colors.purple),
                  ],
                ),
              const SizedBox(height: 32),
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildActionTile("Manage NGO Approvals", "Approve or reject new NGO registrations", Icons.verified_user, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageNgosScreen()));
              }),
              _buildActionTile("Emergency Requests", "Monitor and manage urgent food needs", Icons.campaign, Colors.red, () {}),
              _buildActionTile("Donation History", "View all donation activities in the system", Icons.history, Colors.blue, () {}),
              _buildActionTile("System Reports", "Download monthly impact and distribution reports", Icons.analytics, Colors.teal, () {}),
              _buildActionTile("User Management", "View and manage all registered users", Icons.manage_accounts, Colors.purple, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
