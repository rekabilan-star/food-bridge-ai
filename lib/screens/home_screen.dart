import 'package:flutter/material.dart';
import 'add_donation_screen.dart';
import 'donation_history_screen.dart';
import 'impact_analytics_screen.dart';
import 'profile_screen.dart';
import 'ngo/food_requests_screen.dart';
import 'ngo/manage_volunteers_screen.dart';
import 'ngo/delivery_history_screen.dart';
import 'volunteer/assigned_tasks_screen.dart';
import 'volunteer/live_tracking_screen.dart';
import 'volunteer/job_board_screen.dart';
import 'admin/manage_users_screen.dart';
import 'admin/manage_ngos_screen.dart';
import 'admin/manage_volunteers_screen.dart';
import 'admin/reports_screen.dart';
import 'common/notification_screen.dart';
import '../services/data_service.dart';
import '../models/donation_request.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, this.role = 'DONOR'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardView(role: widget.role),
      const DonationHistoryScreen(),
      const ImpactAnalyticsScreen(),
      ProfileScreen(role: widget.role),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _getThemeColor(widget.role),
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 20,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Impact'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Account'),
        ],
      ),
    );
  }

  Color _getThemeColor(String role) {
    switch (role) {
      case 'NGO': return Colors.orange;
      case 'VOLUNTEER': return Colors.deepPurple;
      case 'ADMIN': return Colors.red;
      default: return Colors.green;
    }
  }
}

class DashboardView extends StatelessWidget {
  final String role;
  const DashboardView({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    String welcomeMessage = 'Welcome back, Kabil!';
    String fabLabel = 'DONATE';
    IconData fabIcon = Icons.add;
    Color themeColor = Colors.green;

    if (role == 'NGO') {
      welcomeMessage = 'NGO Dashboard';
      fabLabel = 'REQUESTS';
      fabIcon = Icons.list_alt;
      themeColor = Colors.orange;
    } else if (role == 'VOLUNTEER') {
      welcomeMessage = 'Volunteer Portal';
      fabLabel = 'TASKS';
      fabIcon = Icons.delivery_dining;
      themeColor = Colors.deepPurple;
    } else if (role == 'ADMIN') {
      welcomeMessage = 'Admin Panel';
      fabLabel = 'REPORTS';
      fabIcon = Icons.assessment;
      themeColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$role Dashboard', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Monitoring your food waste impact', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())), 
            icon: const Icon(Icons.notifications_none, color: Colors.black87)
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: themeColor,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        color: themeColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                welcomeMessage,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),

