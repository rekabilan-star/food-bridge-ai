import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/donation_model.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/constants/app_constants.dart';

class DonationDetailsScreen extends StatelessWidget {
  final DonationModel donation;
  const DonationDetailsScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donation Details")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.category, "Category", donation.category),
                  _buildDetailRow(Icons.people, "Serves", "${donation.membersServed} Members"),
                  _buildDetailRow(Icons.timer, "Prepared Time", DateFormat('hh:mm a').format(donation.preparedTime)),
                  _buildDetailRow(Icons.warning_amber_rounded, "Best Before", DateFormat('hh:mm a').format(donation.bestBeforeTime), color: Colors.red),
                  const SizedBox(height: 32),
                  const Text("Pickup Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAddressCard(),
                  const SizedBox(height: 32),
                  const Text("Special Instructions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    donation.specialInstructions ?? "No special instructions provided.",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  Consumer<DonationViewModel>(
                    builder: (context, viewModel, _) {
                      return ElevatedButton(
                        onPressed: viewModel.isLoading ? null : () => _confirmAcceptance(context, viewModel),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ngoColor),
                        child: viewModel.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("ACCEPT DONATION"),
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    String imageUrl = donation.imageUrl;
    if (!imageUrl.startsWith('http')) {
        imageUrl = '${AppConstants.baseUrl}/$imageUrl'.replaceAll('/api/', '/');
    }

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: imageUrl.isNotEmpty ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ) : null,
      ),
      child: imageUrl.isEmpty ? const Icon(Icons.restaurant, size: 64, color: Colors.grey) : null,
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                donation.foodName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                donation.donorName ?? "Donor",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (donation.donorPhone != null)
          IconButton(
            onPressed: () => IntentUtils.makePhoneCall(donation.donorPhone!),
            style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text("$label:", style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.ngoColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              donation.pickupAddress,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAcceptance(BuildContext context, DonationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Donation?"),
        content: const Text("Once accepted, you are responsible for picking up the food before it expires."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.updateDonationStatus(donation.id, 'accepted');
              if (success) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Donation Accepted!")));
                Navigator.pop(context); // Go back to list
              } else {
                 if (!context.mounted) return;
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage ?? "Failed to accept")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ngoColor, minimumSize: const Size(100, 40)),
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }
}
