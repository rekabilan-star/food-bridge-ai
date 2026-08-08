import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';

class UserProfileModal {
  static void show(BuildContext context) {
    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Header Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleName(user.role).toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Information Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, "Email", user.email),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.phone_android_outlined, "Phone", user.phoneNumber.isNotEmpty ? user.phoneNumber : "Not provided"),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.location_on_outlined, "Address", user.address ?? "Location set via GPS"),
                  if (user.status != null) ...[
                    const Divider(height: 20),
                    _buildInfoRow(Icons.verified_user_outlined, "Account Status", user.status!.toUpperCase()),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthViewModel>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  "LOGOUT / SIGN OUT",
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  static Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.donor: return AppColors.donorColor;
      case UserRole.ngo: return AppColors.ngoColor;
      case UserRole.admin: return AppColors.adminColor;
      default: return AppColors.primary;
    }
  }

  static String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.donor: return "Authorized Donor";
      case UserRole.ngo: return "NGO Partner";
      case UserRole.admin: return "System Admin";
      default: return "Verified User";
    }
  }
}
