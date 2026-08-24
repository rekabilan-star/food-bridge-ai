import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UIUtils {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = Colors.red,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      default:
        return lower.split('_').map((e) => e.isNotEmpty ? (e[0].toUpperCase() + e.substring(1)) : '').join(' ');
    }
  }

  static Color getStatusColor(String? status) {
    if (status == null) return Colors.orange;
    final lower = status.trim().toLowerCase();
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('claimed')) {
      return const Color(0xFF2E7D32);
    }
    if (lower.contains('picked') || lower.contains('route') || lower.contains('transit') || lower.contains('arrived')) {
      return Colors.purple.shade700;
    }
    if (lower.contains('accepted') || lower.contains('matched') || lower.contains('assigned')) {
      return Colors.blue.shade700;
    }
    if (lower.contains('cancelled') || lower.contains('rejected')) {
      return Colors.red.shade700;
    }
    return Colors.orange.shade800;
  }
}
