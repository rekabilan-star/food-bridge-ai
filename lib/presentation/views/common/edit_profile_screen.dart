import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/location_provider_v2.dart';

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
    _addressController = TextEditingController(text: user.address);

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
          UIUtils.showSuccessDialog(context, "Profile updated successfully!", onOk: () => Navigator.pop(context));
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

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (user.profileImage != null ? NetworkImage(user.profileImage!) : null) as ImageProvider?,
                      child: _imageFile == null && user.profileImage == null 
                        ? const Icon(Icons.person, size: 60) 
                        : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Address", 
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: locProvider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                          tooltip: "Auto-detect Live GPS Location",
                          onPressed: () async {
                            await locProvider.fetchLocation();
                            if (mounted && locProvider.location != null) {
                              setState(() {
                                _addressController.text = locProvider.location!.fullAddress;
                              });
                            }
                          },
                        ),
                ),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SAVE CHANGES"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
