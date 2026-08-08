import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_scanner_screen.dart';
import 'delivery_confirmation_screen.dart';
import '../common/chat_screen.dart';
import '../common/rating_screen.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/utils/intent_utils.dart';

class NgoTrackingScreen extends StatefulWidget {
  final String donationId;
  const NgoTrackingScreen({super.key, required this.donationId});

  @override
  State<NgoTrackingScreen> createState() => _NgoTrackingScreenState();
}

class _NgoTrackingScreenState extends State<NgoTrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonationDetails(widget.donationId);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    debugPrint('[GPS] Starting NGO tracking stream');
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      debugPrint('[GPS] NGO Position update: Lat ${position.latitude}, Lng ${position.longitude}, Acc ${position.accuracy}m');
      if (mounted) {
        context.read<DonationViewModel>().updateNgoLocation(position.latitude, position.longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationViewModel>().currentDonation;

    return Scaffold(
      appBar: AppBar(title: const Text("Navigate to Donor")),
      body: donation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(donation.latitude, donation.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mca_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(donation.latitude, donation.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildActionPanel(donation),
              ],
            ),
    );
  }

  Widget _buildActionPanel(DonationModel donation) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donation.foodName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(donation.pickupAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                    receiverId: donation.donorId,
                    donationId: donation.id,
                    receiverName: donation.donorName ?? "Donor",
                  ))),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => IntentUtils.makePhoneCall(donation.donorPhone ?? ''),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue[50]),
                  icon: const Icon(Icons.phone, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => IntentUtils.openMapNavigation(donation.latitude, donation.longitude),
                  style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
                  icon: const Icon(Icons.navigation, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (donation.status == 'accepted')
              _buildPrimaryButton("START JOURNEY", Icons.play_arrow, Colors.blue, () {
                context.read<DonationViewModel>().updateDonationStatus(donation.id, 'on_the_way');
              })
            else if (donation.status == 'on_the_way')
              _buildPrimaryButton("I HAVE ARRIVED", Icons.location_on, Colors.orange, () {
                context.read<DonationViewModel>().updateDonationStatus(donation.id, 'arrived');
              })
            else if (donation.status == 'arrived')
              _buildPrimaryButton("SCAN PICKUP QR", Icons.qr_code_scanner, AppColors.ngoColor, () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => QrScannerScreen(donationId: donation.id)));
                if (!mounted) return;
                if (result == true) {
                   UIUtils.showSuccessDialog(context, "Pickup Verified Successfully!");
                }
              })
            else if (donation.status == 'picked_up')
                _buildPrimaryButton("PROCEED TO DELIVERY", Icons.local_shipping, Colors.teal, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryConfirmationScreen(donation: donation)));
                })
            else if (donation.status == 'completed')
                _buildPrimaryButton("RATE DONOR", Icons.star, Colors.amber, () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(
                     donationId: donation.id,
                     toUserId: donation.donorId,
                     toUserName: donation.donorName ?? "Donor",
                   )));
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
