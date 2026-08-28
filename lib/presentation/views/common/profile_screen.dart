import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../data/models/user_model.dart';
import 'edit_profile_screen.dart';
import 'impact_analytics_screen.dart';
import 'donation_history_screen.dart';
import 'widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(
        title: "Profile",
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Profile Card Header
            _buildProfileHeaderCard(user).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Rescue Impact Action Summary
            _buildImpactBanner(context).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // Rescuer Badges & Achievements Section
            _buildSectionHeader("RESCUER BADGES & ACHIEVEMENTS"),
            _buildBadgesSection().animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // Account Settings Group
            _buildSectionHeader("ACCOUNT SETTINGS"),
            _buildSettingsGroup([
              _buildSettingTile("Edit Profile", Icons.person_outline_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              }),
              _buildSettingTile("Donation History", Icons.history_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationHistoryScreen()));
              }),
              _buildSettingTile("Impact Analytics", Icons.bar_chart_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactAnalyticsScreen()));
              }),
              _buildSettingTile("Log Out", Icons.logout_rounded, () {
                authVm.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }, iconColor: AppColors.error),
            ]),

            const SizedBox(height: 24),

            // Security & Preferences Group
            _buildSectionHeader("PREFERENCES & SECURITY"),
            _buildSettingsGroup([
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text(
                  "Biometric Auth",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                value: authVm.biometricEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => authVm.toggleBiometrics(val),
              ),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dark_mode_outlined, color: AppColors.primary, size: 20),
                ),
                title: const Text(
                  "Dark Mode (UI Only)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                value: _darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _darkMode = val;
                  });
                },
              ),
            ]),

            const SizedBox(height: 32),

            // Primary Logout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  UIUtils.showConfirmationDialog(
                    context: context,
                    title: "Log Out of Account?",
                    message: "Are you sure you want to end your current session?",
                    confirmText: "LOGOUT",
                    confirmColor: AppColors.error,
                    onConfirm: () {
                      authVm.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: const Text(
                  "LOG OUT OF ACCOUNT",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.accent,
              backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
              child: user.profileImage == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.name.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactAnalyticsScreen())),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Impact Score",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "View your food rescue contributions",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap, {Color? iconColor}) {
    final color = iconColor ?? AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: iconColor ?? AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildBadgesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBadgeChip("Zero Waste", Icons.eco_rounded, Colors.green, true),
          _buildBadgeChip("Hero Donor", Icons.verified_user_rounded, AppColors.primary, true),
          _buildBadgeChip("Top Rescuer", Icons.star_rounded, Colors.amber, true),
          _buildBadgeChip("Master Saver", Icons.military_tech_rounded, Colors.purple, false),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, IconData icon, Color color, bool unlocked) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unlocked ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: unlocked ? color.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: unlocked ? color : Colors.grey, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: unlocked ? AppColors.textPrimary : Colors.grey,
          ),
        ),
      ],
    );
  }
}
