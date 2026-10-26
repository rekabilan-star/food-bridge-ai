import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/status_badge.dart';
import '../common/widgets/empty_state.dart';

class ManageNgosScreen extends StatefulWidget {
  final String? initialStatus;

  const ManageNgosScreen({super.key, this.initialStatus = 'pending'});

  @override
  State<ManageNgosScreen> createState() => _ManageNgosScreenState();
}

class _ManageNgosScreenState extends State<ManageNgosScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData({int page = 1}) {
    _currentPage = page;
    context.read<AdminViewModel>().fetchNgos(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final ngos = viewModel.ngos;
    final isLoading = viewModel.isLoading;
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "NGO Partner Governance",
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
            tooltip: "Refresh List",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(page: _currentPage),
        color: AppColors.adminColor,
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: isLoading && ngos.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : errorMessage != null && ngos.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyState(
                              icon: Icons.error_outline_rounded,
                              iconColor: AppColors.error,
                              title: "Unable to Load NGOs",
                              message: errorMessage,
                              actionText: "RETRY",
                              onActionPressed: () => _loadData(page: 1),
                            ),
                          ),
                        )
                      : ngos.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: EmptyState(
                                  icon: Icons.verified_user_rounded,
                                  title: _selectedStatus == 'pending'
                                      ? "No Pending Applications"
                                      : "No Matching NGOs Found",
                                  message: _selectedStatus == 'pending'
                                      ? "All registered NGOs have been evaluated and processed."
                                      : "Try adjusting your search criteria or status filter.",
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: AppSpacing.pagePadding,
                                    itemCount: ngos.length,
                                    itemBuilder: (context, index) {
                                      final ngo = ngos[index];
                                      return _buildNgoCard(ngo);
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

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadData(page: 1),
            decoration: InputDecoration(
              hintText: "Search NGO name, email, or reg number...",
              hintStyle: AppTypography.fieldHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
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
                _buildStatusChip("Pending Approvals", 'pending', AppColors.warning),
                AppSpacing.hGapSm,
                _buildStatusChip("Approved NGOs", 'approved', AppColors.success),
                AppSpacing.hGapSm,
                _buildStatusChip("Rejected", 'rejected', AppColors.error),
                AppSpacing.hGapSm,
                _buildStatusChip("All Organizations", 'all', AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
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
      selectedColor: color,
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(color: isSelected ? color : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
          _loadData(page: 1);
        }
      },
    );
  }

  Widget _buildNgoCard(UserModel ngo) {
    final isLoading = context.watch<AdminViewModel>().isLoading;
    final status = ngo.status ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: AppSpacing.paddingBase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.ngoColor.withValues(alpha: 0.12),
                  child: Text(
                    ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
                    style: const TextStyle(
                      color: AppColors.ngoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                AppSpacing.hGapBase,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo.name,
                        style: AppTypography.subsectionHeading,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Registration: ${ngo.ngoRegistrationNumber ?? 'N/A'}",
                        style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            AppSpacing.vGapMd,
            const Divider(height: 1, color: AppColors.border),
            AppSpacing.vGapMd,
            _buildDetailRow(Icons.email_outlined, ngo.email),
            _buildDetailRow(Icons.phone_outlined, ngo.phoneNumber.isNotEmpty ? ngo.phoneNumber : 'Not provided'),
            _buildDetailRow(Icons.location_on_outlined, ngo.address ?? 'No physical address specified'),
            if (ngo.maxDailyMeals > 0)
              _buildDetailRow(Icons.restaurant_rounded, "Max Daily Meal Capacity: ${ngo.maxDailyMeals}"),
            AppSpacing.vGapMd,
            _buildCertificateSection(ngo),
            AppSpacing.vGapBase,
            Row(
              children: [
                if (status != 'rejected')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () => _handleStatusUpdate(ngo, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                if (status != 'rejected' && status != 'approved') AppSpacing.hGapMd,
                if (status != 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _handleStatusUpdate(ngo, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCertificateUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final rootServer = AppConstants.serverBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$rootServer$cleanPath';
  }

  Widget _buildCertificateSection(UserModel ngo) {
    final String? certPath = (ngo.ngoCertificateUrl != null && ngo.ngoCertificateUrl!.isNotEmpty)
        ? ngo.ngoCertificateUrl
        : ngo.ngoIdProofUrl;

    final fullUrl = _resolveCertificateUrl(certPath);
    final bool isLocalFile = certPath != null && certPath.isNotEmpty && File(certPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              "Government Verification Document",
              style: AppTypography.captionBold,
            ),
          ],
        ),
        AppSpacing.vGapSm,
        if (fullUrl.isNotEmpty || isLocalFile)
          GestureDetector(
            onTap: () => _showFullCertificateDialog(context, ngo.name, fullUrl, isLocalFile ? certPath : null),
            child: ClipRRect(
              borderRadius: AppRadius.borderLg,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLocalFile)
                      Image.file(File(certPath), fit: BoxFit.cover, width: double.infinity, height: 160)
                    else
                      Image.network(
                        fullUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildUnavailableCertificateCard();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
                        },
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "Tap to zoom document",
                              style: AppTypography.captionBold.copyWith(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _buildUnavailableCertificateCard(),
      ],
    );
  }

  Widget _buildUnavailableCertificateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              "No digital registration document attached",
              style: AppTypography.captionBold.copyWith(color: const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullCertificateDialog(BuildContext context, String ngoName, String url, String? localPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        backgroundColor: AppColors.surfaceLight,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text("$ngoName Certificate", style: AppTypography.subsectionHeading),
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.textPrimary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: localPath != null
                      ? Image.file(File(localPath), fit: BoxFit.contain)
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text("Unable to preview certificate image"),
                            );
                          },
                        ),
                ),
              ),
              AppSpacing.vGapSm,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
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
            "Page $_currentPage of ${vm.ngoTotalPages > 0 ? vm.ngoTotalPages : 1}",
            style: AppTypography.captionBold,
          ),
          AppSpacing.hGapBase,
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < vm.ngoTotalPages ? () => _loadData(page: _currentPage + 1) : null,
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

  void _handleStatusUpdate(UserModel ngo, String status) {
    final bool isApprove = status == 'approved';
    UIUtils.showConfirmationDialog(
      context: context,
      title: isApprove ? "Approve NGO Partner?" : "Reject Application?",
      message: isApprove
          ? "Are you sure you want to approve ${ngo.name}? They will be verified to accept and distribute surplus donations."
          : "Are you sure you want to reject ${ngo.name}'s registration?",
      confirmText: isApprove ? "APPROVE" : "REJECT",
      confirmColor: isApprove ? AppColors.success : AppColors.error,
      onConfirm: () async {
        final success = await context.read<AdminViewModel>().updateNgoStatus(ngo.id, status);
        if (!mounted) return;
        if (success) {
          UIUtils.showSnackBar(context, "${ngo.name} successfully ${status.toUpperCase()}");
          _loadData(page: _currentPage);
        } else {
          UIUtils.showErrorDialog(
            context,
            context.read<AdminViewModel>().errorMessage ?? "Verification action failed",
          );
        }
      },
    );
  }
}
