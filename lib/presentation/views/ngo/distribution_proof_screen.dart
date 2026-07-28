import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';

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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _deliveryImage = File(picked.path));
  }

  void _completeDistribution() {
    if (_formKey.currentState!.validate() && _deliveryImage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Thank You!"),
          content: const Text("You have successfully rescued and distributed food. This impact has been recorded."),
          actions: [
            ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text("BACK TO DASHBOARD")),
          ],
        ),
      );
    } else if (_deliveryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload delivery photo")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Distribution Proof")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Step 7: Proof of Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Rescuing food is only half the work. Let's record the impact.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              _buildImageUploader(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _servedController,
                decoration: const InputDecoration(labelText: "Approx. Members Served", prefixIcon: Icon(Icons.people_outline)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Delivery Notes", prefixIcon: Icon(Icons.notes), hintText: "Where did you distribute?"),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _completeDistribution,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text("COMPLETE DISTRIBUTION"),
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
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
        child: _deliveryImage == null 
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.camera_alt, size: 48, color: Colors.grey), SizedBox(height: 12), Text("Add Delivery Photo", style: TextStyle(color: Colors.grey))])
          : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_deliveryImage!, fit: BoxFit.cover)),
      ),
    );
  }
}
