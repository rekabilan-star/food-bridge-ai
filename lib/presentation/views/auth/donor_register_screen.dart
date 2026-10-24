import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/utils/validators.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/standard_card.dart';

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
          "Success! Your account is active. Please log in to start saving food.",
          onOk: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
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
      appBar: CustomAppBar(
        title: "Create Donor Account",
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
                AppSpacing.vGapMd,

                // Top Header Graphic
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

                Center(
                  child: Text(
                    "Join the Rescue Movement",
                    style: AppTypography.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                AppSpacing.vGapXs,

                Center(
                  child: Text(
                    "Register as a food donor to connect surplus food with local communities",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                AppSpacing.vGapLg,

                // Main Form Card
                StandardCard(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Full Name", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _nameController,
                        label: "Full Name",
                        hint: "Enter your full name",
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.validateName,
                      ),

                      AppSpacing.vGapBase,

                      Text("Email Address", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _emailController,
                        label: "Email Address",
                        hint: "donor@example.com",
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),

                      AppSpacing.vGapBase,

                      Text("Create Password", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _passwordController,
                        label: "Create Password",
                        hint: "At least 6 characters",
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: Validators.validatePassword,
                      ),

                      AppSpacing.vGapBase,

                      Text("Phone Number", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        hint: "Enter 10-digit mobile number",
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),

                      AppSpacing.vGapBase,

                      Text("Pickup Address", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _addressController,
                        label: "Pickup Address",
                        hint: "Restaurant, business, or residential address",
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) => Validators.validateRequired(v, "Address"),
                      ),

                      AppSpacing.vGapLg,

                      // Location Verification Panel
                      _buildLocationBox(locProvider),

                      AppSpacing.vGapXl,

                      PrimaryButton(
                        text: "REGISTER AS DONOR",
                        isLoading: authVM.isLoading || locProvider.isLoading,
                        onPressed: _register,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBox(LocationProviderV2 provider) {
    final bool hasLocation = provider.location != null;
    final bool isError = provider.error != null;
    final statusColor = hasLocation 
        ? AppColors.success 
        : (isError ? AppColors.error : AppColors.primary);

    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: hasLocation 
            ? AppColors.success.withValues(alpha: 0.05) 
            : (isError ? AppColors.error.withValues(alpha: 0.05) : AppColors.backgroundLight),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: hasLocation 
              ? AppColors.success.withValues(alpha: 0.3) 
              : (isError ? AppColors.error.withValues(alpha: 0.3) : AppColors.border),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: hasLocation 
                    ? Icons.check_circle_rounded 
                    : (isError ? Icons.location_off_rounded : Icons.gps_fixed_rounded),
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                size: AppIcons.sizeSm,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isLoading 
                          ? "Detecting location..." 
                          : (hasLocation ? "Location Verified" : (isError ? "Detection Failed" : "GPS Location")), 
                      style: AppTypography.subsectionHeading.copyWith(
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    if (hasLocation) ...[
                      Text(
                        provider.accuracyStatus,
                        style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Lat: ${provider.location!.latitude.toStringAsFixed(4)} | Lng: ${provider.location!.longitude.toStringAsFixed(4)}",
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ] else
                      Text(
                        isError ? provider.error!.message : "Real-time verification required for rescue logistics", 
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: AppIcons.sizeMd),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.border),
          ),
          InkWell(
            onTap: _pickManualLocation,
            borderRadius: AppRadius.borderMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, size: AppIcons.sizeSm, color: AppColors.primary),
                  AppSpacing.hGapXs,
                  Flexible(
                    child: Text(
                      hasLocation ? "Not your location? Fix on Map" : "Unable to detect? Pick on Map",
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
