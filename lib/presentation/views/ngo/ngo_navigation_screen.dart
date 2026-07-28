import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_scanner_screen.dart';

class NgoNavigationScreen extends StatefulWidget {
  final String donationId;
  const NgoNavigationScreen({super.key, required this.donationId});

  @override
  State<NgoNavigationScreen> createState() => _NgoNavigationScreenState();
}

class _NgoNavigationScreenState extends State<NgoNavigationScreen> {
  final MapController _mapController = MapController();
  final LatLng _destination = const LatLng(13.0475, 80.2520); // Demo destination
  final LatLng _currentPos = const LatLng(13.0827, 80.2707); // Demo current pos

  Future<void> _launchMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${_destination.latitude},${_destination.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch Maps")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Navigating to Donor")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPos,
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
                    point: _destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.ngoColor,
                    child: Icon(Icons.timer, color: Colors.white, size: 18)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("12 mins to reach",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("1.8 KM • Light traffic",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                ),
                IconButton(
                  onPressed: _launchMaps,
                  icon: const Icon(Icons.directions, color: AppColors.ngoColor),
                  tooltip: "Open in Native Maps",
                ),
              ],
            ),
            const Divider(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          QrScannerScreen(donationId: widget.donationId))),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("ARRIVED AT DONOR"),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.ngoColor),
            ),
          ],
        ),
      ),
    );
  }
}
