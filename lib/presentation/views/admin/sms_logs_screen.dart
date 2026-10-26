import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/sms_log_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/status_badge.dart';
import '../common/widgets/empty_state.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _loadData({int page = 1}) {
    _currentPage = page;
    final vm = context.read<AdminViewModel>();
    vm.fetchSmsLogs(
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      page: page,
    );
    vm.fetchSmsStats();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final logs = viewModel.smsLogs;
    final stats = viewModel.smsStats;
    final isLoading = viewModel.isLoading;
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "SMS Notification Logs",
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadData(page: _currentPage),
            tooltip: "Refresh Logs",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(page: _currentPage),
        color: AppColors.adminColor,
        child: Column(
          children: [
            if (stats.isNotEmpty) _buildStatsHeader(stats),
            _buildSearchAndFilters(),
            Expanded(
              child: isLoading && logs.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : errorMessage != null && logs.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EmptyState(
                              icon: Icons.error_outline_rounded,
                              iconColor: AppColors.error,
                              title: "Failed to Fetch SMS Logs",
                              message: errorMessage,
                              actionText: "RETRY",
                              onActionPressed: () => _loadData(page: 1),
                            ),
                          ),
                        )
                      : logs.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: const EmptyState(
                                  icon: Icons.mark_email_unread_rounded,
                                  title: "No SMS Logs Recorded",
                                  message: "No dispatch notifications or OTP messages found.",
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: AppSpacing.pagePadding,
                                    itemCount: logs.length,
                                    itemBuilder: (context, index) {
                                      final log = logs[index];
                                      return _buildLogCard(log);
                                    },
                                  ),
                                ),
                                _buildPaginationControls(viewModel),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(Map stats) {
    final statusList = stats['status'] as List? ?? [];
    int getStatusCount(String s) {
      for (final e in statusList) {
        if (e is Map && (e['_id']?.toString().toLowerCase() ?? '') == s.toLowerCase()) {
          return (e['count'] is num) ? (e['count'] as num).toInt() : 0;
        }
      }
      return 0;
    }

    final sent = getStatusCount('sent') + getStatusCount('delivered');
    final failed = getStatusCount('failed');

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _buildMiniStatBadge("Delivered/Sent", '$sent', AppColors.success),
          AppSpacing.hGapMd,
          _buildMiniStatBadge("Failed Dispatches", '$failed', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildMiniStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.captionBold.copyWith(color: color, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            onSubmitted: (_) => _loadData(page: 1),
            decoration: InputDecoration(
              hintText: "Filter by recipient phone number...",
              hintStyle: AppTypography.fieldHint,
              prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.textSecondary),
              suffixIcon: _phoneController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _phoneController.clear();
                        _loadData(page: 1);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderLg,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderLg,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderLg,
                borderSide: const BorderSide(color: AppColors.adminColor, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          AppSpacing.vGapSm,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatusChip("All Logs", null),
                AppSpacing.hGapSm,
                _buildStatusChip("Delivered", 'delivered'),
                AppSpacing.hGapSm,
                _buildStatusChip("Sent", 'sent'),
                AppSpacing.hGapSm,
                _buildStatusChip("Failed", 'failed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.adminColor,
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(color: isSelected ? AppColors.adminColor : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
          _loadData(page: 1);
        }
      },
    );
  }

  Widget _buildLogCard(SmsLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.adminColor.withValues(alpha: 0.1),
            child: const Icon(Icons.sms_outlined, color: AppColors.adminColor, size: 20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log.phoneNumber,
                  style: AppTypography.subsectionHeading.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: log.status),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.userName != null) ...[
                const SizedBox(height: 2),
                Text(
                  "User: ${log.userName} (${log.userEmail ?? ''})",
                  style: AppTypography.captionBold.copyWith(fontSize: 11),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                log.message,
                style: AppTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "Via: ${log.provider.toUpperCase()} • ${DateFormat('dd MMM, hh:mm a').format(log.createdAt)}",
                    style: AppTypography.caption.copyWith(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showFullMessageDialog(log),
        ),
      ),
    );
  }

  void _showFullMessageDialog(SmsLogModel log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        backgroundColor: AppColors.surfaceLight,
        title: Row(
          children: [
            const Icon(Icons.sms_rounded, color: AppColors.adminColor),
            AppSpacing.hGapSm,
            Expanded(child: Text(log.phoneNumber, style: AppTypography.subsectionHeading)),
            StatusBadge(status: log.status),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.userName != null) ...[
              Text("Recipient: ${log.userName}", style: AppTypography.captionBold),
              AppSpacing.vGapSm,
            ],
            Text("Message Content:", style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary)),
            AppSpacing.vGapXs,
            Container(
              padding: AppSpacing.paddingBase,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(log.message, style: AppTypography.bodySmall),
            ),
            if (log.error != null && log.error!.isNotEmpty) ...[
              AppSpacing.vGapMd,
              Text("Error Details:", style: AppTypography.captionBold.copyWith(color: AppColors.error)),
              Text(log.error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
            ],
            AppSpacing.vGapBase,
            Text(
              "Timestamp: ${DateFormat('dd MMMM yyyy, hh:mm:ss a').format(log.createdAt)}",
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(AdminViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: AppColors.surfaceLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onTap: _currentPage > 1 ? () => _loadData(page: _currentPage - 1) : null,
          ),
          AppSpacing.hGapBase,
          Text(
            "Page $_currentPage of ${vm.smsTotalPages > 0 ? vm.smsTotalPages : 1}",
            style: AppTypography.captionBold,
          ),
          AppSpacing.hGapBase,
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < vm.smsTotalPages ? () => _loadData(page: _currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : AppColors.backgroundLight,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.border : AppColors.textPrimary,
        ),
      ),
    );
  }
}
