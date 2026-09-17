import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:intl/intl.dart';

class VerificationScannerScreen extends StatefulWidget {
  const VerificationScannerScreen({super.key});

  @override
  State<VerificationScannerScreen> createState() => _VerificationScannerScreenState();
}

class _VerificationScannerScreenState extends State<VerificationScannerScreen> {
  bool _isScanned = false;

  void _handleVerification(String qrCode) async {
    if (_isScanned) return;
    setState(() => _isScanned = true);

    final dVM = context.read<DonationViewModel>();
    UIUtils.showLoadingDialog(context);

    try {
      final result = await dVM.verifyRescueQr(qrCode);
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showImpactSummary(result['data']);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        UIUtils.showErrorDialog(context, e.toString());
        setState(() => _isScanned = false);
      }
    }
  }

  void _showImpactSummary(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, 
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            const Text("RESCUE VERIFIED", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(data['foodName'] ?? "Rescue Mission", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 40),
            _buildInfoRow("Donor", data['donorName'] ?? "N/A"),
            _buildInfoRow("NGO Partner", data['ngoName'] ?? "N/A"),
            _buildInfoRow("Meals Provided", "${data['impact']?['meals'] ?? 0}"),
            _buildInfoRow("Food Saved", "${data['impact']?['weight'] ?? 0} kg"),
            if (data['completedAt'] != null)
              _buildInfoRow("Completed On", DateFormat('dd MMM yyyy').format(DateTime.parse(data['completedAt']))),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("DONE"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) => setState(() => _isScanned = false));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Verify Impact Certificate"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates),
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) _handleVerification(barcode.rawValue!);
            },
          ),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(border: Border.all(color: Colors.white24, width: 2), borderRadius: BorderRadius.circular(30)),
              child: Stack(
                children: [
                  _buildCorner(top: true, left: true),
                  _buildCorner(top: true, right: true),
                  _buildCorner(bottom: true, left: true),
                  _buildCorner(bottom: true, right: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({bool top = false, bool bottom = false, bool left = false, bool right = false}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: bottom ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: right ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
