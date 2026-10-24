import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';
import '../../../core/utils/impact_certificate_service.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/status_badge.dart';
import 'widgets/primary_button.dart';
import 'widgets/secondary_button.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/empty_state.dart';

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
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Track Rescue Mission",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: () => context.read<DonationViewModel>().fetchDonationDetails(widget.donationId),
          ),
        ],
      ),
      body: donation == null && isLoading
          ? const AppLoadingIndicator(message: "Loading mission tracking...")
          : donation == null
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: "Mission Not Found",
                  message: "Donation details could not be loaded at this time.",
                )
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
                                    child: const Icon(Icons.location_on_rounded, color: AppColors.success, size: 45),
                                  ),
                                  if (donation.ngoLat != null && donation.ngoLng != null)
                                    Marker(
                                      point: LatLng(donation.ngoLat!, donation.ngoLng!),
                                      width: 50,
                                      height: 50,
                                      child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 45),
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
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.base),
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
                              color: isPassed ? AppColors.primary : AppColors.border,
                              border: isCurrent ? Border.all(color: AppColors.secondary, width: 3) : null,
                            ),
                            child: isPassed
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : Center(child: Text("${index + 1}", style: AppTypography.caption.copyWith(fontSize: 10))),
                          ),
                          if (!isLast)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                                height: 2.5,
                                color: index < currentStep ? AppColors.primary : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        steps[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isPassed ? AppColors.textPrimary : AppColors.textSecondary,
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
      top: AppSpacing.base,
      left: AppSpacing.base,
      right: AppSpacing.base,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: AppShadows.elevated,
        ),
        padding: AppSpacing.paddingBase,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CURRENT STATUS",
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (latestTime != null)
                  Text(
                    "Updated $latestTime",
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
              ],
            ),
            AppSpacing.vGapSm,
            StatusBadge(status: donation.status),
            AppSpacing.vGapMd,
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent,
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.assignedNgoName ?? "Finding NGO Partner...",
                        style: AppTypography.subsectionHeading,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          distText,
                          key: ValueKey(distText),
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                if (donation.assignedNgoId != null && donation.assignedNgoPhone != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                          receiverId: donation.assignedNgoId!,
                          donationId: donation.id,
                          receiverName: donation.assignedNgoName ?? "NGO",
                        ))),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                        style: IconButton.styleFrom(backgroundColor: AppColors.accent),
                      ),
                      AppSpacing.hGapXs,
                      IconButton(
                        onPressed: () => IntentUtils.makePhoneCall(donation.assignedNgoPhone!),
                        icon: const Icon(Icons.phone_rounded, color: AppColors.success),
                        style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
              ],
            ),
            if (donation.status == 'on_the_way' || donation.status == 'accepted') ...[
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Estimated Arrival", style: AppTypography.bodySmall),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      etaText,
                      key: ValueKey(etaText),
                      style: AppTypography.captionBold.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              const Divider(height: 20, color: AppColors.border),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        "Food successfully delivered.${latestTime != null ? ' Completed at $latestTime' : ''}",
                        style: AppTypography.captionBold.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutBack),
              AppSpacing.vGapMd,
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: "CERTIFICATE",
                      icon: Icons.verified_rounded,
                      onPressed: () => ImpactCertificateService.generateAndDisplay(donation),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: PrimaryButton(
                      text: "RATE NGO",
                      icon: Icons.star_outline_rounded,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(
                        donationId: donation.id,
                        toUserId: donation.assignedNgoId ?? "",
                        toUserName: donation.assignedNgoName ?? "NGO",
                      ))),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.sheetTop,
            boxShadow: AppShadows.elevated,
          ),
          child: ListView(
            controller: scrollController,
            padding: AppSpacing.pageHorizontal,
            children: [
              AppSpacing.vGapMd,
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              AppSpacing.vGapBase,
              Text("Rescue Timeline", style: AppTypography.sectionHeading),
              AppSpacing.vGapLg,
              if (sortedTimeline.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      "Tracking history is not available yet.",
                      style: AppTypography.caption,
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
                  color: isLast ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    if (isLast)
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6),
                  ],
                ),
              ),
              Expanded(
                child: Container(width: 2, color: AppColors.border),
              ),
            ],
          ),
          AppSpacing.hGapMd,
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
                        style: isLast
                            ? AppTypography.subsectionHeading.copyWith(fontSize: 14)
                            : AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        DateFormat('h:mm a').format(step.time.toLocal()),
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    AppSpacing.vGapXs,
                    Text(
                      step.description,
                      style: AppTypography.caption,
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
