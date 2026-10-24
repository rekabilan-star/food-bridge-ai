import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/ui_utils.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/standard_card.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resendOTP() async {
    final vm = context.read<AuthViewModel>();
    final success = await vm.forgotPassword(widget.email);
    if (success) {
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A new recovery code has been dispatched.")),
        );
      }
    }
  }

  void _submit() async {
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      UIUtils.showErrorDialog(context, "Please enter the valid 6-digit recovery code");
      return;
    }
    if (newPassword.isEmpty || newPassword.length < 6) {
      UIUtils.showErrorDialog(context, "Password must be at least 6 characters");
      return;
    }

    final vm = context.read<AuthViewModel>();
    final success = await vm.resetPassword(widget.email, otp, newPassword);

    if (!mounted) return;

    if (success) {
      UIUtils.showSuccessDialog(
        context,
        "Password updated successfully! Please sign in with your new credentials.",
        onOk: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
      );
    } else if (vm.errorMessage != null) {
      UIUtils.showErrorDialog(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Verify & Reset",
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.vGapMd,

              // Top Header Graphic
              Center(
                child: const AppIconContainer(
                  icon: Icons.shield_rounded,
                  size: AppIcons.sizeXxl,
                  color: AppColors.primary,
                  backgroundColor: AppColors.accent,
                  padding: 20,
                ),
              ).animate().scale(duration: 400.ms),

              AppSpacing.vGapBase,

              Center(
                child: Text(
                  "Verify Account",
                  style: AppTypography.pageTitle,
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 100.ms),

              AppSpacing.vGapXs,

              Center(
                child: Text(
                  "Security code sent to ${widget.email}. Enter the code below to set your new password.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ).animate().fadeIn(delay: 150.ms),

              AppSpacing.vGapLg,

              // Form Card
              StandardCard(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("6-Digit Code", style: AppTypography.fieldLabel),
                    AppSpacing.vGapXs,
                    ModernTextField(
                      controller: _otpController,
                      label: "Recovery Code",
                      hint: "Enter 6-digit code",
                      prefixIcon: Icons.vpn_key_rounded,
                      keyboardType: TextInputType.number,
                    ),

                    AppSpacing.vGapBase,

                    Text("New Password", style: AppTypography.fieldLabel),
                    AppSpacing.vGapXs,
                    ModernTextField(
                      controller: _passwordController,
                      label: "New Password",
                      hint: "Enter new password",
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),

                    AppSpacing.vGapBase,

                    // Password Requirements Validator
                    FlutterPwValidator(
                      controller: _passwordController,
                      minLength: 6,
                      uppercaseCharCount: 1,
                      numericCharCount: 1,
                      width: 400,
                      height: 110,
                      onSuccess: () {},
                      onFail: () {},
                    ),

                    AppSpacing.vGapBase,

                    // Resend Timer Row
                    Center(
                      child: _resendTimer > 0
                          ? Text(
                              "Resend code in ${_resendTimer}s",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : TextButton(
                              onPressed: vm.isLoading ? null : _resendOTP,
                              child: Text(
                                "RESEND CODE",
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                    ),

                    AppSpacing.vGapBase,

                    PrimaryButton(
                      text: "UPDATE PASSWORD",
                      isLoading: vm.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

              AppSpacing.vGapXl,
            ],
          ),
        ),
      ),
    );
  }
}
