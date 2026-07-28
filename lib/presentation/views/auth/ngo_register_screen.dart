import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/utils/location_loading_dialog.dart';
import '../../../core/utils/manual_location_picker.dart';
import '../../../core/utils/ui_utils.dart';

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
  
  // URL placeholders for demo. In real app, use image_picker and upload to Cloudinary.
  final String _demoCertUrl = "https://cloudinary.com/demo/cert.pdf";
  final String _demoIdUrl = "https://cloudinary.com/demo/id.jpg";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  void _startLocationCapture() async {
    final locationProvider = context.read<LocationProviderV2>();
    locationProvider.fetchLocation();
    if (!mounted) return;
    LocationLoadingDialog.show(context);
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

      final success = await context.read<AuthViewModel>().registerNgo(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text.isEmpty ? location.fullAddress : _addressController.text,
        latitude: location.latitude,
        longitude: location.longitude,
        regNumber: _regNumberController.text,
        certificateUrl: _demoCertUrl,
        idProofUrl: _demoIdUrl,
      );

      if (success) {
        if (!mounted) return;
        UIUtils.showSuccessDialog(
          context, 
          "Registration Submitted! Admin will verify your NGO.",
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
      appBar: AppBar(title: const Text("NGO Partner Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NGO Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ngoColor),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "NGO Name", prefixIcon: Icon(Icons.business)),
                validator: (value) => value!.isEmpty ? "Enter NGO name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regNumberController,
                decoration: const InputDecoration(labelText: "Registration Number", prefixIcon: Icon(Icons.assignment_outlined)),
                validator: (value) => value!.isEmpty ? "Enter registration number" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFileUploadTile("Government Certificate", Icons.upload_file),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFileUploadTile("Identity Proof", Icons.badge_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Contact Information",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ngoColor),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Official Email", prefixIcon: Icon(Icons.email_outlined)),
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
                decoration: const InputDecoration(labelText: "Headquarters Address", prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 16),
              _buildLocationSection(locationProvider),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authViewModel.isLoading || locationProvider.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.ngoColor),
                child: authViewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT REGISTRATION"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadTile(String label, IconData icon) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.ngoColor),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLocationSection(LocationProviderV2 provider) {
    final hasLocation = provider.location != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasLocation ? Colors.green : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(hasLocation ? Icons.check_circle : Icons.gps_fixed, color: hasLocation ? Colors.green : AppColors.ngoColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? "Location Verified" : "GPS Location Required",
                      style: TextStyle(color: hasLocation ? Colors.green[700] : Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                    if (hasLocation)
                      Text(
                        "${provider.location!.latitude.toStringAsFixed(4)}, ${provider.location!.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              TextButton(onPressed: _startLocationCapture, child: Text(hasLocation ? "RE-SCAN" : "GET", style: const TextStyle(color: AppColors.ngoColor))),
            ],
          ),
          if (!hasLocation) ...[
            const Divider(),
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
