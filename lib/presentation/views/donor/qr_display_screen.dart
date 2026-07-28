import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/donation_model.dart';

class QrDisplayScreen extends StatelessWidget {
  final DonationModel donation;
  const QrDisplayScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pickup Verification")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Show this QR to the NGO Partner",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "This ensures the food is handed over to the correct verified partner.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: QrImageView(
                  data: donation.qrCode ?? "No-QR",
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                donation.foodName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "Donation ID: ${donation.id.substring(donation.id.length - 8).toUpperCase()}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Waiting for pickup verification...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
