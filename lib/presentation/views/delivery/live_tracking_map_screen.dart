import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/live_map_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/theme/app_colors.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  final DonationModel donation;

  const LiveTrackingMapScreen({super.key, required this.donation});

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  final MapController _mapController = MapController();
  bool _followVolunteer = true;
  late LiveMapViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LiveMapViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      final role = auth.user!.role.toString().split('.').last;
      final isVolunteer = role == 'volunteer' || role == 'ngo';
      _viewModel.initTracking(widget.donation, isVolunteer);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<LiveMapViewModel>(
        builder: (context, model, _) {
          // Auto-follow logic
          if (_followVolunteer && model.volunteerPos != null) {
            _mapController.move(model.volunteerPos!, 15);
          }

          return Scaffold(
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(widget.donation.latitude, widget.donation.longitude),
                    initialZoom: 15,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        setState(() => _followVolunteer = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mca_app',
                    ),
                    if (model.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: model.routePoints,
                            strokeWidth: 4.5,
                            color: AppColors.primary,
                            borderStrokeWidth: 2,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.donation.latitude, widget.donation.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                        ),
                        if (model.volunteerPos != null)
                          Marker(
                            point: model.volunteerPos!,
                            width: 40,
                            height: 40,
                            child: Transform.rotate(
                              angle: model.volunteerHeading * (3.14159 / 180),
                              child: const Icon(Icons.directions_bike, color: Colors.blue, size: 40),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                _buildOverlay(model),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlay(LiveMapViewModel model) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(model.currentAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (model.isLoadingRoute)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else ...[
                      Text(
                        model.routePoints.isNotEmpty 
                          ? '${model.routeDurationMins}m' 
                          : model.eta, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)
                      ),
                      Text(
                        model.routePoints.isNotEmpty 
                          ? '${model.routeDistanceKm.toStringAsFixed(1)}km' 
                          : 'ETA', 
                        style: const TextStyle(fontSize: 10, color: Colors.grey)
                      ),
                      if (model.routePoints.isNotEmpty)
                        Text(
                          model.routingSource == "OSRM" ? "Road Route" : "Estimated",
                          style: TextStyle(fontSize: 8, color: Colors.grey[400], fontWeight: FontWeight.bold),
                        ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _followVolunteer = true),
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Locate'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => IntentUtils.makePhoneCall(widget.donation.donorPhone ?? ''),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
