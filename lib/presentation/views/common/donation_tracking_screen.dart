import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';
import '../../../core/utils/receipt_service.dart';
import '../../../core/utils/intent_utils.dart';
import 'package:intl/intl.dart';

class DonationTrackingScreen extends StatefulWidget {
  final String donationId;
  const DonationTrackingScreen({super.key, required this.donationId});

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      context.read<DonationViewModel>().fetchDonationDetails(widget.donationId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonationDetails(widget.donationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationViewModel>().currentDonation;
    final isLoading = context.watch<DonationViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Track Donation")),
      body: donation == null && isLoading
          ? const Center(child: CircularProgressIndicator())
          : donation == null
              ? const Center(child: Text("Donation not found"))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(donation.latitude, donation.longitude),
                        initialZoom: 14,
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
                            if (donation.ngoLat != null && donation.ngoLng != null)
                              Marker(
                                point: LatLng(donation.ngoLat!, donation.ngoLng!),
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                              ),
                          ],
                        ),
                      ],
                    ),
                    _buildTrackingStatus(donation),
                    _buildTimelinePanel(donation),
                  ],
                ),
    );
  }

  Widget _buildTrackingStatus(DonationModel donation) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(donation.status),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          donation.assignedNgoName ?? "Finding NGO Partner...",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (donation.assignedNgoPhone != null)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                            receiverId: donation.assignedNgoId!,
                            donationId: donation.id,
                            receiverName: donation.assignedNgoName ?? "NGO",
                          ))),
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () => IntentUtils.makePhoneCall(donation.assignedNgoPhone!),
                          icon: const Icon(Icons.phone, color: Colors.green),
                        ),
                      ],
                    ),
                ],
              ),
              if (donation.status == 'completed') ...[
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ReceiptService.generateAndPrintReceipt(donation),
                        icon: const Icon(Icons.download),
                        label: const Text("RECEIPT"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(
                          donationId: donation.id,
                          toUserId: donation.assignedNgoId!,
                          toUserName: donation.assignedNgoName ?? "NGO",
                        ))),
                        child: const Text("RATE NGO"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelinePanel(DonationModel donation) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              const Text("Donation Journey", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...donation.timeline.reversed.map((step) => _buildTimelineStep(step, step == donation.timeline.last)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep(TimelineModel step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isLast ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [if (isLast) const BoxShadow(color: Colors.green, blurRadius: 4)],
                ),
              ),
              Expanded(
                child: Container(width: 2, color: Colors.grey[200]),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusTitle(step.status),
                        style: TextStyle(fontWeight: FontWeight.bold, color: isLast ? Colors.black : Colors.grey[600]),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(step.time),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(color: isLast ? Colors.grey[700] : Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted': return "Partner is checking details";
      case 'on_the_way': return "NGO Partner is on the way";
      case 'arrived': return "Partner has arrived at location";
      case 'picked_up': return "Food is being transported";
      case 'delivered': return "Distributing food to people";
      case 'completed': return "Donation completed successfully";
      default: return "Waiting for NGO acceptance";
    }
  }

  String _getStatusTitle(String status) {
    return status.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }
}
