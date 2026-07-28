import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(user),
            const SizedBox(height: 32),
            if (user.role == UserRole.ngo) _buildNgoStats(user)
            else _buildDonorStats(user),
            const SizedBox(height: 32),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: user.role == UserRole.ngo ? AppColors.ngoColor : AppColors.primary,
          child: Text(user.name[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (user.role == UserRole.ngo && user.status == 'approved')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.verified, color: Colors.blue, size: 20),
              ),
          ],
        ),
        Text(user.email, style: const TextStyle(color: Colors.grey)),
        if (user.role == UserRole.ngo)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.star, color: Colors.amber, size: 16),
                 Text(" ${user.averageRating.toStringAsFixed(1)} (${user.totalRatings} ratings)", style: const TextStyle(fontWeight: FontWeight.bold)),
               ],
             ),
           ),
      ],
    );
  }

  Widget _buildDonorStats(UserModel user) {
    return Row(
      children: [
        _buildStatCard("Total Donations", "12", Icons.volunteer_activism, Colors.green),
        const SizedBox(width: 16),
        _buildStatCard("Served", "450", Icons.people, Colors.blue),
      ],
    );
  }

  Widget _buildNgoStats(UserModel user) {
    return Row(
      children: [
        _buildStatCard("Pickups", "24", Icons.local_shipping, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard("Verified", "Yes", Icons.verified_user, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _buildActionTile("Edit Profile", Icons.edit_outlined, () {}),
        _buildActionTile("Notification Settings", Icons.notifications_none, () {}),
        _buildActionTile("Help & Support", Icons.help_outline, () {}),
        _buildActionTile("Logout", Icons.logout, () {
          context.read<AuthViewModel>().logout();
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }, isDestructive: true),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}
