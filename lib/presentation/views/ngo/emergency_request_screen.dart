import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../../data/repositories/emergency_repository.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/standard_card.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _membersController = TextEditingController();
  final _addressController = TextEditingController();

  String _foodType = 'Any';
  String _priority = 'High';
  DateTime _requiredBefore = DateTime.now().add(const Duration(hours: 3));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    _titleController.dispose();
    _reasonController.dispose();
    _membersController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      final locProvider = context.read<LocationProviderV2>();
      final lat = locProvider.location?.latitude ?? 13.0827;
      final lng = locProvider.location?.longitude ?? 80.2707;

      final success = await context.read<EmergencyViewModel>().createRequest(
            EmergencyRequestModel(
              id: '',
              ngoId: '',
              title: _titleController.text.trim(),
              reason: _reasonController.text.trim(),
              requiredMembers: int.tryParse(_membersController.text.trim()) ?? 10,
              foodType: _foodType,
              address: _addressController.text.trim(),
              latitude: lat,
              longitude: lng,
              requiredBefore: _requiredBefore,
              priority: _priority,
              status: 'active',
            ),
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        UIUtils.showSuccessDialog(
          context,
          "Emergency broadcast sent successfully! Nearby donors and restaurants have been alerted.",
          onOk: () => Navigator.pop(context),
        );
      } else {
        UIUtils.showErrorDialog(
          context,
          context.read<EmergencyViewModel>().errorMessage ?? "Failed to broadcast emergency request",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProviderV2>();
    final emergencyVM = context.watch<EmergencyViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Emergency Broadcast"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Info Banner
              StandardCard(
                backgroundColor: AppColors.error.withValues(alpha: 0.06),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Immediate Community Hunger Need",
                            style: AppTypography.subsectionHeading.copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "All registered food donors and restaurants within 20 KM will receive high-priority alerts.",
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title Field
              ModernTextField(
                controller: _titleController,
                label: "Request Title",
                hint: "e.g., Food for flood relief camp or night shelter",
                prefixIcon: Icons.title_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter a title" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Reason Field
              ModernTextField(
                controller: _reasonController,
                label: "Reason & Context",
                hint: "Describe who needs meals and the urgency...",
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please provide context" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Members & Food Type Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: _membersController,
                      label: "Members in Need",
                      hint: "e.g., 50",
                      prefixIcon: Icons.people_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Food Type", style: AppTypography.fieldLabel),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _foodType,
                              items: ['Any', 'Veg', 'Non-Veg']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodyMedium)))
                                  .toList(),
                              onChanged: (v) => setState(() => _foodType = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Priority Level
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Priority Level", style: AppTypography.fieldLabel),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _priority,
                        items: ['High', 'Medium', 'Low']
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: p == 'High'
                                            ? AppColors.error
                                            : (p == 'Medium' ? AppColors.warning : AppColors.success),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(p, style: AppTypography.bodyMedium),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Delivery Address
              ModernTextField(
                controller: _addressController,
                label: "Distribution / Delivery Address",
                hint: "Enter destination address...",
                prefixIcon: Icons.location_on_outlined,
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
                validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter an address" : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Required Before Time Picker
              _buildTimePicker(),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              PrimaryButton(
                text: "BROADCAST EMERGENCY ALERT",
                icon: Icons.campaign_rounded,
                isLoading: emergencyVM.isLoading || _isSubmitting,
                onPressed: (emergencyVM.isLoading || _isSubmitting) ? null : _submit,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_requiredBefore),
        );
        if (picked != null) {
          final now = DateTime.now();
          setState(() {
            _requiredBefore = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
          });
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.timer_outlined, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Meals Required Before", style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a (Today)').format(_requiredBefore),
                  style: AppTypography.subsectionHeading,
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
