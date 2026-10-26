import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum TrackingConnectionStatus { live, connecting, offline }

/// Floating Map Controls for Live Tracking Screens.
/// Includes Zoom In/Out, Recenter/Fit Bounds, and Live Status Badge.
class TrackingMapControls extends StatelessWidget {
  final MapController mapController;
  final List<LatLng> focusPoints;
  final TrackingConnectionStatus connectionStatus;
  final VoidCallback? onRecenter;

  const TrackingMapControls({
    super.key,
    required this.mapController,
    this.focusPoints = const [],
    this.connectionStatus = TrackingConnectionStatus.live,
    this.onRecenter,
  });

  void _zoomIn() {
    try {
      final currentZoom = mapController.camera.zoom;
      mapController.move(mapController.camera.center, (currentZoom + 1).clamp(3, 18));
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final currentZoom = mapController.camera.zoom;
      mapController.move(mapController.camera.center, (currentZoom - 1).clamp(3, 18));
    } catch (_) {}
  }

  void _fitBounds() {
    if (onRecenter != null) {
      onRecenter!();
      return;
    }

    if (focusPoints.isEmpty) return;

    try {
      if (focusPoints.length == 1) {
        mapController.move(focusPoints.first, 15.5);
      } else {
        final bounds = LatLngBounds.fromPoints(focusPoints);
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 72),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Live GPS / Status Pill
        _buildStatusPill(),
        const SizedBox(height: AppSpacing.sm),

        // Controls Column
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.add_rounded,
                tooltip: "Zoom in",
                onPressed: _zoomIn,
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildControlButton(
                icon: Icons.remove_rounded,
                tooltip: "Zoom out",
                onPressed: _zoomOut,
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildControlButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: "Fit route & markers",
                onPressed: _fitBounds,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    Color dotColor;
    String label;

    switch (connectionStatus) {
      case TrackingConnectionStatus.live:
        dotColor = AppColors.success;
        label = "LIVE GPS";
        break;
      case TrackingConnectionStatus.connecting:
        dotColor = AppColors.warning;
        label = "CONNECTING...";
        break;
      case TrackingConnectionStatus.offline:
        dotColor = AppColors.textSecondary;
        label = "OFFLINE";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionBold.copyWith(
              fontSize: 10,
              color: dotColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
