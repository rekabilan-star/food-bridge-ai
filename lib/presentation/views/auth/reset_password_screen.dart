import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import '../common/widgets/glass_container.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A new code has been dispatched.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildFormCard(vm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthViewModel vm) {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.shield_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 24),
          const Text("Verify Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text("Security code sent to ${widget.email}", 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 40),
          _buildTextField(
            controller: _otpController,
            label: "6-Digit Code",
            icon: Icons.vpn_key_rounded,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: "New Password",
            icon: Icons.lock_rounded,
            isPassword: true,
            obscureText: !_isPasswordVisible,
            onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 16),
          Theme(
            data: ThemeData.dark(),
            child: FlutterPwValidator(
              controller: _passwordController,
              minLength: 6,
              uppercaseCharCount: 1,
              numericCharCount: 1,
              width: 400,
              height: 120,
              onSuccess: () {},
              onFail: () {},
            ),
          ),
          const SizedBox(height: 32),
          if (_resendTimer > 0)
            Text("Resend code in ${_resendTimer}s", style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold))
          else
            TextButton(
              onPressed: vm.isLoading ? null : _resendOTP,
              child: const Text("RESEND CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: vm.isLoading ? null : () async {
              final success = await vm.resetPassword(widget.email, _otpController.text.trim(), _passwordController.text.trim());
              if (!context.mounted) return;
              if (success) {
                if (!mounted) return;
                UIUtils.showSuccessDialog(context, "Password updated successfully! Please sign in with your new password.", onOk: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false));
              } else if (vm.errorMessage != null) {
                if (!mounted) return;
                UIUtils.showErrorDialog(context, vm.errorMessage!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            child: vm.isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) 
                : const Text("UPDATE PASSWORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixTap,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        counterStyle: const TextStyle(color: Colors.white60, fontSize: 10),
        suffixIcon: isPassword 
            ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70), onPressed: onSuffixTap)
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}
