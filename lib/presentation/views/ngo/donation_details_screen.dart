import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/donation_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import 'ngo_tracking_screen.dart';
import 'delivery_confirmation_screen.dart';

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
                  Consumer2<AuthViewModel, DonationViewModel>(
                    builder: (context, auth, viewModel, _) {
                      if (auth.user?.role != UserRole.ngo) return const SizedBox.shrink();

                      final statusLower = donation.status.toLowerCase();

                      if (statusLower == 'completed') {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                "Donation Successfully Completed",
                                style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }

                      if (statusLower == 'picked_up') {
                        return ElevatedButton.icon(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryConfirmationScreen(donation: donation))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.local_shipping_rounded),
                          label: const Text("PROCEED TO DELIVERY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        );
                      }

                      if (statusLower == 'accepted' || statusLower == 'on_the_way' || statusLower == 'arrived') {
                        return ElevatedButton.icon(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ngoColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text("TRACK PICKUP / RESCUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        );
                      }

                      if (statusLower == 'expired' || donation.isExpired) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_off_rounded, color: Colors.red, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "This food donation has expired and is no longer available for rescue.",
                                  style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (statusLower == 'cancelled' || statusLower == 'rejected') {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cancel_outlined, color: Colors.grey, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                "This donation was ${statusLower == 'cancelled' ? 'cancelled' : 'rejected'}.",
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ElevatedButton.icon(
                        onPressed: viewModel.isLoading ? null : () => _confirmAcceptance(context, viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ngoColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: viewModel.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          viewModel.isLoading ? "PROCESSING..." : "ACCEPT DONATION",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
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

  String _resolveFoodImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (File(trimmed).existsSync()) {
      return trimmed;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootServer$cleanPath';
  }

  Widget _buildImageHeader() {
    final rawUrl = donation.imageUrl;
    final resolvedUrl = _resolveFoodImageUrl(rawUrl);
    final isLocalFile = rawUrl.isNotEmpty && File(rawUrl).existsSync();

    if (resolvedUrl.isEmpty) {
      return _buildUnavailableImageHeader();
    }

    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey[200],
      child: isLocalFile
          ? Image.file(
              File(rawUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
            )
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildUnavailableImageHeader();
              },
            ),
    );
  }

  Widget _buildUnavailableImageHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Food image unavailable",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Donation Accepted! Task added to your Rescue Control."))
                );
                Navigator.pushNamedAndRemoveUntil(context, '/ngo-dashboard', (route) => false);
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
