import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/providers/location_provider_v2.dart';
import '../core/utils/location_loading_dialog.dart';
import '../core/utils/manual_location_picker.dart';
import '../services/data_service.dart';
import '../models/donation_request.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final _picker = ImagePicker();

  // Controllers
  final _restaurantController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _storageController = TextEditingController();
  final _allergenController = TextEditingController();
  
  String _category = 'Cooked Food';
  DateTime _cookingTime = DateTime.now();
  DateTime _expiryTime = DateTime.now().add(const Duration(hours: 4));

  @override
  void dispose() {
    _restaurantController.dispose();
    _foodNameController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _storageController.dispose();
    _allergenController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProviderV2>();

    if (locationProvider.location != null && _addressController.text.isEmpty) {
        _addressController.text = locationProvider.location!.fullAddress;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Food Donation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.1), width: 2),
                    image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  ),
                  child: _image == null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.green.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('Upload Food Image', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ) : null,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Basic Information'),
              _buildTextField(_restaurantController, 'Restaurant Name', Icons.store_outlined),
              _buildTextField(_foodNameController, 'Food Name', Icons.restaurant_menu_outlined),
              
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Food Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Cooked Food', 'Raw Materials', 'Bakery', 'Fruits/Veggies', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _category = newValue!),
              ),
              const SizedBox(height: 16),
              _buildTextField(_quantityController, 'Quantity (kg)', Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              
              _buildSectionTitle('Timings'),
              Row(
                children: [
                  Expanded(child: _buildTimeTile('Cooking', _cookingTime, () => _selectDateTime(context, _cookingTime, (d) => setState(() => _cookingTime = d)))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeTile('Expiry', _expiryTime, () => _selectDateTime(context, _expiryTime, (d) => setState(() => _expiryTime = d)))),
                ],
              ),
              
              _buildSectionTitle('Location'),
              _buildLocationButton(locationProvider),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Pickup Address', Icons.location_on_outlined, maxLines: 2),
              
              _buildSectionTitle('Additional Details'),
              _buildTextField(_descController, 'Description', Icons.info_outline, maxLines: 3),
              _buildTextField(_storageController, 'Storage Instructions', Icons.ac_unit),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_image == null) {
                      _showSnackBar('Please add a photo of the food');
                      return;
                    }
                    _showProcessingDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SUBMIT DONATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton(LocationProviderV2 provider) {
    final hasLocation = provider.location != null;
    return Column(
      children: [
        InkWell(
          onTap: _startLocationCapture,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(hasLocation ? Icons.check_circle : Icons.gps_fixed, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      hasLocation ? "Location Verified" : "Capture GPS Location",
                      style: TextStyle(
                          color: hasLocation ? Colors.green : Colors.black87,
                          fontWeight: hasLocation ? FontWeight.bold : FontWeight.normal))),
              TextButton(onPressed: _startLocationCapture, child: Text(hasLocation ? "RE-SCAN" : "GET")),
            ]),
          ),
        ),
        if (!hasLocation)
          TextButton.icon(
            onPressed: _pickManualLocation,
            icon: const Icon(Icons.map, size: 16),
            label: const Text("Select from map instead", style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  // ... helper methods ( _buildSectionTitle, _buildTextField, _buildTimeTile, _showImageSourceActionSheet, etc) ...
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildTimeTile(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, HH:mm').format(value), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera), title: const Text('Camera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, DateTime initial, Function(DateTime) onSelected) async {
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 7)));
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time != null) {
        onSelected(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 24),
            const Text('AI-Based NGO Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Analyzing distance, food type, and NGO capacity...', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog
      _showRecommendationResults(context);
    });
  }

  void _showRecommendationResults(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green),
                SizedBox(width: 8),
                Text('AI Recommendations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Based on food type, quantity, and urgency, we found these best-suited NGOs.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildNgoRecCard('Helping Hands NGO', '0.8 km', 'High Capacity', 'Vegetables/Cooked'),
                  _buildNgoRecCard('Feed The Needy', '1.5 km', 'Medium Capacity', 'Cooked Food Only'),
                  _buildNgoRecCard('Green Earth Food Bank', '2.2 km', 'High Capacity', 'Raw Materials'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger real storage
                DataService().addDonation(DonationRequest(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  restaurantName: _restaurantController.text,
                  foodName: _foodNameController.text,
                  quantity: _quantityController.text,
                  address: _addressController.text,
                  status: 'pending',
                  expiryTime: _expiryTime,
                ));

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donation submitted! Notifications sent.')));
                
                if (mounted) {
                  Navigator.pop(context); // Pop bottom sheet
                  Navigator.pop(context); // Pop add donation screen
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONFIRM & SEND NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNgoRecCard(String name, String dist, String cap, String pref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.business, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$dist away • $cap', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Prefers: $pref', style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
