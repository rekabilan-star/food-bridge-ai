import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/location_loading_dialog.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';

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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startLocationCapture() async {
    final locationProvider = context.read<LocationProviderV2>();
    locationProvider.fetchLocation();
    if (!mounted) return;
    LocationLoadingDialog.show(context);
    
    // Listen for completion or error
    void listener() {
      if (locationProvider.error != null) {
        locationProvider.removeListener(listener);
        // Optional: Auto-open manual picker on error
        // _pickManualLocation(); 
      } else if (locationProvider.location != null) {
        locationProvider.removeListener(listener);
      }
    }
    locationProvider.addListener(listener);
  }

  void _pickManualLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManualLocationPicker()),
    );
    if (result != null) {
      context.read<LocationProviderV2>().setManualLocation(result);
      _addressController.text = result.fullAddress;
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final location = context.read<LocationProviderV2>().location;
      
      if (location == null) {
        UIUtils.showErrorDialog(context, "GPS Location Required. Please tap the location button.");
        return;
      }

      final success = await context.read<AuthViewModel>().registerDonor(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text.isEmpty ? location.fullAddress : _addressController.text,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (success) {
        if (!mounted) return;
        UIUtils.showSuccessDialog(
          context, 
          "Registration Successful! Please login.",
          onOk: () => Navigator.pop(context)
        );
      } else {
        if (!mounted) return;
        UIUtils.showErrorDialog(
          context, 
          context.read<AuthViewModel>().errorMessage ?? "Registration Failed"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final locationProvider = context.watch<LocationProviderV2>();

    if (locationProvider.location != null && _addressController.text.isEmpty) {
        _addressController.text = locationProvider.location!.fullAddress;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Donor Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
                validator: (value) => value!.length < 6 ? "Minimum 6 characters" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Enter phone" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address", 
                  prefixIcon: Icon(Icons.location_on_outlined),
                  helperText: "Detect location or type manually",
                ),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 16),
              _buildLocationCaptureBox(locationProvider),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authViewModel.isLoading || locationProvider.isLoading ? null : _register,
                child: authViewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("REGISTER AS DONOR"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCaptureBox(LocationProviderV2 provider) {
    final hasLocation = provider.location != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasLocation ? Colors.green : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.check_circle : Icons.gps_fixed, 
                color: hasLocation ? Colors.green : AppColors.primary
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? "Location Verified" : "GPS Status",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasLocation ? Colors.green : Colors.black87
                      ),
                    ),
                    Text(
                      hasLocation 
                        ? "Coords: ${provider.location!.latitude.toStringAsFixed(4)}, ${provider.location!.longitude.toStringAsFixed(4)}"
                        : "Location capture required for delivery",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _startLocationCapture, 
                child: Text(hasLocation ? "RE-SCAN" : "GET GPS")
              ),
            ],
          ),
          if (!hasLocation) ...[
            const Divider(height: 24),
            InkWell(
              onTap: _pickManualLocation,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Pick from Map instead", style: TextStyle(color: Colors.blue, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
