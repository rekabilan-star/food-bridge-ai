import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';
import '../../../core/utils/impact_certificate_service.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/utils/ui_utils.dart';
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
    final steps = ["Waiting", "Accepted", "Picked Up", "Completed"];
    int currentStep = 0;
    final lower = currentStatus.toLowerCase();
    if (lower == 'completed' || lower == 'claimed' || lower == 'delivered') {
      currentStep = 3;
    } else if (lower == 'picked_up' || lower == 'picked up' || lower == 'on_the_way' || lower == 'arrived' || lower == 'in_transit' || lower == 'en_route') {
      currentStep = 2;
    } else if (lower == 'accepted' || lower == 'matched' || lower == 'assigned') {
      currentStep = 1;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isPassed = index <= currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPassed ? AppColors.primary : Colors.grey.shade200,
                              border: isCurrent ? Border.all(color: AppColors.accent, width: 3) : null,
                            ),
                            child: isPassed
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : Center(child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
                          ),
                          if (!isLast)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                height: 2.5,
                                color: index < currentStep ? AppColors.primary : Colors.grey.shade200,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isPassed ? AppColors.textPrimary : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrackingInfoCard(DonationModel donation) {
    final statusText = StatusUtils.formatStatusLabel(donation.status);
    final statusColor = StatusUtils.getStatusColor(donation.status);
    final latestTime = donation.timeline.isNotEmpty ? DateFormat('h:mm a').format(donation.timeline.last.time.toLocal()) : null;

    String distText = "Distance unavailable";
    String etaText = "ETA unavailable";
    if (donation.latitude != 0 && donation.longitude != 0 && donation.ngoLat != null && donation.ngoLng != null) {
      final meters = Geolocator.distanceBetween(donation.latitude, donation.longitude, donation.ngoLat!, donation.ngoLng!);
      final km = meters / 1000;
      distText = "${km.toStringAsFixed(1)} km away";
      final mins = (km / 30 * 60).round();
      etaText = "~ ${mins > 0 ? mins : 1} mins";
    }

    final isCompleted = donation.status.toLowerCase() == 'completed' || donation.status.toLowerCase() == 'delivered';

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("CURRENT STATUS", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  if (latestTime != null)
                    Text("Updated $latestTime", style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCompleted ? Icons.check_circle : Icons.circle, size: 12, color: statusColor),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: Text(
                        statusText,
                        key: ValueKey(statusText),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue[50],
                    child: Icon(isCompleted ? Icons.check_circle : Icons.local_shipping, color: Colors.blue[800]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.assignedNgoName ?? "Finding NGO Partner...",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            distText,
                            key: ValueKey(distText),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
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
                        const SizedBox(width: 6),
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
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Estimated Time", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        etaText,
                        key: ValueKey(etaText),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (isCompleted) ...[
                const Divider(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Food successfully delivered.${latestTime != null ? ' Completed at $latestTime' : ''}",
                          style: TextStyle(color: Colors.green[900], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutBack),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ImpactCertificateService.generateAndDisplay(donation),
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text("CERTIFICATE"),
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
                        icon: const Icon(Icons.star_outline, size: 18),
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
      initialChildSize: 0.14,
      minChildSize: 0.14,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        final sortedTimeline = List<TimelineModel>.from(donation.timeline)
          ..sort((a, b) => a.time.compareTo(b.time));

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
              const SizedBox(height: 16),
              const Text("Rescue Timeline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (sortedTimeline.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      "Tracking history is not available yet.",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                ...sortedTimeline.asMap().entries.map((entry) => _buildTimelineStep(entry.value, entry.key == sortedTimeline.length - 1)),
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
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        StatusUtils.formatStatusLabel(step.status),
                        style: TextStyle(
                          fontWeight: isLast ? FontWeight.bold : FontWeight.w600,
                          color: isLast ? Colors.black : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(step.time.toLocal()),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(color: isLast ? Colors.grey[800] : Colors.grey[500], fontSize: 12, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
