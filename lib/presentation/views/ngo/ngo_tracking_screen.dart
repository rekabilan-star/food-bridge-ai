import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/donation_viewmodel.dart';
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
  bool _isActionLoading = false;

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
      debugPrint('[GPS] NGO Position update: Lat ${position.latitude}, Lng ${position.longitude}');
      if (mounted) {
        context.read<DonationViewModel>().updateNgoLocation(position.latitude, position.longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationViewModel>().currentDonation;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Rescue Navigation"),
      body: donation == null
          ? const AppLoadingIndicator(message: "Loading rescue details & route...")
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

                // Top floating status pill
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: _buildTopStatusPill(donation),
                ),

                // Bottom Action & Mission Panel
                _buildActionPanel(donation),
              ],
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
