import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/donation_model.dart';
import '../ngo/donation_details_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/status_badge.dart';
import '../common/widgets/empty_state.dart';

class DonationAuditScreen extends StatefulWidget {
  final String? initialStatus;

  const DonationAuditScreen({super.key, this.initialStatus});

  @override
  State<DonationAuditScreen> createState() => _DonationAuditScreenState();
}

class _DonationAuditScreenState extends State<DonationAuditScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String? _selectedStatus;
  String? _selectedCategory;
  bool _filterExpiredOnly = false;
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
    context.read<AdminViewModel>().fetchAllDonations(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      status: _filterExpiredOnly ? 'expired' : _selectedStatus,
      category: _selectedCategory,
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final allDonations = viewModel.donations;
    final donations = _filterExpiredOnly
        ? allDonations.where((d) => d.isExpired).toList()
        : allDonations;
    final isLoading = viewModel.isLoading;
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Donation Audit & Expiry Monitor",
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
            tooltip: "Refresh Audit",
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
              child: isLoading && donations.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : errorMessage != null && donations.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyState(
                              icon: Icons.error_outline_rounded,
                              iconColor: AppColors.error,
                              title: "Unable to Load Donations",
                              message: errorMessage,
                              actionText: "RETRY",
                              onActionPressed: () => _loadData(page: 1),
                            ),
                          ),
                        )
                      : donations.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: EmptyState(
                                  icon: Icons.inventory_2_outlined,
                                  title: _filterExpiredOnly ? "No Expired Donations" : "No Donations Found",
                                  message: _filterExpiredOnly
                                      ? "Great! All active donations are within their safe shelf-life."
                                      : "No rescue missions match the current status or search filter.",
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: AppSpacing.pagePadding,
                                    itemCount: donations.length,
                                    itemBuilder: (context, index) {
                                      final donation = donations[index];
                                      return _buildDonationCard(donation);
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
              hintText: "Search food name, donor, or location...",
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
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_off_rounded,
                        size: 14,
                        color: _filterExpiredOnly ? Colors.white : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Expired Only",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _filterExpiredOnly ? Colors.white : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  selected: _filterExpiredOnly,
                  selectedColor: AppColors.error,
                  backgroundColor: const Color(0xFFFEF2F2),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      _filterExpiredOnly = selected;
                    });
                    _loadData(page: 1);
                  },
                ),
                AppSpacing.hGapSm,
                _buildStatusChip("All", null),
                AppSpacing.hGapSm,
                _buildStatusChip("Waiting", 'waiting'),
                AppSpacing.hGapSm,
                _buildStatusChip("Accepted", 'accepted'),
                AppSpacing.hGapSm,
                _buildStatusChip("Picked Up", 'picked_up'),
                AppSpacing.hGapSm,
                _buildStatusChip("Completed", 'completed'),
                AppSpacing.hGapSm,
                _buildStatusChip("Cancelled", 'cancelled'),
              ],
            ),
          ),
          AppSpacing.vGapSm,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryChip("All Categories", null),
                AppSpacing.hGapSm,
                _buildCategoryChip("Cooked Food", 'Cooked Food'),
                AppSpacing.hGapSm,
                _buildCategoryChip("Raw Materials", 'Raw Materials'),
                AppSpacing.hGapSm,
                _buildCategoryChip("Bakery", 'Bakery'),
                AppSpacing.hGapSm,
                _buildCategoryChip("Fruits/Veggies", 'Fruits/Veggies'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final isSelected = !_filterExpiredOnly && _selectedStatus == value;
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
          setState(() {
            _selectedStatus = value;
            _filterExpiredOnly = false;
          });
          _loadData(page: 1);
        }
      },
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = value;
          });
          _loadData(page: 1);
        }
      },
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    final isExpired = donation.isExpired;
    final now = DateTime.now();
    final difference = donation.bestBeforeTime.difference(now);
    final isExpiringSoon = !isExpired && difference.inMinutes > 0 && difference.inHours < 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: isExpired
              ? const Color(0xFFFCA5A5)
              : (isExpiringSoon ? const Color(0xFFFDE68A) : AppColors.border),
          width: isExpired ? 1.5 : 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: AppSpacing.paddingBase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.borderMd,
                  child: donation.imageUrl.isNotEmpty
                      ? Image.network(
                          donation.imageUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
                AppSpacing.hGapBase,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.foodName,
                        style: AppTypography.subsectionHeading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${donation.category} • ${donation.membersServed} meals",
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: donation.status),
              ],
            ),
            AppSpacing.vGapMd,

            // Expiry Visibility Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xFFFEF2F2)
                    : (isExpiringSoon ? const Color(0xFFFFFBEB) : AppColors.backgroundLight),
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: isExpired
                      ? const Color(0xFFFCA5A5)
                      : (isExpiringSoon ? const Color(0xFFFDE68A) : AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired
                        ? Icons.timer_off_rounded
                        : (isExpiringSoon ? Icons.timer_outlined : Icons.schedule_rounded),
                    size: 14,
                    color: isExpired
                        ? AppColors.error
                        : (isExpiringSoon ? AppColors.warning : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isExpired
                          ? "EXPIRED: Passed shelf-life on ${DateFormat('dd MMM, hh:mm a').format(donation.bestBeforeTime)}"
                          : (isExpiringSoon
                              ? "EXPIRING SOON: ${difference.inMinutes} mins remaining (${DateFormat('hh:mm a').format(donation.bestBeforeTime)})"
                              : "Safe until: ${DateFormat('dd MMM, hh:mm a').format(donation.bestBeforeTime)}"),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? AppColors.error
                            : (isExpiringSoon ? AppColors.warning : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.vGapMd,
            _buildInfoRow(Icons.person_outline_rounded, "Donor", donation.donorName ?? 'Anonymous Donor'),
            _buildInfoRow(Icons.domain_rounded, "Assigned NGO", donation.assignedNgoName ?? 'Unassigned'),
            _buildInfoRow(Icons.place_outlined, "Pickup", donation.pickupAddress),
            AppSpacing.vGapBase,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAuditLogSheet(donation),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 42),
                    ),
                    child: Text(
                      "TIMELINE AUDIT",
                      style: AppTypography.captionBold.copyWith(color: AppColors.adminColor),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                    ),
                    child: Text(
                      "FULL DETAILS",
                      style: AppTypography.captionBold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: 54,
      height: 54,
      color: AppColors.backgroundLight,
      child: const Icon(Icons.restaurant_rounded, color: AppColors.textSecondary, size: 24),
    );
  }

  void _showAuditLogSheet(DonationModel donation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      backgroundColor: AppColors.surfaceLight,
      builder: (context) => Container(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.adminColor),
                AppSpacing.hGapSm,
                Text("Mission Audit Trail", style: AppTypography.sectionHeading),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              donation.foodName,
              style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vGapBase,
            if (donation.timeline.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text("No lifecycle steps recorded yet.", style: AppTypography.bodySmall),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: donation.timeline.length,
                  itemBuilder: (context, index) {
                    final log = donation.timeline[index];
                    final isLast = index == donation.timeline.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.adminColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 44,
                                color: AppColors.border,
                              ),
                          ],
                        ),
                        AppSpacing.hGapBase,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.status.toUpperCase().replaceAll('_', ' '),
                                style: AppTypography.captionBold,
                              ),
                              Text(
                                log.description,
                                style: AppTypography.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(log.time),
                                style: AppTypography.caption.copyWith(fontSize: 10, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          AppSpacing.hGapSm,
          Text("$label: ", style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            "Page $_currentPage of ${vm.donationTotalPages > 0 ? vm.donationTotalPages : 1}",
            style: AppTypography.captionBold,
          ),
          AppSpacing.hGapBase,
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < vm.donationTotalPages ? () => _loadData(page: _currentPage + 1) : null,
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
