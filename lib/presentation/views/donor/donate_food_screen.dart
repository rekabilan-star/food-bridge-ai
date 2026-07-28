import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/utils/ui_utils.dart';

class DonateFoodScreen extends StatefulWidget {
  const DonateFoodScreen({super.key});

  @override
  State<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends State<DonateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _instructionController = TextEditingController();

  // Multi-item support
  final List<FoodItem> _items = [];
  final _itemNameController = TextEditingController();
  final _itemMembersController = TextEditingController();
  String _itemCategory = 'Cooked Meal';

  // Checklist
  bool _isFreshlyPrepared = false;
  bool _isProperlyPacked = false;
  String _foodType = 'Veg';
  bool _hasAllergens = false;

  // Scheduling
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  DateTime _preparedTime = DateTime.now();
  DateTime _expiryTime = DateTime.now().add(const Duration(hours: 4));
  File? _image;
  double? _lat, _lng;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _addressController.dispose();
    _instructionController.dispose();
    _itemNameController.dispose();
    _itemMembersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, "Location Error: $e");
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        UIUtils.showErrorDialog(context, "Please add at least one food item");
        return;
      }
      if (!_isFreshlyPrepared || !_isProperlyPacked) {
        UIUtils.showErrorDialog(context, "Please complete the quality checklist");
        return;
      }
      if (_lat == null) {
        UIUtils.showErrorDialog(context, "GPS Location required");
        return;
      }
      if (_image == null) {
        UIUtils.showErrorDialog(context, "Food image required");
        return;
      }

      DateTime? scheduledTimestamp;
      if (_isScheduled && _scheduledDate != null && _scheduledTime != null) {
        scheduledTimestamp = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      final success = await context.read<DonationViewModel>().createDonation(
            DonationModel(
              id: '',
              donorId: '',
              items: _items,
              foodName: '', // Backend will generate from items
              category: '',
              membersServed: 0,
              imageUrl: '',
              preparedTime: _preparedTime,
              bestBeforeTime: _expiryTime,
              checklist: QualityChecklist(
                isFreshlyPrepared: _isFreshlyPrepared,
                isProperlyPacked: _isProperlyPacked,
                foodType: _foodType,
                hasAllergens: _hasAllergens,
              ),
              isScheduled: _isScheduled,
              scheduledTimestamp: scheduledTimestamp,
              pickupAddress: _addressController.text,
              latitude: _lat!,
              longitude: _lng!,
              specialInstructions: _instructionController.text,
              status: 'waiting',
            ),
            _image,
          );

      if (success) {
        if (!mounted) return;
        UIUtils.showSuccessDialog(
          context, 
          "Food Donated Successfully! Finding nearby NGOs...",
          onOk: () => Navigator.pop(context)
        );
      } else {
        if (!mounted) return;
        UIUtils.showErrorDialog(
          context, 
          context.read<DonationViewModel>().errorMessage ?? "Donation Failed"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              
              const Text("Food Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildItemsList(),
              _buildAddItemButton(),
              
              const SizedBox(height: 32),
              const Text("Quality Checklist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildChecklist(),

              const SizedBox(height: 32),
              const Text("Scheduling", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSchedulingOptions(),

              const SizedBox(height: 32),
              const Text("Logistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildTimePicker(
                          "Prepared At",
                          _preparedTime,
                          (t) => setState(() => _preparedTime = t))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTimePicker("Best Before", _expiryTime,
                          (t) => setState(() => _expiryTime = t))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: "Pickup Address",
                    prefixIcon: Icon(Icons.map_outlined)),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 12),
              _buildLocationButton(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionController,
                decoration: const InputDecoration(
                    labelText: "Special Instructions",
                    prefixIcon: Icon(Icons.info_outline),
                    hintText: "e.g., Handle with care, cold storage required"),
                maxLines: 2,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed:
                    context.watch<DonationViewModel>().isLoading ? null : _submit,
                child: context.watch<DonationViewModel>().isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("DONATE FOOD"),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${item.category} • Serves ${item.membersServed}"),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => setState(() => _items.remove(item)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAddItemButton() {
    return OutlinedButton.icon(
      onPressed: _showAddItemDialog,
      icon: const Icon(Icons.add),
      label: const Text("ADD FOOD ITEM"),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Food Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: "Food Name"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _itemCategory,
                items: ['Cooked Meal', 'Bakery Items', 'Raw Materials', 'Fruits/Veggies', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => _itemCategory = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _itemMembersController,
                decoration: const InputDecoration(labelText: "Serves How Many?"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                if (_itemNameController.text.isNotEmpty && _itemMembersController.text.isNotEmpty) {
                  setState(() {
                    _items.add(FoodItem(
                      foodName: _itemNameController.text,
                      category: _itemCategory,
                      membersServed: int.parse(_itemMembersController.text),
                    ));
                  });
                  _itemNameController.clear();
                  _itemMembersController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("ADD"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text("Freshly Prepared"),
            value: _isFreshlyPrepared,
            onChanged: (v) => setState(() => _isFreshlyPrepared = v!),
          ),
          CheckboxListTile(
            title: const Text("Properly Packed"),
            value: _isProperlyPacked,
            onChanged: (v) => setState(() => _isProperlyPacked = v!),
          ),
          CheckboxListTile(
            title: const Text("Contains Allergens"),
            value: _hasAllergens,
            onChanged: (v) => setState(() => _hasAllergens = v!),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [Text("Food Type", style: TextStyle(fontWeight: FontWeight.bold))]),
          ),
          Row(
            children: ['Veg', 'Non-Veg', 'Both'].map((type) => Expanded(
              child: RadioListTile<String>(
                title: Text(type, style: const TextStyle(fontSize: 12)),
                value: type,
                groupValue: _foodType,
                onChanged: (v) => setState(() => _foodType = v!),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Schedule for Later"),
            subtitle: const Text("Notify NGO at a specific time"),
            value: _isScheduled,
            onChanged: (v) => setState(() => _isScheduled = v),
          ),
          if (_isScheduled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) setState(() => _scheduledDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_scheduledDate == null ? "Date" : DateFormat('dd/MM').format(_scheduledDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _scheduledTime = picked);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_scheduledTime == null ? "Time" : _scheduledTime!.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
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
                    Text("Add Food Image", style: TextStyle(color: Colors.grey))
                  ])
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_image!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildTimePicker(
      String label, DateTime time, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
            context: context, initialTime: TimeOfDay.fromDateTime(time));
        if (picked != null) {
          final now = DateTime.now();
          onPicked(DateTime(
              now.year, now.month, now.day, picked.hour, picked.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(DateFormat('hh:mm a').format(time),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildLocationButton() {
    return InkWell(
      onTap: _getLocation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.gps_fixed, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  _lat != null ? "GPS Location Captured" : "Confirm GPS Location",
                  style: TextStyle(
                      color: _lat != null ? AppColors.primary : Colors.grey[700],
                      fontWeight:
                          _lat != null ? FontWeight.bold : FontWeight.normal))),
          if (_isGettingLocation)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ),
    );
  }
}
