import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'donor_register_screen.dart';
import 'ngo_register_screen.dart';

import '../../../core/utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthViewModel>().login(
        _emailController.text,
        _passwordController.text,
      );
      if (success) {
        if (!mounted) return;
        final user = context.read<AuthViewModel>().user;
        final role = user?.role.toString().split('.').last;
        
        if (role == 'donor') {
          Navigator.pushReplacementNamed(context, '/donor-dashboard');
        } else if (role == 'ngo') {
          Navigator.pushReplacementNamed(context, '/ngo-dashboard');
        } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          UIUtils.showErrorDialog(context, "Unknown User Role");
        }
      } else {
        if (!mounted) return;
        UIUtils.showErrorDialog(
          context, 
          context.read<AuthViewModel>().errorMessage ?? "Login Failed"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, size: 64, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Welcome Back",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login to continue food rescue",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _login,
                  child: authViewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOGIN"),
                ),
                const SizedBox(height: 40),
                const Center(child: Text("Don't have an account?")),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorRegisterScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("AS DONOR"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NgoRegisterScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.ngoColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("AS NGO", style: TextStyle(color: AppColors.ngoColor)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
