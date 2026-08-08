import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/location_provider_v2.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/primary_button.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locProvider = context.read<LocationProviderV2>();
      if (locProvider.location == null) {
        locProvider.fetchLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProviderV2>();
    final lat = locProvider.location?.latitude ?? 11.0168;
    final lng = locProvider.location?.longitude ?? 76.9558;
    final currentLatLng = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(
        title: "Live Location",
      ),
      body: Stack(
        children: [
          // Map Display
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mca_app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLatLng,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderStrokeWidth: 2,
                    borderColor: AppColors.primary.withValues(alpha: 0.4),
                    radius: 60,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLatLng,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Location Verified Pill Badge on Map
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Location Verified",
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // Floating Recenter GPS Button
          Positioned(
            right: 20,
            bottom: 260,
            child: FloatingActionButton(
              heroTag: 'recenter_gps',
              onPressed: () {
                locProvider.fetchLocation();
                _mapController.move(currentLatLng, 15.0);
              },
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location_rounded, color: AppColors.textPrimary),
            ),
          ),

          // Bottom Location Detail Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Your Location",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    locProvider.location?.fullAddress ?? "Peelamedu, Coimbatore, Tamil Nadu 641004, India",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Latitude & Longitude Grid
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Latitude",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${lat.toStringAsFixed(4)}° N",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 30, width: 1, color: AppColors.border),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Longitude",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${lng.toStringAsFixed(4)}° E",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Accuracy Indicator
                  Row(
                    children: [
                      const Text(
                        "Accuracy",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "± ${(locProvider.location?.accuracy ?? 12).toInt()} meters",
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Refresh Location Button
                  PrimaryButton(
                    text: "Refresh Location",
                    icon: Icons.refresh_rounded,
                    isLoading: locProvider.isLoading,
                    onPressed: () => locProvider.fetchLocation(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
