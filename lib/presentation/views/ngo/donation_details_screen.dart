import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/donation_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../core/utils/intent_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../common/widgets/custom_app_bar.dart';
import '../common/widgets/primary_button.dart';
import '../common/widgets/secondary_button.dart';
import '../common/widgets/standard_card.dart';
import '../common/widgets/status_badge.dart';
import '../common/widgets/section_heading.dart';
import '../common/chat_screen.dart';
import 'ngo_tracking_screen.dart';
import 'delivery_confirmation_screen.dart';

class DonationDetailsScreen extends StatefulWidget {
  final DonationModel donation;
  const DonationDetailsScreen({super.key, required this.donation});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;
    final isExpired = donation.isExpired;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: "Donation Details"),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(donation),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(donation),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeading(title: "Food Information"),
                  const SizedBox(height: AppSpacing.sm),
                  _buildFoodSpecsCard(donation),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeading(title: "Pickup Location"),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLocationCard(donation),
                  if (donation.specialInstructions != null && donation.specialInstructions!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeading(title: "Special Instructions"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionsCard(donation.specialInstructions!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _buildContextualAction(context, donation, isExpired),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveFoodImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (File(trimmed).existsSync()) {
      return trimmed;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootServer$cleanPath';
  }

  Widget _buildImageHeader(DonationModel donation) {
    final rawUrl = donation.imageUrl;
    final resolvedUrl = _resolveFoodImageUrl(rawUrl);
    final isLocalFile = rawUrl.isNotEmpty && File(rawUrl).existsSync();

    if (resolvedUrl.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: AppColors.accent.withValues(alpha: 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fastfood_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Food Image Not Provided",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black12,
      child: isLocalFile
          ? Image.file(File(rawUrl), fit: BoxFit.cover, width: double.infinity)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.accent.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textSecondary),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(DonationModel donation) {
    return StandardCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: StatusBadge(
                  status: donation.status,
                  label: _formatStatusCompact(donation),
                ),
              ),
              if (donation.category.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    donation.category,
                    style: AppTypography.captionBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(donation.foodName, style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Donated by ${donation.donorName ?? 'Anonymous Donor'}",
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (donation.donorPhone != null && donation.donorPhone!.isNotEmpty) ...[
                IconButton(
                  onPressed: () => IntentUtils.makePhoneCall(donation.donorPhone!),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                  tooltip: "Call Donor",
                ),
                const SizedBox(width: 6),
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
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                  tooltip: "Chat with Donor",
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSpecsCard(DonationModel donation) {
    final prepFormatted = DateFormat('hh:mm a, dd MMM').format(donation.preparedTime);
    final expiryFormatted = DateFormat('hh:mm a, dd MMM').format(donation.bestBeforeTime);

    return StandardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildSpecRow(Icons.restaurant_rounded, "Servings Count", "${donation.membersServed} Members / Servings"),
          const Divider(color: AppColors.border, height: 16),
          _buildSpecRow(Icons.access_time_rounded, "Prepared Time", prepFormatted),
          const Divider(color: AppColors.border, height: 16),
          _buildSpecRow(
            Icons.timer_outlined,
            "Best Before",
            expiryFormatted,
            valueColor: donation.isExpired ? AppColors.error : AppColors.warning,
          ),
          if (donation.checklist.isFreshlyPrepared || donation.checklist.isProperlyPacked) ...[
            const Divider(color: AppColors.border, height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, size: 18, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text("Food Quality:", style: AppTypography.bodySmall),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (donation.checklist.isFreshlyPrepared)
                        _buildQualityPill("Freshly Prepared"),
                      if (donation.checklist.isProperlyPacked)
                        _buildQualityPill("Properly Packed"),
                      _buildQualityPill(donation.checklist.foodType),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.captionBold.copyWith(color: AppColors.success, fontSize: 10),
      ),
    );
  }

  String _formatStatusCompact(DonationModel donation) {
    if (donation.isExpired && donation.status == 'waiting') {
      return 'EXPIRED';
    }
    switch (donation.status.toLowerCase()) {
      case 'waiting':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'on_the_way':
        return 'IN TRANSIT';
      case 'arrived':
        return 'ARRIVED';
      case 'picked_up':
        return 'PICKED UP';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'expired':
        return 'EXPIRED';
      default:
        return donation.status.toUpperCase();
    }
  }

  Widget _buildSpecRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(DonationModel donation) {
    return StandardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pickup Address", style: AppTypography.subsectionHeading),
                    const SizedBox(height: 2),
                    Text(
                      donation.pickupAddress,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            text: "OPEN IN MAPS NAVIGATION",
            icon: Icons.directions_outlined,
            onPressed: () => IntentUtils.openMapNavigation(donation.latitude, donation.longitude),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(String instructions) {
    return StandardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              instructions,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualAction(BuildContext context, DonationModel donation, bool isExpired) {
    final auth = context.watch<AuthViewModel>();
    final viewModel = context.watch<DonationViewModel>();

    if (auth.user?.role != UserRole.ngo) return const SizedBox.shrink();

    final statusLower = donation.status.toLowerCase();

    // 1. Completed
    if (statusLower == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
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
      );
    }

    // 2. Picked up -> Proceed to Delivery
    if (statusLower == 'picked_up') {
      return PrimaryButton(
        text: "PROCEED TO DELIVERY",
        icon: Icons.local_shipping_rounded,
        isLoading: viewModel.isLoading,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeliveryConfirmationScreen(donation: donation)),
        ),
      );
    }

    // 3. Accepted / On the way / Arrived -> Track Rescue
    if (statusLower == 'accepted' || statusLower == 'on_the_way' || statusLower == 'arrived') {
      return PrimaryButton(
        text: "TRACK PICKUP / RESCUE",
        icon: Icons.navigation_rounded,
        isLoading: viewModel.isLoading,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)),
        ),
      );
    }

    // 4. Expired
    if (statusLower == 'expired' || isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "This food donation has expired and is no longer available for rescue.",
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // 5. Cancelled / Rejected
    if (statusLower == 'cancelled' || statusLower == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              "This donation was ${statusLower == 'cancelled' ? 'cancelled' : 'rejected'}.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // 6. Waiting -> Actionable Accept Donation
    return PrimaryButton(
      text: "ACCEPT DONATION",
      icon: Icons.check_circle_rounded,
      isLoading: viewModel.isLoading || _isActionInProgress,
      onPressed: (viewModel.isLoading || _isActionInProgress)
          ? null
          : () => _confirmAcceptance(context, viewModel, donation),
    );
  }

  void _confirmAcceptance(BuildContext context, DonationViewModel viewModel, DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text("Accept Donation?", style: AppTypography.sectionHeading),
          ],
        ),
        content: Text(
          "Once accepted, your organization commits to picking up '${donation.foodName}' (${donation.membersServed} servings) before it expires.\n\nDo you want to proceed?",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          SecondaryButton(
            text: "CANCEL",
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: AppSpacing.xs),
          PrimaryButton(
            text: "CONFIRM RESCUE",
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionInProgress = true);
              final success = await viewModel.updateDonationStatus(donation.id, 'accepted');
              if (!mounted) return;
              setState(() => _isActionInProgress = false);
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Donation Accepted! Task added to your Rescue Control."),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/ngo-dashboard', (route) => false);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.errorMessage ?? "Failed to accept donation"),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
