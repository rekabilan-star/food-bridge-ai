import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../viewmodels/live_map_viewmodel.dart';
import '../../../core/services/socket_service.dart';
import '../../../data/models/donation_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import '../common/widgets/status_badge.dart';
import '../common/widgets/app_loading_indicator.dart';
import '../common/widgets/tracking_map_controls.dart';
import '../common/widgets/route_summary_card.dart';
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
  late final LiveMapViewModel _liveMapVM;
  StreamSubscription<Position>? _positionStream;
  bool _isActionLoading = false;
  String? _initializedDonationId;
  String? _gpsErrorMessage;
  bool _isGpsPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _liveMapVM = LiveMapViewModel();
    _initLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationViewModel>().fetchDonationDetails(widget.donationId);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _liveMapVM.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsErrorMessage = "Device location services are disabled. Please enable GPS.";
            _isGpsPermissionDenied = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _gpsErrorMessage = "Location permission is required to stream rescue navigation.";
              _isGpsPermissionDenied = true;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsErrorMessage = "Location permissions are permanently denied. Please enable in App Settings.";
            _isGpsPermissionDenied = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _gpsErrorMessage = null;
          _isGpsPermissionDenied = false;
        });
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );

      debugPrint('[GPS] Starting NGO tracking stream');
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        debugPrint('[GPS] NGO Position update: Lat ${position.latitude}, Lng ${position.longitude}');
        if (mounted) {
          context.read<DonationViewModel>().updateNgoLocation(position.latitude, position.longitude);

          try {
            final auth = context.read<AuthViewModel>();
            final userId = auth.user?.id ?? '';
            SocketService().updateLocation(
              userId: userId,
              donationId: widget.donationId,
              latitude: position.latitude,
              longitude: position.longitude,
              heading: position.heading,
              speed: position.speed,
            );
          } catch (_) {}

          _liveMapVM.setManualVolunteerPosition(
            LatLng(position.latitude, position.longitude),
            heading: position.heading,
          );
        }
      });
    } catch (e) {
      debugPrint('[GPS] Location tracking error: $e');
      if (mounted) {
        setState(() => _gpsErrorMessage = "Could not initialize GPS stream.");
      }
    }
  }

  void _checkAndInitRoute(DonationModel donation) {
    if (_initializedDonationId != donation.id) {
      _initializedDonationId = donation.id;
      _liveMapVM.initTracking(donation, true);
    }
  }

  void _fitRoute(DonationModel donation) {
    final points = <LatLng>[
      LatLng(donation.latitude, donation.longitude),
      if (_liveMapVM.volunteerPos != null) _liveMapVM.volunteerPos!,
      ..._liveMapVM.routePoints,
    ];

    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        _mapController.move(points.first, 15);
      } else {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(top: 140, bottom: 220, left: 40, right: 40),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationViewModel>().currentDonation;

    if (donation != null) {
      _checkAndInitRoute(donation);
    }

    return ChangeNotifierProvider<LiveMapViewModel>.value(
      value: _liveMapVM,
      child: Consumer<LiveMapViewModel>(
        builder: (context, mapVM, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: const CustomAppBar(title: "Rescue Navigation"),
            body: donation == null
                ? const AppLoadingIndicator(message: "Loading rescue details & route...")
                : Stack(
                    children: [
                      // Full Map with Live Road Polyline
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

                          // Live OSRM Road Polyline Layer
                          if (mapVM.routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mapVM.routePoints,
                                  strokeWidth: 4.5,
                                  color: AppColors.primary,
                                  borderStrokeWidth: 2.0,
                                  borderColor: Colors.white,
                                ),
                              ],
                            ),

                          // Markers
                          MarkerLayer(
                            markers: [
                              // 1. Food Pickup Destination Marker
                              Marker(
                                point: LatLng(donation.latitude, donation.longitude),
                                width: 48,
                                height: 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
                                ),
                              ),

                              // 2. NGO Self Vehicle Position Marker
                              if (mapVM.volunteerPos != null)
                                Marker(
                                  point: mapVM.volunteerPos!,
                                  width: 48,
                                  height: 48,
                                  child: Transform.rotate(
                                    angle: mapVM.volunteerHeading * (3.14159 / 180),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Top Floating Status Pill & Route Summary
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTopStatusPill(donation),
                            if (mapVM.routeDistanceKm > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              RouteSummaryCard(
                                distanceKm: mapVM.routeDistanceKm,
                                durationMins: mapVM.routeDurationMins,
                                routingSource: mapVM.routingSource,
                                isLoading: mapVM.isLoadingRoute,
                                lastUpdated: mapVM.lastLocationUpdate,
                                onRefresh: () => mapVM.refreshRoute(donation),
                              ),
                            ],
                            if (_gpsErrorMessage != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              _buildGpsWarningCard(),
                            ],
                          ],
                        ),
                      ),

                      // Floating Map Controls (Right Side)
                      Positioned(
                        top: 170,
                        right: AppSpacing.md,
                        child: TrackingMapControls(
                          mapController: _mapController,
                          focusPoints: [
                            LatLng(donation.latitude, donation.longitude),
                            if (mapVM.volunteerPos != null) mapVM.volunteerPos!,
                            ...mapVM.routePoints,
                          ],
                          connectionStatus: _gpsErrorMessage != null
                              ? TrackingConnectionStatus.offline
                              : (mapVM.volunteerPos != null
                                  ? TrackingConnectionStatus.live
                                  : TrackingConnectionStatus.connecting),
                          onRecenter: () => _fitRoute(donation),
                        ),
                      ),

                      // Bottom Action & Mission Panel
                      _buildActionPanel(donation),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTopStatusPill(DonationModel donation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _getMissionSubtitle(donation.status),
              style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusBadge(
            status: donation.status,
            label: StatusUtils.formatStatusLabel(donation.status).toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsWarningCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _gpsErrorMessage ?? "Location services unavailable",
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_isGpsPermissionDenied) {
                Geolocator.openAppSettings();
              } else {
                Geolocator.openLocationSettings();
              }
              _initLocationTracking();
            },
            child: Text(
              _isGpsPermissionDenied ? "SETTINGS" : "RETRY",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _getMissionSubtitle(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Mission Assigned • Ready to depart';
      case 'on_the_way':
        return 'En Route to Donor Location';
      case 'arrived':
        return 'Arrived at Pickup • Scan Donor QR';
      case 'picked_up':
        return 'Food Collected • Deliver to Distribution';
      case 'completed':
        return 'Mission Accomplished';
      default:
        return 'Rescue in Progress';
    }
  }

  Widget _buildActionPanel(DonationModel donation) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Donor and Food Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donation.foodName, style: AppTypography.subsectionHeading),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              donation.pickupAddress,
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons: Chat, Call, External Map
                if (donation.donorId.isNotEmpty)
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: donation.donorId,
                          donationId: donation.id,
                          receiverName: donation.donorName ?? "Donor",
                        ),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                    tooltip: "Chat with Donor",
                  ),
                const SizedBox(width: 4),
                if (donation.donorPhone != null && donation.donorPhone!.isNotEmpty)
                  IconButton(
                    onPressed: () => IntentUtils.makePhoneCall(donation.donorPhone!),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                    tooltip: "Call Donor",
                  ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => IntentUtils.openMapNavigation(donation.latitude, donation.longitude),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
                  tooltip: "Open External Navigation",
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Dynamic Step Action Button
            _buildStepActionButton(donation),
          ],
        ),
      ),
    );
  }

  Widget _buildStepActionButton(DonationModel donation) {
    final status = donation.status.toLowerCase();
    final dVM = context.read<DonationViewModel>();

    if (status == 'accepted') {
      return PrimaryButton(
        text: "START JOURNEY",
        icon: Icons.play_arrow_rounded,
        isLoading: _isActionLoading,
        onPressed: _isActionLoading
            ? null
            : () async {
                setState(() => _isActionLoading = true);
                await dVM.updateDonationStatus(donation.id, 'on_the_way');
                if (mounted) setState(() => _isActionLoading = false);
              },
      );
    } else if (status == 'on_the_way') {
      return PrimaryButton(
        text: "I HAVE ARRIVED AT PICKUP",
        icon: Icons.location_on_rounded,
        isLoading: _isActionLoading,
        onPressed: _isActionLoading
            ? null
            : () async {
                setState(() => _isActionLoading = true);
                await dVM.updateDonationStatus(donation.id, 'arrived');
                if (mounted) setState(() => _isActionLoading = false);
              },
      );
    } else if (status == 'arrived') {
      return PrimaryButton(
        text: "SCAN PICKUP QR CODE",
        icon: Icons.qr_code_scanner_rounded,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QrScannerScreen(donationId: donation.id)),
          );
          if (!mounted) return;
          if (result == true) {
            UIUtils.showSuccessDialog(context, "Pickup Handshake Verified! Food marked as Picked Up.");
          }
        },
      );
    } else if (status == 'picked_up') {
      return PrimaryButton(
        text: "PROCEED TO DELIVERY",
        icon: Icons.local_shipping_rounded,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DeliveryConfirmationScreen(donation: donation)),
          );
        },
      );
    } else if (status == 'completed') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Donation Successfully Rescued & Completed",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            text: "RATE DONOR EXPERIENCE",
            icon: Icons.star_rate_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    donationId: donation.id,
                    toUserId: donation.donorId,
                    toUserName: donation.donorName ?? "Donor",
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
