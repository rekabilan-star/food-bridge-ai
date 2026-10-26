import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/ui_utils.dart';

import '../common/widgets/empty_state.dart';
import '../common/widgets/shimmer_loading.dart';
import '../ngo/donation_details_screen.dart';
import '../ngo/ngo_tracking_screen.dart';
import '../ngo/ngo_donation_requests_screen.dart';
import '../common/donation_tracking_screen.dart';
import '../donor/donor_dashboard_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().fetchNotifications(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<NotificationViewModel>().fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) async {
    final authVM = context.read<AuthViewModel>();
    final donationVM = context.read<DonationViewModel>();
    final userRole = authVM.user?.role;

    // Fast-path feedback for already claimed donations
    if (notification.title.contains('Claimed') || notification.body.contains('already been accepted')) {
      if (context.mounted) {
        UIUtils.showSnackBar(
          context,
          "This donation has already been accepted by another NGO and is no longer available.",
          isError: false,
        );
      }
      return;
    }

    final String? donationId = notification.data['donationId']?.toString() ?? notification.data['id']?.toString();

    if (donationId != null && donationId.isNotEmpty) {
      await donationVM.fetchDonationDetails(donationId);
      final donation = donationVM.currentDonation;
      if (context.mounted) {
        if (donation != null) {
          if (userRole == UserRole.ngo) {
            if (donation.status == 'accepted' ||
                donation.status == 'on_the_way' ||
                donation.status == 'arrived' ||
                donation.status == 'picked_up') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)),
            );
          }
          return;
        } else if (donationVM.errorMessage != null && donationVM.errorMessage!.isNotEmpty) {
          UIUtils.showSnackBar(context, donationVM.errorMessage!, isError: true);
          return;
        }
      }
    }

    // Category fallback navigation
    if (notification.category == 'DONATION' || notification.category == 'EMERGENCY') {
      if (context.mounted) {
        if (userRole == UserRole.ngo) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()),
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DonorDashboardScreen(initialIndex: 1)),
            (route) => false,
          );
        }
      }
    } else if (notification.category == 'CHAT') {
      if (context.mounted) {
        Navigator.pushNamed(context, '/chats');
      }
    } else {
      if (context.mounted) {
        if (userRole == UserRole.ngo) {
          Navigator.pushNamedAndRemoveUntil(context, '/ngo-dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/donor-dashboard', (route) => false);
        }
      }
    }
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        backgroundColor: AppColors.surfaceLight,
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            AppSpacing.hGapSm,
            Text("Clear All Notifications?", style: AppTypography.subsectionHeading),
          ],
        ),
        content: Text(
          "This will permanently delete all your notifications and rescue alerts. This action cannot be undone.",
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationViewModel>().deleteAll();
              UIUtils.showSnackBar(context, "All notifications cleared");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            child: const Text("CLEAR ALL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier this Week': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final aWeekAgo = today.subtract(const Duration(days: 7));

    for (final item in list) {
      if (_unreadOnly && item.isRead) continue;

      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      if (itemDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(item);
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(item);
      } else if (itemDate.isAfter(aWeekAgo)) {
        groups['Earlier this Week']!.add(item);
      } else {
        groups['Older']!.add(item);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final grouped = _groupNotifications(vm.notifications);
    final unreadCount = vm.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Notifications", style: AppTypography.pageTitle.copyWith(fontSize: 18)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.borderFull,
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
            tooltip: "Mark all as read",
            onPressed: () {
              vm.markAllAsRead();
              UIUtils.showSnackBar(context, "All notifications marked as read");
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textSecondary, size: 22),
            tooltip: "Clear all",
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => vm.fetchNotifications(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _buildSearchAndFilters(),
            ),
            if (vm.isLoading && vm.notifications.isEmpty)
              const SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: ShimmerListLoading(count: 6),
                ),
              )
            else if (vm.errorMessage != null && vm.notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.error,
                    title: "Unable to Load Alerts",
                    message: vm.errorMessage!,
                    actionText: "RETRY",
                    onActionPressed: () => vm.fetchNotifications(refresh: true),
                  ),
                ),
              )
            else if (grouped.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: _unreadOnly ? "No Unread Notifications" : "All Caught Up!",
                    message: _unreadOnly
                        ? "You've read all rescue updates and notifications."
                        : "New donation broadcasts and coordination alerts will arrive here.",
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Flatten the groups for the list delegate
                      int count = 0;
                      for (final entry in grouped.entries) {
                        // Header item
                        if (index == count) {
                          return _buildGroupHeader(entry.key);
                        }
                        count++;

                        // Child items
                        if (index < count + entry.value.length) {
                          final itemIndex = index - count;
                          final notification = entry.value[itemIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NotificationCard(
                              notification: notification,
                              onTap: () {
                                vm.markAsRead(notification.id);
                                _handleNotificationTap(context, notification);
                              },
                              onDelete: () => vm.deleteNotification(notification.id),
                            ),
                          );
                        }
                        count += entry.value.length;
                      }

                      // Bottom loader when fetching next page
                      if (vm.hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: _calculateTotalItems(grouped) + (vm.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalItems(Map<String, List<NotificationModel>> grouped) {
    int total = grouped.keys.length; // Headers
    for (final list in grouped.values) {
      total += list.length;
    }
    return total;
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.captionBold.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
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
            decoration: InputDecoration(
              hintText: 'Search updates and alerts...',
              hintStyle: AppTypography.fieldHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<NotificationViewModel>().setSearchQuery(null);
                        setState(() {});
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
              context.read<NotificationViewModel>().setSearchQuery(value.isEmpty ? null : value);
            },
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
                        _unreadOnly ? Icons.mark_email_unread_rounded : Icons.mark_email_read_rounded,
                        size: 14,
                        color: _unreadOnly ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Unread Only",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _unreadOnly ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  selected: _unreadOnly,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: _unreadOnly ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() => _unreadOnly = selected);
                  },
                ),
                AppSpacing.hGapSm,
                const _CategoryFilterChip(label: 'All', category: null),
                AppSpacing.hGapSm,
                const _CategoryFilterChip(label: 'Donations', category: 'DONATION'),
                AppSpacing.hGapSm,
                const _CategoryFilterChip(label: 'Chats', category: 'CHAT'),
                AppSpacing.hGapSm,
                const _CategoryFilterChip(label: 'Urgent', category: 'EMERGENCY'),
                AppSpacing.hGapSm,
                const _CategoryFilterChip(label: 'System', category: 'SYSTEM'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final String? category;

  const _CategoryFilterChip({required this.label, this.category});

  @override
  Widget build(BuildContext context) {
    final selectedCategory = context.watch<NotificationViewModel>().selectedCategory;
    final isSelected = selectedCategory == category;

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
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          context.read<NotificationViewModel>().setCategoryFilter(category);
        }
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isClaimed = notification.title.contains('Claimed') ||
        notification.body.contains('already been accepted');
    final isExpired = notification.isExpired;

    final categoryColor = _getCategoryColor(notification.category);
    final categoryIcon = _getCategoryIcon(notification.category);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.borderXl,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: !notification.isRead
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
            width: !notification.isRead ? 1.5 : 1.0,
          ),
          boxShadow: notification.isRead ? AppShadows.subtle : AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderXl,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: categoryColor.withValues(alpha: 0.12),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTypography.subsectionHeading.copyWith(
                                  fontSize: 14,
                                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeago.format(notification.createdAt, locale: 'en_short'),
                              style: AppTypography.caption.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: AppTypography.bodySmall.copyWith(
                            color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isClaimed) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.handshake_outlined, size: 12, color: AppColors.warning),
                                SizedBox(width: 4),
                                Text(
                                  'CLAIMED BY ANOTHER NGO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isExpired) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_off_outlined, size: 12, color: AppColors.error),
                                SizedBox(width: 4),
                                Text(
                                  'EXPIRED / UNAVAILABLE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'DONATION':
        return AppColors.primary;
      case 'CHAT':
        return AppColors.info;
      case 'EMERGENCY':
        return AppColors.error;
      case 'SYSTEM':
        return AppColors.adminColor;
      default:
        return AppColors.accent;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'DONATION':
        return Icons.volunteer_activism_rounded;
      case 'CHAT':
        return Icons.chat_bubble_rounded;
      case 'PROFILE':
        return Icons.person_rounded;
      case 'EMERGENCY':
        return Icons.flash_on_rounded;
      case 'SYSTEM':
        return Icons.shield_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
