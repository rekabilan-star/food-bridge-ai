import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';

class NgoApprovalPendingScreen extends StatelessWidget {
  const NgoApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () async {
            await authVm.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        title: const Text(
          "Account Status",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 64,
                  color: Colors.amber.shade800,
                ),
              ).animate().scale(duration: 500.ms),

              const SizedBox(height: 28),

              Text(
                "Approval Pending",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "STATUS: ADMIN REVIEW IN PROGRESS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Welcome ${user?.name ?? 'NGO Partner'}! Your NGO application has been submitted successfully.\n\nOur Admin team is reviewing your registration details and documents. You will receive access to the Rescue Control Room as soon as your account is approved.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              // Check Live Approval Status Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final approved = await authVm.refreshApprovalStatus();
                    if (!context.mounted) return;
                    if (approved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Account Approved! Welcome to Rescue Control.")),
                      );
                      Navigator.pushReplacementNamed(context, '/ngo-dashboard');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Application is still under admin review. Please try again shortly.")),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("CHECK APPROVAL STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Demo / Admin Simulation Button for instant testing
              OutlinedButton.icon(
                onPressed: () {
                  authVm.simulateNgoAdminApproval();
                  Navigator.pushReplacementNamed(context, '/ngo-dashboard');
                },
                icon: const Icon(Icons.verified_user_rounded, size: 18),
                label: const Text(
                  "SIMULATE ADMIN APPROVAL (DEMO TEST)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () async {
                  await authVm.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundLight,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
