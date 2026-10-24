import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/ui_utils.dart';
import 'reset_password_screen.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/standard_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<AuthViewModel>();
      final email = _emailController.text.trim();
      final success = await vm.forgotPassword(email);
      if (!mounted) return;
      if (success) {
        UIUtils.showSuccessDialog(
          context,
          "Recovery code dispatched for $email. Enter the code on the next screen to set your new password.",
          onOk: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)));
          },
        );
      } else if (vm.errorMessage != null) {
        UIUtils.showErrorDialog(context, vm.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Forgot Password",
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vGapXl,

                // Top Header Graphic
                Center(
                  child: const AppIconContainer(
                    icon: Icons.lock_reset_rounded,
                    size: AppIcons.sizeXxl,
                    color: AppColors.primary,
                    backgroundColor: AppColors.accent,
                    padding: 20,
                  ),
                ).animate().scale(duration: 400.ms),

                AppSpacing.vGapBase,

                Center(
                  child: Text(
                    "Reset Password",
                    style: AppTypography.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                AppSpacing.vGapXs,

                Center(
                  child: Text(
                    "Enter your registered email address and we'll send you a recovery code to verify your account.",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                AppSpacing.vGapXl,

                // Main Form Card
                StandardCard(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Registered Email", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _emailController,
                        label: "Email Address",
                        hint: "donor@example.com",
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Please enter your registered email";
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return "Please enter a valid email address";
                          }
                          return null;
                        },
                      ),

                      AppSpacing.vGapLg,

                      PrimaryButton(
                        text: "SEND RECOVERY CODE",
                        isLoading: vm.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                AppSpacing.vGapLg,

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Remember your password? ",
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Sign In",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
