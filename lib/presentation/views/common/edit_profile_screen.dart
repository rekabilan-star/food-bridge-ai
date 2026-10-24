import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../data/models/user_model.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/standard_card.dart';
import '../common/widgets/status_badge.dart';
import '../common/widgets/section_heading.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().user!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _addressController = TextEditingController(text: user.address ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locProvider = Provider.of<LocationProviderV2>(context, listen: false);
        if (locProvider.location == null) {
          locProvider.fetchLocation().then((_) {
            _onLocationDetected();
          });
        }
        locProvider.addListener(_onLocationDetected);
      }
    });
  }

  void _onLocationDetected() {
    if (!mounted) return;
    final locProvider = Provider.of<LocationProviderV2>(context, listen: false);
    if (locProvider.location != null && !locProvider.isLoading) {
      if (locProvider.location!.fullAddress.isNotEmpty && _addressController.text.trim().isEmpty) {
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
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final authVm = context.read<AuthViewModel>();

      final success = await authVm.updateProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        if (success) {
          UIUtils.showSuccessDialog(
            context,
            "Profile updated successfully!",
            onOk: () => Navigator.pop(context),
          );
        } else {
          UIUtils.showErrorDialog(context, authVm.errorMessage ?? "Update failed");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user!;
    final isLoading = context.watch<AuthViewModel>().isLoading;
    final locProvider = context.watch<LocationProviderV2>();
    final isNgo = user.role == UserRole.ngo;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with camera badge
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user.profileImage != null ? NetworkImage(user.profileImage!) : null) as ImageProvider?,
                      child: _imageFile == null && user.profileImage == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                              style: AppTypography.pageTitle.copyWith(color: AppColors.primary, fontSize: 36),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Personal / Organization Info
              ModernTextField(
                controller: _nameController,
                label: isNgo ? "Organization Name" : "Full Name",
                hint: isNgo ? "e.g., Hope Food Bank" : "e.g., John Doe",
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              ModernTextField(
                controller: _phoneController,
                label: "Phone Number",
                hint: "e.g., +91 9876543210",
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              ModernTextField(
                controller: _addressController,
                label: "Operational Address",
                hint: "Enter your registered premises address",
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                suffixIcon: locProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                        tooltip: "Auto-detect live GPS location",
                        onPressed: () async {
                          await locProvider.fetchLocation();
                          if (mounted && locProvider.location != null) {
                            setState(() {
                              _addressController.text = locProvider.location!.fullAddress;
                            });
                          }
                        },
                      ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              // NGO Operational Capacity Section
              if (isNgo) ...[
                const SizedBox(height: AppSpacing.xl),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SectionHeading(title: "NGO Operational Settings"),
                ),
                const SizedBox(height: AppSpacing.sm),
                StandardCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _buildNgoDetailRow(
                        "Registration Number",
                        user.ngoRegistrationNumber ?? "Pending Verification",
                        Icons.verified_user_outlined,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildNgoDetailRow(
                        "Max Daily Capacity",
                        "${user.maxDailyMeals > 0 ? user.maxDailyMeals : '50'} meals/day",
                        Icons.restaurant_menu_rounded,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text("Accepted Foods:", style: AppTypography.bodySmall),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: user.acceptedCategories.isNotEmpty
                                ? Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: user.acceptedCategories
                                        .map((c) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent.withValues(alpha: 0.4),
                                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                              ),
                                              child: Text(
                                                c,
                                                style: AppTypography.captionBold.copyWith(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  )
                                : Text("All Categories", style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text("Account Status:", style: AppTypography.bodySmall),
                            ],
                          ),
                          StatusBadge(
                            status: user.status ?? 'pending',
                            label: (user.status ?? 'PENDING').toUpperCase(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Save Changes
              PrimaryButton(
                text: "SAVE PROFILE CHANGES",
                icon: Icons.check_circle_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _save,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNgoDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
