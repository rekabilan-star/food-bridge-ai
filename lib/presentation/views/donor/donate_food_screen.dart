import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import 'matched_ngos_screen.dart';
import '../common/success_confirmation_screen.dart';
import '../common/location_picker_screen.dart';
import '../../../core/providers/location_provider_v2.dart';
import '../../../core/models/location_model.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/modern_text_field.dart';
import '../common/widgets/custom_app_bar.dart';

class DonateFoodScreen extends StatefulWidget {
  final DonationModel? donation;
  const DonateFoodScreen({super.key, this.donation});

  @override
  State<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends State<DonateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _instructionController = TextEditingController();
  final _quantityController = TextEditingController(text: "2");

  List<FoodItem> _items = [];
  final bool _isFreshlyPrepared = true;
  final bool _isProperlyPacked = true;
  String _foodType = 'Cooked Meal';
  String _foodCategory = 'Vegetarian';
  String _quantityUnit = 'Plates';
  final bool _hasAllergens = false;

  final bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  DateTime _preparedTime = DateTime.now();
  DateTime _expiryTime = DateTime.now().add(const Duration(hours: 4));
  File? _image;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    if (widget.donation != null) {
      _items = List.from(widget.donation!.items);
      _addressController.text = widget.donation!.pickupAddress;
      _instructionController.text = widget.donation!.specialInstructions ?? '';
      _foodType = widget.donation!.checklist.foodType;
      _preparedTime = widget.donation!.preparedTime;
      _expiryTime = widget.donation!.bestBeforeTime;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LocationProviderV2>().setManualLocation(LocationModel(
          latitude: widget.donation!.latitude,
          longitude: widget.donation!.longitude,
          accuracy: 0.0,
          fullAddress: widget.donation!.pickupAddress,
          timestamp: DateTime.now(),
        ));
      });
    } else {
      _items.add(FoodItem(
        foodName: "Cooked Meals",
        category: "Vegetarian",
        membersServed: 2,
      ));
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  void _submit() async {
    final locProvider = context.read<LocationProviderV2>();
    
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        UIUtils.showErrorDialog(context, "Please add at least one food item");
        return;
      }
      
      if (locProvider.location == null) {
        UIUtils.showErrorDialog(context, "GPS Location required. Please verify your location.");
        return;
      }

      if (_image == null && widget.donation == null) {
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

      final viewModel = context.read<DonationViewModel>();
      
      String mainFoodName = _items.map((i) => i.foodName).join(", ");
      if (mainFoodName.length > 50) mainFoodName = "${mainFoodName.substring(0, 47)}...";
      
      String mainCategory = _foodCategory;
      int totalMembers = int.tryParse(_quantityController.text) ?? 2;

      String backendChecklistFoodType = 'Veg';
      if (_foodCategory == 'Non-Vegetarian') {
        backendChecklistFoodType = 'Non-Veg';
      } else if (_foodCategory == 'Both') {
        backendChecklistFoodType = 'Both';
      }

      final donationData = DonationModel(
        id: widget.donation?.id ?? '',
        donorId: widget.donation?.donorId ?? '',
        items: _items,
        foodName: mainFoodName, 
        category: mainCategory,
        membersServed: totalMembers,
        imageUrl: widget.donation?.imageUrl ?? '',
        preparedTime: _preparedTime,
        bestBeforeTime: _expiryTime,
        checklist: QualityChecklist(
          isFreshlyPrepared: _isFreshlyPrepared,
          isProperlyPacked: _isProperlyPacked,
          foodType: backendChecklistFoodType,
          hasAllergens: _hasAllergens,
        ),
        isScheduled: _isScheduled,
        scheduledTimestamp: scheduledTimestamp,
        pickupAddress: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : (locProvider.location?.fullAddress ?? "Verified GPS Location"),
        latitude: locProvider.location!.latitude,
        longitude: locProvider.location!.longitude,
        specialInstructions: _instructionController.text.trim(),
        status: widget.donation?.status ?? 'waiting',
      );

      bool success;
      if (widget.donation != null) {
        success = await viewModel.updateDonation(widget.donation!.id, donationData, _image);
      } else {
        success = await viewModel.createDonation(donationData, _image);
      }

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessConfirmationScreen(
              title: "Donation Successful!",
              message: "Thank you for your kindness.\nYou are making a difference. 💜",
              donationId: viewModel.currentDonation?.id ?? "FDB-2026-0516-0012",
              status: "Completed",
              estimatedPickup: "Today, 6:00 PM",
              onContinue: () {
                final newDonationId = viewModel.currentDonation?.id;
                if (newDonationId != null) {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => MatchedNgosScreen(donationId: newDonationId))
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      } else {
        if (!mounted) return;
        UIUtils.showErrorDialog(
          context, 
          viewModel.errorMessage ?? "Operation Failed"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: widget.donation != null ? "Edit Donation" : "Donate Food",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepProgressBar(),

              const SizedBox(height: 28),

              const Text(
                "Food Type",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildDropdownCard(
                value: _foodType,
                items: const ['Cooked Meal', 'Fresh Produce', 'Packaged Food', 'Bakery Items'],
                onChanged: (v) => setState(() => _foodType = v!),
              ),

              const SizedBox(height: 18),

              const Text(
                "Quantity",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ModernTextField(
                      controller: _quantityController,
                      label: "",
                      hint: "e.g. 2",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildDropdownCard(
                      value: _quantityUnit,
                      items: const ['Plates', 'Kg', 'Packs'],
                      onChanged: (v) => setState(() => _quantityUnit = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                "Food Category",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildDropdownCard(
                value: _foodCategory,
                items: const ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Eggitarian'],
                onChanged: (v) => setState(() => _foodCategory = v!),
              ),

              const SizedBox(height: 18),

              _buildDateSelectorTile(
                label: "Prepared On",
                dateString: DateFormat('dd MMM yyyy').format(_preparedTime),
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _preparedTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 2)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _preparedTime = picked);
                },
              ),

              const SizedBox(height: 14),

              _buildDateSelectorTile(
                label: "Best Before",
                dateString: DateFormat('dd MMM yyyy, h:mm a').format(_expiryTime),
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (picked != null) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    final timePicked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_expiryTime));
                    if (timePicked != null && mounted) {
                      setState(() {
                        _expiryTime = DateTime(picked.year, picked.month, picked.day, timePicked.hour, timePicked.minute);
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: 22),

              const Text(
                "Add Photo",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildPhotoUploadCard(),

              const SizedBox(height: 36),

              PrimaryButton(
                text: _currentStep == 1 ? "Next: Location" : "Confirm Donation",
                onPressed: () async {
                  if (_currentStep == 1) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                    );
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    final loc = Provider.of<LocationProviderV2>(context, listen: false).location;
                    if (loc != null) {
                      setState(() {
                        _addressController.text = loc.fullAddress;
                        _currentStep = 2;
                      });
                      } else {
                        setState(() {
                          _currentStep = 2;
                        });
                      }
                  } else {
                    _submit();
                  }
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Row(
      children: [
        _buildStepCircle(1, "Food Details", _currentStep >= 1),
        _buildStepLine(_currentStep >= 2),
        _buildStepCircle(2, "Location", _currentStep >= 2),
        _buildStepLine(_currentStep >= 3),
        _buildStepCircle(3, "Review", _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.white,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              "$step",
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildDropdownCard({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateSelectorTile({
    required String label,
    required String dateString,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateString,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(icon, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Add food image",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
