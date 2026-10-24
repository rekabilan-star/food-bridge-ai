import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/standard_card.dart';
import '../common/widgets/status_badge.dart';

class NgoApprovalPendingScreen extends StatefulWidget {
  const NgoApprovalPendingScreen({super.key});

  @override
  State<NgoApprovalPendingScreen> createState() => _NgoApprovalPendingScreenState();
}

class _NgoApprovalPendingScreenState extends State<NgoApprovalPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().refreshApprovalStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;
    final isApproved = (user?.status ?? 'pending').toLowerCase() == 'approved';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Account Status",
        onBackPressed: () async {
          await authVm.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Graphic / Status Card
                StandardCard(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    children: [
                      AppSpacing.vGapMd,
                      AppIconContainer(
                        icon: isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: AppIcons.sizeXxl,
                        color: isApproved ? AppColors.success : AppColors.warning,
                        backgroundColor: isApproved
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        padding: 24,
                      ).animate().scale(duration: 500.ms),

                      AppSpacing.vGapLg,

                      Text(
                        isApproved ? "Application Approved" : "Approval Pending",
                        style: AppTypography.pageTitle,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms),

                      AppSpacing.vGapSm,

                      StatusBadge(
                        status: isApproved ? "APPROVED" : "PENDING",
                        label: isApproved ? "STATUS: ACCOUNT APPROVED" : "STATUS: ADMIN REVIEW IN PROGRESS",
                      ),

                      AppSpacing.vGapLg,

                      Text(
                        isApproved
                            ? "Congratulations ${user?.name ?? 'NGO Partner'}! Your NGO application has been approved by our Admin team. You can now access the NGO Dashboard and accept food rescue requests."
                            : "Welcome ${user?.name ?? 'NGO Partner'}! Your NGO application has been submitted successfully.\n\nOur Admin team is reviewing your registration details and documents. You will receive access to the Rescue Control Room as soon as your account is approved.",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      AppSpacing.vGapXl,

                      if (isApproved) ...[
                        PrimaryButton(
                          text: "CONTINUE TO NGO DASHBOARD",
                          icon: Icons.dashboard_rounded,
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/ngo-dashboard');
                          },
                        ),
                      ] else ...[
                        PrimaryButton(
                          text: "CHECK APPROVAL STATUS",
                          icon: Icons.refresh_rounded,
                          isLoading: authVm.isLoading,
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
                        ),
                      ],

                      AppSpacing.vGapMd,

                      SecondaryButton(
                        text: "SIGN OUT",
                        icon: Icons.logout_rounded,
                        onPressed: () async {
                          await authVm.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                      AppSpacing.vGapSm,
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
