import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import 'reset_password_screen.dart';
import '../common/widgets/glass_container.dart';

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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFormCard(vm),
                          const SizedBox(height: 40),
                        ],
                      ),
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_reset_rounded, size: 48, color: Colors.white),
            ).animate().scale(duration: 500.ms),
            const SizedBox(height: 24),
            const Text("Reset Password", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text("Enter your registered email address and we'll send you a recovery code.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 40),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              validator: (v) => v!.isEmpty || !v.contains('@') ? "Enter a valid email" : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: vm.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: vm.isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) 
                  : const Text("SEND RECOVERY CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }
}
