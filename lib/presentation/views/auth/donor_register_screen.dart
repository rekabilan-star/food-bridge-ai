import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/utils/validators.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/custom_app_bar.dart';

class DonorRegisterScreen extends StatefulWidget {
  const DonorRegisterScreen({super.key});

  @override
  State<DonorRegisterScreen> createState() => _DonorRegisterScreenState();
}

class _DonorRegisterScreenState extends State<DonorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locProvider = Provider.of<LocationProviderV2>(context, listen: false);
        locProvider.fetchLocation().then((_) {
          _onLocationDetected();
        });
        locProvider.addListener(_onLocationDetected);
      }
    });
  }

  void _onLocationDetected() {
    if (!mounted) return;
    final locProvider = Provider.of<LocationProviderV2>(context, listen: false);
    if (locProvider.location != null && !locProvider.isLoading) {
      if (locProvider.location!.fullAddress.isNotEmpty) {
        setState(() {
          _addressController.text = locProvider.location!.fullAddress;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<LocationProviderV2>(context, listen: false).removeListener(_onLocationDetected);
    } catch (_) {}
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final locProvider = context.read<LocationProviderV2>();
      
      if (locProvider.location == null) {
        UIUtils.showErrorDialog(
          context, 
          "Location Required: Your real-time location is mandatory for rescue logistics. Please enable GPS or select on map.",
        );
        return;
      }

      final location = locProvider.location!;

      final success = await context.read<AuthViewModel>().registerDonor(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.isEmpty ? location.fullAddress : _addressController.text.trim(),
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) return;

      if (success) {
        UIUtils.showSuccessDialog(
          context, 
          "Success! Your account is active. Start saving food now.",
          onOk: () => Navigator.pop(context),
        );
      } else {
        UIUtils.showErrorDialog(context, context.read<AuthViewModel>().errorMessage ?? "Registration failed.");
      }
    }
  }

  void _pickManualLocation() async {
    final locProvider = context.read<LocationProviderV2>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualLocationPicker(
          initialLat: locProvider.location?.latitude,
          initialLng: locProvider.location?.longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      locProvider.setManualLocation(result);
      setState(() {
        _addressController.text = result.fullAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final locProvider = context.watch<LocationProviderV2>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(
        title: "Create Donor Account",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Join the Rescue Movement",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    ModernTextField(
                      controller: _nameController,
                      label: "Full Name",
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.validateName,
                    ),

                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: _emailController,
                      label: "Email Address",
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: _passwordController,
                      label: "Create Password",
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),

                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: _addressController,
                      label: "Business/Home Address",
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => Validators.validateRequired(v, "Address"),
                    ),

                    const SizedBox(height: 20),

                    _buildLocationBox(locProvider),

                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: "GET STARTED",
                      isLoading: authVM.isLoading || locProvider.isLoading,
                      onPressed: _register,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBox(LocationProviderV2 provider) {
    final bool hasLocation = provider.location != null;
    final bool isError = provider.error != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasLocation ? AppColors.success.withValues(alpha: 0.06) : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLocation ? AppColors.success.withValues(alpha: 0.3) : (isError ? AppColors.error.withValues(alpha: 0.3) : AppColors.border),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.check_circle_rounded : (isError ? Icons.location_off_rounded : Icons.gps_fixed_rounded), 
                color: hasLocation ? AppColors.success : (isError ? AppColors.error : AppColors.primary), 
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isLoading 
                          ? "Detecting location..." 
                          : (hasLocation ? "Location Verified" : (isError ? "Detection Failed" : "GPS Location")), 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        color: hasLocation ? AppColors.success : (isError ? AppColors.error : AppColors.textPrimary), 
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasLocation) ...[
                      Text(
                        provider.accuracyStatus,
                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Lat: ${provider.location!.latitude.toStringAsFixed(4)} | Lng: ${provider.location!.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ] else
                      Text(
                        isError ? provider.error!.message : "Real-time verification required", 
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (!provider.isLoading)
                IconButton(
                  onPressed: () async {
                    await provider.fetchLocation();
                    if (mounted && provider.location != null) {
                      setState(() {
                        _addressController.text = provider.location!.fullAddress;
                      });
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                  tooltip: "Refresh GPS & Auto-fill Address",
                )
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          InkWell(
            onTap: _pickManualLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    hasLocation ? "Not your location? Fix on Map" : "Unable to detect? Pick on Map",
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
