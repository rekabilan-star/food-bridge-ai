import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/ui_utils.dart';

class ManageNgosScreen extends StatefulWidget {
  const ManageNgosScreen({super.key});

  @override
  State<ManageNgosScreen> createState() => _ManageNgosScreenState();
}

class _ManageNgosScreenState extends State<ManageNgosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchNgos(status: 'pending');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ngos = context.watch<AdminViewModel>().ngos;
    final isLoading = context.watch<AdminViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("NGO Approvals")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ngos.isEmpty
              ? const Center(child: Text("No pending NGO approvals"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ngos.length,
                  itemBuilder: (context, index) {
                    final ngo = ngos[index];
                    return _buildNgoCard(ngo);
                  },
                ),
    );
  }

  Widget _buildNgoCard(UserModel ngo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Text(ngo.name[0], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ngo.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Reg: ${ngo.ngoRegistrationNumber ?? 'N/A'}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                const Chip(label: Text("PENDING", style: TextStyle(fontSize: 10, color: Colors.orange)), backgroundColor: Color(0xFFFFF3E0)),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.email, ngo.email),
            _buildDetailRow(Icons.phone, ngo.phoneNumber),
            _buildDetailRow(Icons.location_on, ngo.address ?? 'No address'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleStatusUpdate(ngo.id, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text("REJECT"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStatusUpdate(ngo.id, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("APPROVE"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  void _handleStatusUpdate(String id, String status) async {
    final success = await context.read<AdminViewModel>().updateNgoStatus(id, status);
    if (success) {
      if (mounted) UIUtils.showSuccessDialog(context, "NGO successfully $status");
    } else {
      if (mounted) UIUtils.showErrorDialog(context, context.read<AdminViewModel>().errorMessage ?? "Failed to update status");
    }
  }
}
