import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';

class QrScannerScreen extends StatefulWidget {
  final String donationId;
  const QrScannerScreen({super.key, required this.donationId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Pickup QR")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              final donationVM = context.read<DonationViewModel>();
              
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  final success = await donationVM.verifyPickup(widget.donationId, barcode.rawValue!);
                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(donationVM.errorMessage ?? "Verification Failed")));
                    setState(() => _isScanned = false);
                  }
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Align the QR code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
