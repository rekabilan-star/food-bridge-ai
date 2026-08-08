import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';
import '../../../core/utils/receipt_service.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class DonationTrackingScreen extends StatefulWidget {
  final String donationId;
  const DonationTrackingScreen({super.key, required this.donationId});

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonationDetails(widget.donationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationViewModel>().currentDonation;
    final isLoading = context.watch<DonationViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Track Rescue Mission", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DonationViewModel>().fetchDonationDetails(widget.donationId),
          ),
        ],
      ),
      body: donation == null && isLoading
          ? const Center(child: CircularProgressIndicator())
          : donation == null
              ? const Center(child: Text("Donation mission not found"))
              : Column(
                  children: [
                    _buildProgressStepper(donation.status),
                    Expanded(
                      child: Stack(
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
                                    width: 50,
                                    height: 50,
                                    child: const Icon(Icons.location_on, color: Colors.green, size: 45),
                                  ),
                                  if (donation.ngoLat != null && donation.ngoLng != null)
                                    Marker(
                                      point: LatLng(donation.ngoLat!, donation.ngoLng!),
                                      width: 50,
                                      height: 50,
                                      child: const Icon(Icons.directions_car, color: Colors.blue, size: 45),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          _buildTrackingInfoCard(donation),
                          _buildTimelinePanel(donation),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProgressStepper(String currentStatus) {
    final List<String> statuses = ['waiting', 'accepted', 'on_the_way', 'arrived', 'picked_up', 'delivered', 'completed'];
    final int currentIndex = statuses.indexOf(currentStatus);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: List.generate(statuses.length, (index) {
          final bool isCompleted = index <= currentIndex;
          final bool isLast = index == statuses.length - 1;
          
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.primary : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted 
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text("${index + 1}", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getShortStatus(statuses[index]),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isCompleted ? AppColors.primary : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getShortStatus(String status) {
    switch (status) {
      case 'waiting': return "Wait";
      case 'accepted': return "Accept";
      case 'on_the_way': return "Transit";
      case 'arrived': return "Arrival";
      case 'picked_up': return "Pickup";
      case 'delivered': return "Delivery";
      case 'completed': return "Done";
      default: return "";
    }
  }

  Widget _buildTrackingInfoCard(DonationModel donation) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[50],
                    child: Icon(donation.status == 'completed' ? Icons.check_circle : Icons.local_shipping, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
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
                  if (donation.assignedNgoId != null && donation.assignedNgoPhone != null)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                            receiverId: donation.assignedNgoId!,
                            donationId: donation.id,
                            receiverName: donation.assignedNgoName ?? "NGO",
                          ))),
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                          style: IconButton.styleFrom(backgroundColor: Colors.blue[50]),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => IntentUtils.makePhoneCall(donation.assignedNgoPhone!),
                          icon: const Icon(Icons.phone, color: Colors.green),
                          style: IconButton.styleFrom(backgroundColor: Colors.green[50]),
                        ),
                      ],
                    ),
                ],
              ),
              if (donation.status == 'on_the_way' || donation.status == 'accepted') ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Estimated Time", style: TextStyle(color: Colors.grey)),
                      Text("~ 15-20 mins", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                    ],
                  ),
              ],
              if (donation.status == 'completed') ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ReceiptService.generateAndPrintReceipt(donation),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text("RECEIPT"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(
                          donationId: donation.id,
                          toUserId: donation.assignedNgoId ?? "",
                          toUserName: donation.assignedNgoName ?? "NGO",
                        ))),
                        icon: const Icon(Icons.star_outline),
                        label: const Text("RATE NGO"),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              const Text("Rescue Timeline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...donation.timeline.reversed.map((step) => _buildTimelineStep(step, step == donation.timeline.last)),
              const SizedBox(height: 30),
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
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isLast ? AppColors.primary : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [if (isLast) BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)],
                ),
              ),
              Expanded(
                child: Container(width: 2, color: Colors.grey[200]),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusTitle(step.status),
                        style: TextStyle(
                          fontWeight: isLast ? FontWeight.bold : FontWeight.w600,
                          color: isLast ? Colors.black : Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(step.time),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: TextStyle(color: isLast ? Colors.grey[800] : Colors.grey[400], fontSize: 13, height: 1.4),
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
      case 'accepted': return "NGO has accepted your donation";
      case 'on_the_way': return "Rescue partner is on the way";
      case 'arrived': return "Partner has arrived at pickup";
      case 'picked_up': return "Food is collected & in transit";
      case 'delivered': return "Food reached distribution point";
      case 'completed': return "Rescue mission successful! 🎉";
      default: return "Waiting for a nearby partner...";
    }
  }

  String _getStatusTitle(String status) {
    return status.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }
}
