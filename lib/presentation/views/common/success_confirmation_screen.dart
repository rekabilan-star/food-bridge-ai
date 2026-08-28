import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/primary_button.dart';
import 'widgets/secondary_button.dart';

class SuccessConfirmationScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;
  final String donationId;
  final String status;
  final String estimatedPickup;

  const SuccessConfirmationScreen({
    super.key,
    this.title = "Donation Successful!",
    this.message = "Thank you for your kindness.\nYou are making a difference. 💜",
    required this.onContinue,
    this.donationId = "FDB-2026-0516-0012",
    this.status = "Completed",
    this.estimatedPickup = "Today, 6:00 PM",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Animated Checkmark Ring Badge (Panel 6 Reference)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer soft glow ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    // Inner glow ring
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    // Solid Purple Circle Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 10),

              // Subtitle Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const Spacer(flex: 1),

              // Donation Details Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Donation ID Row with Copy button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Donation ID",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              donationId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: donationId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Donation ID copied to clipboard")),
                            );
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 24, color: AppColors.border),

                    // Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          status,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Estimated Pickup Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Estimated Pickup",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          estimatedPickup,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

              const Spacer(flex: 2),

              // Action Buttons
              PrimaryButton(
                text: "View My Donations",
                onPressed: onContinue,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 14),

              SecondaryButton(
                text: "Back to Home",
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/donor-dashboard', (route) => false);
                },
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
