import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/primary_button.dart';

class DistributionProofScreen extends StatefulWidget {
  const DistributionProofScreen({super.key});

  @override
  State<DistributionProofScreen> createState() => _DistributionProofScreenState();
}

class _DistributionProofScreenState extends State<DistributionProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servedController = TextEditingController();
  final _notesController = TextEditingController();
  File? _deliveryImage;

  @override
  void dispose() {
    _servedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _deliveryImage = File(picked.path));
  }

  void _completeDistribution() {
    if (_formKey.currentState!.validate() && _deliveryImage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text("Thank You!", style: AppTypography.sectionHeading),
          content: Text(
            "You have successfully rescued and distributed food. This impact has been recorded.",
            style: AppTypography.bodyMedium,
          ),
          actions: [
            PrimaryButton(
              text: "BACK TO DASHBOARD",
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      );
    } else if (_deliveryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload delivery photo"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Proof of Distribution"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Step 7: Proof of Distribution", style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Rescuing food is only half the work. Let's record the impact for transparency.",
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildImageUploader(),
              const SizedBox(height: AppSpacing.lg),
              ModernTextField(
                controller: _servedController,
                label: "Approx. Members Served",
                hint: "e.g., 40",
                prefixIcon: Icons.people_outline_rounded,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: AppSpacing.md),
              ModernTextField(
                controller: _notesController,
                label: "Distribution Notes",
                hint: "Where and to whom was food delivered?",
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: "COMPLETE DISTRIBUTION",
                icon: Icons.check_circle_rounded,
                onPressed: _completeDistribution,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _deliveryImage == null ? AppColors.border : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: _deliveryImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Add Distribution Photo",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.file(_deliveryImage!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
