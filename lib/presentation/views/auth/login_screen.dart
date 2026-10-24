import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/services/security_service.dart';
import '../../../data/models/user_model.dart';
import 'ngo_approval_pending_screen.dart';
import 'forgot_password_screen.dart';
import 'donor_register_screen.dart';
import 'ngo_register_screen.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/standard_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Email Login Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await SecurityService.canCheckBiometrics();
    final enabled = await SecurityService.getBiometricPref();
    if (canCheck && enabled && _rememberMe) {
      _loginWithBiometrics();
    }
  }

  void _loginWithBiometrics() async {
    final success = await context.read<AuthViewModel>().authenticateWithBiometrics();
    if (!mounted) return;
    if (success) {
      _navigateToDashboard();
    }
  }

  void _loginWithEmail() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final authVm = context.read<AuthViewModel>();

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('saved_email', email);
      } else {
        await prefs.remove('saved_email');
      }

      if (!mounted) return;
      final success = await authVm.login(email, password);

      if (success) {
        _navigateToDashboard();
      } else {
        if (!mounted) return;
        UIUtils.showErrorDialog(context, authVm.errorMessage ?? "Invalid Email or Password");
      }
    }
  }

  void _navigateToDashboard() async {
    if (!mounted) return;
    final authVm = context.read<AuthViewModel>();
    await authVm.refreshApprovalStatus();
    if (!mounted) return;

    final user = authVm.user;
    if (user == null) return;

    final role = user.role;
    if (role == UserRole.donor) {
      Navigator.pushReplacementNamed(context, '/donor-dashboard');
    } else if (role == UserRole.ngo) {
      final status = (user.status ?? 'approved').toLowerCase();
      if (status == 'pending') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NgoApprovalPendingScreen()),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/ngo-dashboard');
      }
    } else if (role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }
  }

  void _showRoleSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.sheetTop,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppSpacing.vGapBase,
                Text(
                  "Create an Account",
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionHeading,
                ),
                AppSpacing.vGapXs,
                Text(
                  "Choose your role to get started with FoodBridge AI",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.vGapLg,
                StandardCard(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonorRegisterScreen()),
                    );
                  },
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      const AppIconContainer(
                        icon: Icons.volunteer_activism_rounded,
                        color: AppColors.primary,
                        backgroundColor: AppColors.accent,
                        size: AppIcons.sizeMd,
                      ),
                      AppSpacing.hGapBase,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Register as Donor", style: AppTypography.subsectionHeading),
                            AppSpacing.vGapXs,
                            Text(
                              "Donate surplus food from restaurant, event, or home",
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: AppIcons.sizeMd,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapSm,
                StandardCard(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NgoRegisterScreen()),
                    );
                  },
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      const AppIconContainer(
                        icon: Icons.shield_rounded,
                        color: AppColors.ngoColor,
                        backgroundColor: Color(0xFFE0F2FE),
                        size: AppIcons.sizeMd,
                      ),
                      AppSpacing.hGapBase,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Register as NGO Partner", style: AppTypography.subsectionHeading),
                            AppSpacing.vGapXs,
                            Text(
                              "Rescue and distribute food to local communities",
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: AppIcons.sizeMd,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapBase,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Sign In",
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/splash');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vGapLg,

                // Top Header Graphic / Logo
                Center(
                  child: const AppIconContainer(
                    icon: Icons.volunteer_activism_rounded,
                    size: AppIcons.sizeXxl,
                    color: AppColors.primary,
                    backgroundColor: AppColors.accent,
                    padding: 20,
                  ),
                ).animate().scale(duration: 400.ms),

                AppSpacing.vGapBase,

                // Title & Subtitle
                Center(
                  child: Text(
                    "Sign In to FoodBridge",
                    style: AppTypography.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                AppSpacing.vGapXs,

                Center(
                  child: Text(
                    "Enter your registered Email & Password to continue",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                AppSpacing.vGapXl,

                // Sign-In Card Container
                StandardCard(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Address Field
                      Text(
                        "Email Address",
                        style: AppTypography.fieldLabel,
                      ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _emailController,
                        label: "Email Address",
                        hint: "donor@example.com",
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your registered email";
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return "Please enter a valid email address";
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut),

                      AppSpacing.vGapBase,

                      // Password Field
                      Text(
                        "Password",
                        style: AppTypography.fieldLabel,
                      ).animate().fadeIn(delay: 280.ms, duration: 350.ms),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "Enter password",
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 280.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut),

                      AppSpacing.vGapSm,

                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                AppSpacing.hGapXs,
                                Flexible(
                                  child: Text(
                                    "Remember Me",
                                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 340.ms, duration: 350.ms),

                      AppSpacing.vGapLg,

                      // Primary Login Button
                      PrimaryButton(
                        text: "SIGN IN",
                        isLoading: authViewModel.isLoading,
                        onPressed: _loginWithEmail,
                      ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
                    ],
                  ),
                ),

                AppSpacing.vGapLg,

                // Register Link Row
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => _showRoleSelectionBottomSheet(context),
                      child: Text(
                        "Sign Up",
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
