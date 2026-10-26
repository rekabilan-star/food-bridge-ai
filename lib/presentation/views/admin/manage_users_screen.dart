import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/status_badge.dart';
import '../common/widgets/empty_state.dart';

class ManageUsersScreen extends StatefulWidget {
  final String? initialRole;

  const ManageUsersScreen({super.key, this.initialRole});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String? _selectedRole;
  String? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
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
    context.read<AdminViewModel>().fetchUsers(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final users = viewModel.users;
    final isLoading = viewModel.isLoading;
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "User & Account Management",
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
              child: isLoading && users.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : errorMessage != null && users.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyState(
                              icon: Icons.error_outline_rounded,
                              iconColor: AppColors.error,
                              title: "Unable to Load Accounts",
                              message: errorMessage,
                              actionText: "RETRY",
                              onActionPressed: () => _loadData(page: 1),
                            ),
                          ),
                        )
                      : users.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: const EmptyState(
                                  icon: Icons.person_search_rounded,
                                  title: "No User Accounts Found",
                                  message: "No user matching your current query or role filter exists.",
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: AppSpacing.pagePadding,
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return _buildUserCard(user);
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
              hintText: "Search name, email, or contact number...",
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
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  "All Roles",
                  ['donor', 'ngo', 'volunteer'],
                  _selectedRole,
                  (v) {
                    setState(() => _selectedRole = v);
                    _loadData(page: 1);
                  },
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: _buildFilterDropdown(
                  "All Status",
                  ['approved', 'pending', 'rejected'],
                  _selectedStatus,
                  (v) {
                    setState(() => _selectedStatus = v);
                    _loadData(page: 1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary)),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(value: null, child: Text(hint, style: AppTypography.captionBold)),
            ...items.map(
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  i.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(
                    color: i == value ? AppColors.adminColor : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final roleColor = _getRoleColor(user.role);
    final status = user.status ?? 'pending';

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
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Icon(_getRoleIcon(user.role), color: roleColor, size: 20),
          ),
          title: Text(
            user.name,
            style: AppTypography.subsectionHeading.copyWith(fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                user.email,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      user.role.name.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.borderActive),
          onTap: () => _showUserDetailSheet(user),
        ),
      ),
    );
  }

  void _showUserDetailSheet(UserModel user) {
    final roleColor = _getRoleColor(user.role);
    final status = user.status ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      backgroundColor: AppColors.surfaceLight,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Icon(_getRoleIcon(user.role), color: roleColor, size: 26),
                ),
                AppSpacing.hGapBase,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: AppTypography.sectionHeading),
                      Text(
                        user.role.name.toUpperCase(),
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            AppSpacing.vGapBase,
            const Divider(color: AppColors.border),
            AppSpacing.vGapSm,
            _buildDetailRow(Icons.email_outlined, user.email),
            _buildDetailRow(Icons.phone_outlined, user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided'),
            if (user.address != null && user.address!.isNotEmpty)
              _buildDetailRow(Icons.location_on_outlined, user.address!),
            if (user.ngoRegistrationNumber != null && user.ngoRegistrationNumber!.isNotEmpty)
              _buildDetailRow(Icons.badge_outlined, "Registration No: ${user.ngoRegistrationNumber}"),
            if (user.maxDailyMeals > 0)
              _buildDetailRow(Icons.restaurant_rounded, "Max Daily Meals: ${user.maxDailyMeals}"),
            AppSpacing.vGapBase,
            if (user.role == UserRole.ngo && status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleStatusUpdate(user, 'rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleStatusUpdate(user, 'approved');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
            ],
          ],
        ),
      ),
    );
  }

  void _handleStatusUpdate(UserModel user, String status) {
    final bool isApprove = status == 'approved';
    UIUtils.showConfirmationDialog(
      context: context,
      title: isApprove ? "Approve NGO Account?" : "Reject NGO Account?",
      message: isApprove
          ? "Confirm approving ${user.name}? This activates their donation distribution features."
          : "Are you sure you want to reject ${user.name}?",
      confirmText: isApprove ? "APPROVE" : "REJECT",
      confirmColor: isApprove ? AppColors.success : AppColors.error,
      onConfirm: () async {
        final success = await context.read<AdminViewModel>().updateNgoStatus(user.id, status);
        if (mounted) {
          if (success) {
            UIUtils.showSnackBar(context, "${user.name} status updated to ${status.toUpperCase()}");
            _loadData(page: _currentPage);
          } else {
            UIUtils.showErrorDialog(
              context,
              context.read<AdminViewModel>().errorMessage ?? "Failed to update status",
            );
          }
        }
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
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
            "Page $_currentPage of ${vm.userTotalPages > 0 ? vm.userTotalPages : 1}",
            style: AppTypography.captionBold,
          ),
          AppSpacing.hGapBase,
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < vm.userTotalPages ? () => _loadData(page: _currentPage + 1) : null,
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return AppColors.donorColor;
      case UserRole.ngo:
        return AppColors.ngoColor;
      case UserRole.volunteer:
        return AppColors.info;
      default:
        return AppColors.adminColor;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return Icons.volunteer_activism_rounded;
      case UserRole.ngo:
        return Icons.business_rounded;
      case UserRole.volunteer:
        return Icons.directions_bike_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
