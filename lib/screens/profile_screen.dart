import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'common/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  const ProfileScreen({super.key, this.role = 'DONOR'});

  @override
  Widget build(BuildContext context) {
    Color themeColor = Colors.green;
    if (role == 'NGO') themeColor = Colors.orange;
    if (role == 'VOLUNTEER') themeColor = Colors.deepPurple;
    if (role == 'ADMIN') themeColor = Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(themeColor),
            const SizedBox(height: 24),
            _buildSettingsList(context, themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color themeColor) {
    String rank = 'Gold Donor';
    if (role == 'NGO') rank = 'Verified Partner';
    if (role == 'VOLUNTEER') rank = 'Elite Courier';
    if (role == 'ADMIN') rank = 'System Superuser';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: themeColor,
              child: const Icon(Icons.person, size: 70, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Kabilan R', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('kabilan@example.com', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(rank, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.person_outline, 'Personal Details', themeColor, () {}),
          if (role == 'DONOR') _buildSettingsTile(Icons.favorite_outline, 'My Impact Goals', themeColor, () {}),
          if (role == 'VOLUNTEER') _buildSettingsTile(Icons.directions_bike, 'Vehicle Details', themeColor, () {}),
          if (role == 'NGO') _buildSettingsTile(Icons.verified_user_outlined, 'NGO Certifications', themeColor, () {}),
          if (role == 'NGO') _buildSettingsTile(Icons.storage_rounded, 'Capacity Management', themeColor, () => _showCapacityDialog(context, themeColor)),
          _buildSettingsTile(Icons.settings_outlined, 'Settings', themeColor, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', themeColor, () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Color themeColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCapacityDialog(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capacity Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set your current storage capacity for food acceptance.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            _buildCapacityOption('High Availability', 'Can accept >50kg', Icons.battery_full, Colors.green),
            _buildCapacityOption('Limited Space', 'Only <10kg remaining', Icons.battery_charging_full, Colors.orange),
            _buildCapacityOption('At Capacity', 'Cannot accept more today', Icons.battery_alert, Colors.red),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  Widget _buildCapacityOption(String title, String sub, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: () {},
    );
  }
}
