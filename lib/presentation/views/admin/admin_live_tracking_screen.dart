import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

class AdminLiveTrackingScreen extends StatefulWidget {
  const AdminLiveTrackingScreen({super.key});

  @override
  State<AdminLiveTrackingScreen> createState() => _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen> {
  final SocketService _socketService = SocketService();
  final Map<String, _VolunteerUnit> _units = {};
  final MapController _mapController = MapController();
  _VolunteerUnit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _socketService.onLocationUpdated((data) {
      _updateVolunteerMarker(data);
    });
  }

  void _updateVolunteerMarker(Map<String, dynamic> data) {
    final String userId = data['userId']?.toString() ?? 'unknown';
    final double? lat = (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : null;
    final double? lng = (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : null;
    final double heading = (data['heading'] is num) ? (data['heading'] as num).toDouble() : 0.0;

    if (lat == null || lng == null) return;

    if (mounted) {
      setState(() {
        _units[userId] = _VolunteerUnit(
          userId: userId,
          position: LatLng(lat, lng),
          heading: heading,
          lastUpdated: DateTime.now(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fleet Operations Map",
          style: AppTypography.pageTitle.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              if (_units.isNotEmpty) {
                _mapController.move(_units.values.first.position, 14);
              } else {
                _mapController.move(const LatLng(13.0827, 80.2707), 13);
              }
            },
            tooltip: "Recenter Map",
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(13.0827, 80.2707), // Chennai Default
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mca_app',
              ),
              MarkerLayer(
                markers: _units.values.map((unit) {
                  return Marker(
                    point: unit.position,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUnit = unit;
                        });
                      },
                      child: Transform.rotate(
                        angle: unit.heading * (3.14159 / 180),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.adminColor, width: 2),
                            boxShadow: AppShadows.card,
                          ),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: AppColors.adminColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Status Pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.95),
                borderRadius: AppRadius.borderFull,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.elevated,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _units.isNotEmpty ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Text(
                    _units.isNotEmpty
                        ? "Active Fleet: ${_units.length} unit${_units.length > 1 ? 's' : ''} broadcasting"
                        : "Fleet Standby: Awaiting volunteer GPS telemetry",
                    style: AppTypography.captionBold,
                  ),
                ],
              ),
            ),
          ),

          // Selected Unit Card
          if (_selectedUnit != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: AppSpacing.paddingBase,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.borderXl,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bike_rounded, color: AppColors.adminColor),
                        AppSpacing.hGapSm,
                        Text(
                          "Volunteer ID: ${_selectedUnit!.userId.substring((_selectedUnit!.userId.length - 6).clamp(0, _selectedUnit!.userId.length))}",
                          style: AppTypography.subsectionHeading,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _selectedUnit = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lat: ${_selectedUnit!.position.latitude.toStringAsFixed(4)}, Lng: ${_selectedUnit!.position.longitude.toStringAsFixed(4)}",
                      style: AppTypography.caption,
                    ),
                    Text(
                      "Last ping: ${DateFormat('hh:mm:ss a').format(_selectedUnit!.lastUpdated)}",
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

class _VolunteerUnit {
  final String userId;
  final LatLng position;
  final double heading;
  final DateTime lastUpdated;

  _VolunteerUnit({
    required this.userId,
    required this.position,
    required this.heading,
    required this.lastUpdated,
  });
}
