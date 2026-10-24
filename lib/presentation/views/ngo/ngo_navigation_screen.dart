import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import 'qr_scanner_screen.dart';

class NgoNavigationScreen extends StatefulWidget {
  final String donationId;
  final double? destinationLat;
  final double? destinationLng;
  const NgoNavigationScreen({
    super.key,
    required this.donationId,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  State<NgoNavigationScreen> createState() => _NgoNavigationScreenState();
}

class _NgoNavigationScreenState extends State<NgoNavigationScreen> {
  final MapController _mapController = MapController();
  late final LatLng _destination;
  final LatLng _currentPos = const LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    _destination = LatLng(
      widget.destinationLat ?? 13.0475,
      widget.destinationLng ?? 80.2520,
    );
  }

  Future<void> _launchMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${_destination.latitude},${_destination.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch external maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Navigating to Pickup"),
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
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                    ),
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.sheetTop,
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Navigating to Food Pickup", style: AppTypography.subsectionHeading),
                      const SizedBox(height: 2),
                      Text(
                        "Destination verified within 20 KM service radius",
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              text: "OPEN IN GOOGLE MAPS",
              icon: Icons.directions_outlined,
              onPressed: _launchMaps,
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              text: "ARRIVED AT DONOR LOCATION",
              icon: Icons.check_circle_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrScannerScreen(donationId: widget.donationId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
