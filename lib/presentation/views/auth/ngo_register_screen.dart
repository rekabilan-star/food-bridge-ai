import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/errors/location_exception.dart';
import '../../../core/utils/validators.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/custom_app_bar.dart';

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

  String _selectedIdType = 'Aadhaar Card';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Location Data Required"),
        content: Text(error.message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
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
              child: const Text("OPEN SETTINGS"),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _pickManualLocation();
              },
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
      );

      if (!mounted) return;

      if (success) {
        UIUtils.showSuccessDialog(
          context, 
          "Application Submitted! Our team will review your NGO documentation shortly.",
          onOk: () => Navigator.pop(context),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, size: 32, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Partner with FoodBridge AI",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader("ORGANIZATION DETAILS"),
                    ModernTextField(
                      controller: _nameController,
                      label: "Official NGO Name",
                      prefixIcon: Icons.business_rounded,
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 14),
                    
                    _buildSectionHeader("PERSONAL IDENTITY VERIFICATION"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIdType,
                      decoration: InputDecoration(
                        labelText: "Personal ID Document Type",
                        prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                    const SizedBox(height: 14),

                    InkWell(
                      onTap: () => _pickFile(false),
                      borderRadius: BorderRadius.circular(18),
                      child: _buildDocTile(
                        _idFile == null ? "Upload $_selectedIdType Proof" : "$_selectedIdType Uploaded ✓", 
                        Icons.upload_file_rounded, 
                        _idFile != null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader("ACCOUNT"),
                    ModernTextField(
                      controller: _emailController,
                      label: "Work Email",
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 14),
                    ModernTextField(
                      controller: _passwordController,
                      label: "Password",
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 14),
                    ModernTextField(
                      controller: _phoneController,
                      label: "Contact Phone",
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 14),
                    ModernTextField(
                      controller: _addressController,
                      label: "HQ Address",
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => Validators.validateRequired(v, "Address"),
                    ),

                    const SizedBox(height: 20),

                    _buildLocationBox(locationProvider),

                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: "SUBMIT APPLICATION",
                      isLoading: authVM.isLoading,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDocTile(String label, IconData icon, bool isUploaded) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUploaded ? AppColors.success.withValues(alpha: 0.08) : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isUploaded ? AppColors.success : AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isUploaded ? AppColors.success : AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: isUploaded ? AppColors.success : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (isUploaded) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationBox(LocationProviderV2 provider) {
    final hasLocation = provider.location != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasLocation ? AppColors.success.withValues(alpha: 0.06) : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasLocation ? AppColors.success.withValues(alpha: 0.3) : AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(hasLocation ? Icons.check_circle_rounded : Icons.gps_fixed_rounded, color: hasLocation ? AppColors.success : AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? "Location Verified" : "HQ GPS Identity", 
                      style: TextStyle(fontWeight: FontWeight.w700, color: hasLocation ? AppColors.success : AppColors.textPrimary, fontSize: 14),
                    ),
                    Text(
                      hasLocation ? "Organization HQ locked" : "Precise location required", 
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _startLocationCapture, 
                child: Text(hasLocation ? "REFRESH" : "VERIFY", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
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
                    hasLocation ? "Wrong location? Fix on Map" : "Pick from Map manually", 
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
