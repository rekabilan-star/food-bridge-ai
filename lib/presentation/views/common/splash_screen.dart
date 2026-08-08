import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/primary_button.dart';
import 'widgets/secondary_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isAutoChecking = true;

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    debugPrint('[STARTUP] SplashScreen _navigateToNext started');
    try {
      final authVM = context.read<AuthViewModel>();
      await authVM.checkLoginStatus().timeout(const Duration(seconds: 4), onTimeout: () {
        debugPrint('[STARTUP ERROR] checkLoginStatus timed out');
      });
    } catch (e) {
      debugPrint('[STARTUP ERROR] Splash init: $e');
    }
    
    await Future.delayed(2000.ms);
    
    if (!mounted) return;

    final authVM = context.read<AuthViewModel>();
    
    if (authVM.user != null) {
      final role = authVM.user!.role;
      if (role == UserRole.donor) {
        Navigator.pushReplacementNamed(context, '/donor-dashboard');
      } else if (role == UserRole.ngo) {
        Navigator.pushReplacementNamed(context, '/ngo-dashboard');
      } else if (role == UserRole.admin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      if (mounted) {
        setState(() {
          _isAutoChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Top Logo Circular Card
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              // Title & Tagline
              Text(
                "FoodBridge AI",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                "Zero Waste. Zero Hunger.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ).animate().fadeIn(delay: 300.ms),

              const Spacer(flex: 2),

              // Soft Illustration Box Card
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBF8FF), Color(0xFFF3E8FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 48),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 28),
                            const SizedBox(width: 12),
                            Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

              const Spacer(flex: 2),

              if (_isAutoChecking)
                const SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else
                Column(
                  children: [
                    PrimaryButton(
                      text: "Get Started",
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 14),
                    SecondaryButton(
                      text: "I already have an account",
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
