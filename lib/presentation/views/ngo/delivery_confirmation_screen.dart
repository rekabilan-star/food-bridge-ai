import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/theme/app_colors.dart';

import '../../../services/location_service.dart';

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

  @override
  void initState() {
    super.initState();
    _membersController.text = widget.donation.membersServed.toString();
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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        UIUtils.showErrorDialog(context, "Please take a delivery confirmation photo");
        return;
      }

      final viewModel = context.read<DonationViewModel>();
      
      // 1. Get Location
      double finalLat = widget.donation.latitude;
      double finalLng = widget.donation.longitude;
      try {
          final loc = await LocationService().getProductionLocation(
            onProgress: (msg) => debugPrint("Delivery Location: $msg")
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
          UIUtils.showErrorDialog(context, "Image upload failed");
          return;
      }

      final success = await viewModel.confirmDelivery(widget.donation.id, {
        'photoUrl': photoUrl,
        'address': _addressController.text,
        'latitude': finalLat,
        'longitude': finalLng,
        'membersServed': int.parse(_membersController.text),
        'notes': _notesController.text,
      });

      if (!mounted) return;

      if (success) {
        UIUtils.showSuccessDialog(context, "Donation Completed! Thank you for your service.", onOk: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        UIUtils.showErrorDialog(context, viewModel.errorMessage ?? "Completion failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Delivery")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Distribution Proof", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("Take Distribution Photo", style: TextStyle(color: Colors.grey))
                            ])
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_image!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Distribution Location", prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => v!.isEmpty ? "Enter location" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersController,
                decoration: const InputDecoration(labelText: "Actual Members Served", prefixIcon: Icon(Icons.people_outline)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter number" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Delivery Notes", prefixIcon: Icon(Icons.note_alt_outlined), hintText: "e.g., Distributed at NGO center"),
                maxLines: 3,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: context.watch<DonationViewModel>().isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ngoColor,
                    minimumSize: const Size(double.infinity, 56)
                ),
                child: context.watch<DonationViewModel>().isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("COMPLETE DONATION"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
