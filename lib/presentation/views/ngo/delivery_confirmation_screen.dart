import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../services/location_service.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/primary_button.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final DonationModel donation;
  const DeliveryConfirmationScreen({super.key, required this.donation});

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _membersController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _membersController.text = widget.donation.membersServed.toString();
    _addressController.text = widget.donation.pickupAddress;
  }

  @override
  void dispose() {
    _membersController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (!mounted) return;
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final loc = await LocationService().getProductionLocation(
        onProgress: (msg) => debugPrint("Delivery Location: $msg"),
      );
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
          if (loc.fullAddress.isNotEmpty) {
            _addressController.text = loc.fullAddress;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      if (_image == null) {
        UIUtils.showErrorDialog(context, "Please capture a distribution confirmation photo.");
        return;
      }

      setState(() => _isSubmitting = true);
      final viewModel = context.read<DonationViewModel>();

      // 1. Get Location
      double finalLat = widget.donation.latitude;
      double finalLng = widget.donation.longitude;
      try {
        final loc = await LocationService().getProductionLocation(
          onProgress: (msg) => debugPrint("Delivery Location: $msg"),
        );
        finalLat = loc.latitude;
        finalLng = loc.longitude;
      } catch (e) {
        debugPrint("Delivery location capture failed: $e");
      }

      // 2. Upload photo
      final photoUrl = await viewModel.uploadImage(_image!);
      if (!mounted) return;

      if (photoUrl == null) {
        setState(() => _isSubmitting = false);
        UIUtils.showErrorDialog(context, "Image upload failed. Please verify your connection.");
        return;
      }

      final success = await viewModel.confirmDelivery(widget.donation.id, {
        'photoUrl': photoUrl,
        'address': _addressController.text.trim(),
        'latitude': finalLat,
        'longitude': finalLng,
        'membersServed': int.tryParse(_membersController.text.trim()) ?? widget.donation.membersServed,
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        UIUtils.showSuccessDialog(
          context,
          "Donation Completed! Thank you for rescuing and distributing food to the community.",
          onOk: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
      } else {
        UIUtils.showErrorDialog(context, viewModel.errorMessage ?? "Completion failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DonationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Confirm Delivery"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo upload container
              Text("Distribution Proof Photo", style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Capture food handover to beneficiaries or shelter staff.",
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _image == null ? AppColors.border : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              "Tap to Take Distribution Photo",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Camera capture required for verified proof",
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text("Retake Photo", style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Distribution Location
              ModernTextField(
                controller: _addressController,
                label: "Distribution Location",
                hint: "e.g., Community Shelter, North Hall",
                prefixIcon: Icons.location_on_outlined,
                suffixIcon: _isDetectingLocation
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
                        tooltip: "Detect live location",
                        onPressed: _detectLocation,
                      ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please specify location" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Actual Members Served
              ModernTextField(
                controller: _membersController,
                label: "Actual Members Served",
                hint: "e.g., 50",
                prefixIcon: Icons.people_outline_rounded,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter count" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Notes
              ModernTextField(
                controller: _notesController,
                label: "Delivery & Distribution Notes",
                hint: "e.g., Food distributed warmly to 45 children and 5 volunteers",
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              PrimaryButton(
                text: "COMPLETE DONATION MISSION",
                icon: Icons.check_circle_rounded,
                isLoading: viewModel.isLoading || _isSubmitting,
                onPressed: (viewModel.isLoading || _isSubmitting) ? null : _submit,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
