import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/errors/location_exception.dart';
import '../../../core/utils/validators.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/standard_card.dart';

class NgoRegisterScreen extends StatefulWidget {
  const NgoRegisterScreen({super.key});

  @override
  State<NgoRegisterScreen> createState() => _NgoRegisterScreenState();
}

class _NgoRegisterScreenState extends State<NgoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _maxMealsController = TextEditingController(text: '50');

  String _selectedIdType = 'Aadhaar Card';
  final List<String> _acceptedCategories = ['Cooked Meal'];

  File? _idFile;

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
      if (locProvider.location!.fullAddress.isNotEmpty && _addressController.text.isEmpty) {
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
    _regNumberController.dispose();
    _maxMealsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isCert) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _idFile = File(pickedFile.path);
      });
    }
  }

  void _startLocationCapture() async {
    final locProvider = Provider.of<LocationProviderV2>(context, listen: false);
    await locProvider.fetchLocation();
    if (mounted && locProvider.location != null) {
      setState(() {
        _addressController.text = locProvider.location!.fullAddress;
      });
    } else if (locProvider.error != null) {
      _handleLocationError(locProvider.error!);
    }
  }

  void _handleLocationError(LocationException error) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        title: Text("Location Data Required", style: AppTypography.subsectionHeading),
        content: Text(error.message, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          if (error.type == LocationErrorType.permissionDeniedForever || error.type == LocationErrorType.serviceDisabled)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (error.type == LocationErrorType.serviceDisabled) {
                  Geolocator.openLocationSettings();
                } else {
                  Geolocator.openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("OPEN SETTINGS"),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _pickManualLocation();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("PICK MANUALLY"),
            ),
        ],
      ),
    );
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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final location = context.read<LocationProviderV2>().location;

      if (location == null) {
        UIUtils.showErrorDialog(context, "Verification Failed: Organization headquarters location is required.");
        return;
      }

      if (_idFile == null) {
        UIUtils.showErrorDialog(context, "Personal ID Document Required: Please upload your $_selectedIdType proof document.");
        return;
      }

      final authVM = context.read<AuthViewModel>();

      final success = await authVM.registerNgo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.isEmpty ? location.fullAddress : _addressController.text.trim(),
        latitude: location.latitude,
        longitude: location.longitude,
        regNumber: _selectedIdType,
        certificateUrl: _idFile!.path,
        idProofUrl: _idFile!.path,
        acceptedCategories: _acceptedCategories,
        maxDailyMeals: int.tryParse(_maxMealsController.text) ?? 0,
      );

      if (!mounted) return;

      if (success) {
        UIUtils.showSuccessDialog(
          context,
          "Application Submitted! Our team will review your NGO documentation shortly. Please log in with your credentials.",
          onOk: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
        );
      } else {
        UIUtils.showErrorDialog(context, authVM.errorMessage ?? "Registration Error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final locationProvider = context.watch<LocationProviderV2>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "NGO Partner Application",
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
                    icon: Icons.shield_rounded,
                    size: AppIcons.sizeXxl,
                    color: AppColors.ngoColor,
                    backgroundColor: Color(0xFFE0F2FE),
                    padding: 20,
                  ),
                ).animate().scale(duration: 400.ms),

                AppSpacing.vGapBase,

                Center(
                  child: Text(
                    "Partner with FoodBridge AI",
                    style: AppTypography.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                AppSpacing.vGapXs,

                Center(
                  child: Text(
                    "Join verified rescue organizations delivering meals to communities in need",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                AppSpacing.vGapLg,

                // Main Form Card
                StandardCard(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Organization Details
                      _buildSectionHeader("ORGANIZATION DETAILS"),
                      Text("Official NGO Name", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _nameController,
                        label: "Official NGO Name",
                        hint: "Registered NGO or Foundation Name",
                        prefixIcon: Icons.business_rounded,
                        validator: Validators.validateName,
                      ),

                      AppSpacing.vGapLg,

                      // Section 2: Identity / Verification
                      _buildSectionHeader("IDENTITY VERIFICATION"),
                      Text("Personal ID Document Type", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIdType,
                        style: AppTypography.bodyLarge.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primary, size: AppIcons.sizeSm),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderLg,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderLg,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderLg,
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Aadhaar Card', child: Text("Aadhaar Card")),
                          DropdownMenuItem(value: 'Driving License', child: Text("Driving License")),
                          DropdownMenuItem(value: 'Ration Card', child: Text("Ration Card")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedIdType = val;
                            });
                          }
                        },
                      ),

                      AppSpacing.vGapMd,

                      InkWell(
                        onTap: () => _pickFile(false),
                        borderRadius: AppRadius.borderLg,
                        child: _buildDocTile(
                          _idFile == null ? "Upload $_selectedIdType Proof" : "$_selectedIdType Uploaded ✓",
                          Icons.upload_file_rounded,
                          _idFile != null,
                        ),
                      ),

                      AppSpacing.vGapLg,

                      // Section 3: Account & Contact
                      _buildSectionHeader("ACCOUNT & CONTACT"),
                      Text("Work Email", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _emailController,
                        label: "Work Email",
                        hint: "ngo@organization.org",
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),

                      AppSpacing.vGapBase,

                      Text("Password", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "At least 6 characters",
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: Validators.validatePassword,
                      ),

                      AppSpacing.vGapBase,

                      Text("Contact Phone", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _phoneController,
                        label: "Contact Phone",
                        hint: "Enter official contact number",
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),

                      AppSpacing.vGapBase,

                      Text("Headquarters Address", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _addressController,
                        label: "HQ Address",
                        hint: "Street address, area, city",
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) => Validators.validateRequired(v, "Address"),
                      ),

                      AppSpacing.vGapLg,

                      // Section 4: Operational Capacity
                      _buildSectionHeader("OPERATIONAL CAPACITY"),
                      Text("Max Daily Meal Capacity", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      ModernTextField(
                        controller: _maxMealsController,
                        label: "Max Daily Meal Capacity",
                        hint: "e.g. 50",
                        prefixIcon: Icons.restaurant_menu_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateRequired(v, "Daily Capacity"),
                      ),

                      AppSpacing.vGapBase,

                      Text("Accepted Food Categories", style: AppTypography.fieldLabel),
                      AppSpacing.vGapXs,
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          'Cooked Meal',
                          'Bakery Items',
                          'Raw Materials',
                          'Fruits/Veggies',
                          'Other'
                        ].map((cat) {
                          final isSelected = _acceptedCategories.contains(cat);
                          return FilterChip(
                            label: Text(
                              cat,
                              style: AppTypography.caption.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _acceptedCategories.add(cat);
                                } else {
                                  _acceptedCategories.remove(cat);
                                }
                              });
                            },
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            backgroundColor: AppColors.backgroundLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMd,
                              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                            ),
                          );
                        }).toList(),
                      ),

                      AppSpacing.vGapLg,

                      // Section 5: HQ GPS Verification
                      _buildSectionHeader("HEADQUARTERS LOCATION"),
                      _buildLocationBox(locationProvider),

                      AppSpacing.vGapXl,

                      PrimaryButton(
                        text: "SUBMIT APPLICATION",
                        isLoading: authVM.isLoading,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSpacing.hGapXs,
          Text(
            title,
            style: AppTypography.badge.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(String label, IconData icon, bool isUploaded) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUploaded ? AppColors.success.withValues(alpha: 0.06) : AppColors.backgroundLight,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: isUploaded ? AppColors.success : AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          AppIconContainer(
            icon: icon,
            color: isUploaded ? AppColors.success : AppColors.primary,
            backgroundColor: isUploaded ? AppColors.success.withValues(alpha: 0.15) : AppColors.accent,
            size: AppIcons.sizeSm,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isUploaded ? AppColors.success : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isUploaded) ...[
            AppSpacing.hGapXs,
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: AppIcons.sizeSm),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationBox(LocationProviderV2 provider) {
    final hasLocation = provider.location != null;
    final statusColor = hasLocation ? AppColors.success : AppColors.primary;

    return Container(
      padding: AppSpacing.paddingBase,
      decoration: BoxDecoration(
        color: hasLocation ? AppColors.success.withValues(alpha: 0.05) : AppColors.backgroundLight,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: hasLocation ? AppColors.success.withValues(alpha: 0.3) : AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: hasLocation ? Icons.check_circle_rounded : Icons.gps_fixed_rounded,
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
                      hasLocation ? "Location Verified" : "HQ GPS Identity",
                      style: AppTypography.subsectionHeading.copyWith(
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      hasLocation ? "Organization HQ locked" : "Precise location required for 20 KM eligibility",
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _startLocationCapture,
                child: Text(
                  hasLocation ? "REFRESH" : "VERIFY",
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                      hasLocation ? "Wrong location? Fix on Map" : "Pick from Map manually",
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
