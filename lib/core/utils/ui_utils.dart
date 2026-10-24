import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_icons.dart';

class UIUtils {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(AppIcons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(AppIcons.success, color: AppColors.success),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onOk != null) onOk();
            },
            child: const Text('OK'),
          ),
        ],
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.button.copyWith(fontSize: 14, color: Colors.white)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = AppColors.error,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        title: Text(title, style: AppTypography.sectionHeading),
        content: Text(message, style: AppTypography.bodyMedium),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppTypography.button.copyWith(fontSize: 13, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(confirmText, style: AppTypography.button.copyWith(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class StatusUtils {
  static String formatStatusLabel(String? status) {
    if (status == null || status.trim().isEmpty) return "Waiting for NGO acceptance";
    final lower = status.trim().toLowerCase();
    switch (lower) {
      case 'waiting':
      case 'available':
      case 'pending':
      case 'requested':
        return "Waiting for NGO acceptance";
      case 'accepted':
      case 'matched':
      case 'assigned':
        return "Accepted by NGO";
      case 'on_the_way':
      case 'in_transit':
      case 'en_route':
        return "NGO On the Way";
      case 'arrived':
        return "NGO Arrived";
      case 'picked_up':
      case 'pickup':
        return "Food Picked Up";
      case 'completed':
      case 'delivered':
      case 'claimed':
        return "Donation Completed";
      case 'cancelled':
      case 'rejected':
        return "Cancelled";
      case 'expired':
        return "Expired";
      default:
        return lower.split('_').map((e) => e.isNotEmpty ? (e[0].toUpperCase() + e.substring(1)) : '').join(' ');
    }
  }

  static Color getStatusColor(String? status) {
    if (status == null) return AppColors.warning;
    final lower = status.trim().toLowerCase();
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('claimed')) {
      return AppColors.success;
    }
    if (lower.contains('picked') || lower.contains('route') || lower.contains('transit') || lower.contains('arrived')) {
      return AppColors.primary;
    }
    if (lower.contains('accepted') || lower.contains('matched') || lower.contains('assigned')) {
      return AppColors.info;
    }
    if (lower.contains('cancelled') || lower.contains('rejected') || lower.contains('expired')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }
}
