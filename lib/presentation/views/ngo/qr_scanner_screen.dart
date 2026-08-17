import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  final String donationId;
  const QrScannerScreen({super.key, required this.donationId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;

  void _handleQrVerification(String qrPayload) async {
    if (_isScanned) return;
    setState(() => _isScanned = true);

    final donationVM = context.read<DonationViewModel>();
    final success = await donationVM.verifyPickup(
      widget.donationId, 
      qrPayload,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Handshake Verified! Status updated to Picked Up.")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(donationVM.errorMessage ?? "Invalid QR Code or verification failed")),
      );
      setState(() => _isScanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Pickup QR Code"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _handleQrVerification(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ngoColor, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              "Align the Donor's QR code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