              // Dynamic Role-Based Content
              if (role == 'DONOR') _buildDonorSection(context, themeColor),
              if (role == 'NGO') _buildNgoSection(context, themeColor),
              if (role == 'VOLUNTEER') _buildVolunteerSection(context, themeColor),
              if (role == 'ADMIN') _buildAdminSection(context, themeColor),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {}, 
                    child: Text('View All', style: TextStyle(color: themeColor, fontWeight: FontWeight.w600))
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<List<DonationRequest>>(
                stream: DataService().donationStream,
                initialData: DataService().currentDonations,
                builder: (context, snapshot) {
                  final activities = snapshot.data ?? [];
                  if (activities.isEmpty) return const Center(child: Text('No recent activity'));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length > 5 ? 5 : activities.length,
                    itemBuilder: (context, index) {
                      final item = activities[index];
                      final isPending = item.status == 'pending';
                      final color = isPending ? Colors.orange : themeColor;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(role == 'VOLUNTEER' ? Icons.local_shipping_outlined : Icons.fastfood_outlined, color: color, size: 24),
                          ),
                          title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.restaurantName} • ${item.status.toUpperCase()}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(item.quantity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(item.status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (role == 'DONOR') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDonationScreen()));
          } else if (role == 'NGO') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodRequestsScreen()));
          } else if (role == 'VOLUNTEER') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignedTasksScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReportsScreen()));
          }
        },
        backgroundColor: themeColor,
        icon: Icon(fabIcon, color: Colors.white),
        label: Text(fabLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDonorSection(BuildContext context, Color themeColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMainStatCard('Daily Waste', '12.5 kg', Icons.delete_outline, themeColor.withValues(alpha: 0.1), themeColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildMainStatCard('Points', '450 pts', Icons.stars_outlined, Colors.blue.withValues(alpha: 0.1), Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        _buildWideStatCard('CO2 Saved', '25 kg CO2 saved', Icons.eco_outlined, themeColor.withValues(alpha: 0.1), themeColor),
        const SizedBox(height: 16),
        _buildQuickActionCard(context, 'New Donation', 'Donate your surplus food now', Icons.add_circle_outline, themeColor, const AddDonationScreen()),
      ],
    );
  }

  Widget _buildNgoSection(BuildContext context, Color themeColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMainStatCard('Total Recvd', '450 kg', Icons.inventory_2_outlined, themeColor.withValues(alpha: 0.1), themeColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildMainStatCard('Pending', '12 req', Icons.pending_actions, Colors.orange.withValues(alpha: 0.1), Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        _buildWideStatCard('Volunteers', '8 active nearby', Icons.people_outline, themeColor.withValues(alpha: 0.1), themeColor),
        const SizedBox(height: 16),
        _buildQuickActionCard(context, 'Manage Volunteers', 'Coordinate with local helpers', Icons.people_alt, themeColor, const ManageVolunteersScreen()),
        const SizedBox(height: 12),
        _buildQuickActionCard(context, 'Delivery History', 'Track all incoming donations', Icons.history, themeColor, const NgoDeliveryHistoryScreen()),
      ],
    );
  }

  Widget _buildVolunteerSection(BuildContext context, Color themeColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMainStatCard('Completed', '24 tasks', Icons.done_all, themeColor.withValues(alpha: 0.1), themeColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildMainStatCard('Earnings', '850 pts', Icons.monetization_on_outlined, Colors.amber.withValues(alpha: 0.1), Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),
        _buildWideStatCard('Distance', '142 km traveled', Icons.route_outlined, themeColor.withValues(alpha: 0.1), themeColor),
        const SizedBox(height: 16),
        _buildQuickActionCard(context, 'Browse Jobs', 'Find pickups near you', Icons.explore_outlined, themeColor, const VolunteerJobBoard()),
        const SizedBox(height: 12),
        _buildQuickActionCard(context, 'Active Navigation', 'Optimized route for current task', Icons.map_outlined, themeColor, const LiveTrackingScreen(destination: 'Current Task')),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildMainStatCard('Total Users', '1,250', Icons.people_outline, themeColor.withValues(alpha: 0.1), themeColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildMainStatCard('Food Saved', '4.2 Tons', Icons.eco_outlined, Colors.green.withValues(alpha: 0.1), Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        _buildWideStatCard('Pending Verifications', '14 NGOs awaiting approval', Icons.verified_user_outlined, themeColor.withValues(alpha: 0.1), themeColor),
        const SizedBox(height: 24),
        const Text('System Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildManagementTile(context, Icons.people_alt_outlined, 'Manage Users', 'Search and moderate members', const ManageUsersScreen()),
        _buildManagementTile(context, Icons.home_work_outlined, 'Manage NGOs', 'Verify and manage organizations', const ManageNgosScreen()),
        _buildManagementTile(context, Icons.assignment_ind_outlined, 'Manage Volunteers', 'Oversee delivery fleet', const ManageVolunteersAdminScreen()),
        _buildManagementTile(context, Icons.assessment_outlined, 'Global Analytics', 'Export reports & statistics', const AdminReportsScreen()),
      ],
    );
  }

  Widget _buildMainStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWideStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, String sub, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(sub, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile(BuildContext context, IconData icon, String title, String subtitle, Widget screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
        leading: Icon(icon, color: Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
