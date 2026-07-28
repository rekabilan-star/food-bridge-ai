import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/emergency_viewmodel.dart';
import '../../../data/repositories/emergency_repository.dart';
import '../../../core/utils/ui_utils.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _membersController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _foodType = 'Any';
  String _priority = 'High';
  DateTime _requiredBefore = DateTime.now().add(const Duration(hours: 3));

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<EmergencyViewModel>().createRequest(
        EmergencyRequestModel(
          id: '',
          ngoId: '',
          title: _titleController.text,
          reason: _reasonController.text,
          requiredMembers: int.parse(_membersController.text),
          foodType: _foodType,
          address: _addressController.text,
          latitude: 13.0827, // Mock
          longitude: 80.2707, // Mock
          requiredBefore: _requiredBefore,
          priority: _priority,
          status: 'active',
        )
      );

      if (success) {
        if (mounted) {
          UIUtils.showSuccessDialog(context, "Emergency Request Broadcasted!", onOk: () {
            Navigator.pop(context);
          });
        }
      } else {
        if (mounted) UIUtils.showErrorDialog(context, context.read<EmergencyViewModel>().errorMessage ?? "Failed to create request");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Request")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Broadcast Emergency Need", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Donors near you will receive instant notifications.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Request Title", hintText: "e.g., Food for flood victims"),
                validator: (v) => v!.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: "Reason / Context"),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Enter reason" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _membersController,
                      decoration: const InputDecoration(labelText: "Members in Need"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Enter number" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _foodType,
                      decoration: const InputDecoration(labelText: "Food Type"),
                      items: ['Veg', 'Non-Veg', 'Any'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _foodType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: "Priority Level"),
                items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Delivery Address", prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => v!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 24),
              _buildTimePicker(),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: context.watch<EmergencyViewModel>().isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 56)),
                child: context.watch<EmergencyViewModel>().isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("BROADCAST EMERGENCY"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_requiredBefore));
        if (picked != null) {
          final now = DateTime.now();
          setState(() => _requiredBefore = DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.red),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Required Before", style: TextStyle(fontSize: 12, color: Colors.red)),
                Text(DateFormat('hh:mm a').format(_requiredBefore), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
