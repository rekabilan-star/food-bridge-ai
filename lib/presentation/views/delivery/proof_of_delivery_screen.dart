import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/models/donation_model.dart';

class ProofOfDeliveryScreen extends StatefulWidget {
  final DonationModel donation;

  const ProofOfDeliveryScreen({super.key, required this.donation});

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? _image;
  final _picker = ImagePicker();
  final _receiverController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (_image == null || _controller.isEmpty || _receiverController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide all details (Photo, Signature, Name)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // final Uint8List? signature = await _controller.toPngBytes();
      
      // In a real app, upload image and signature to Cloudinary/S3 first
      // Then call the confirmDelivery API
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receiver Name', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _receiverController, decoration: const InputDecoration(hintText: 'Enter name')),
            const SizedBox(height: 20),
            
            const Text('Proof Photo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                ),
                child: _image != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, fit: BoxFit.cover))
                  : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Digital Signature', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(
                controller: _controller,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.clear), onPressed: () => _controller.clear()),
              ],
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT PROOF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
