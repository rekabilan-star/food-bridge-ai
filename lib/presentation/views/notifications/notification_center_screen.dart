import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donation_viewmodel.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../common/widgets/custom_app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<NotificationViewModel>(context, listen: false);
      vm.fetchNotifications(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Provider.of<NotificationViewModel>(context, listen: false).fetchNotifications();
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
    final String? donationId = notification.data['donationId']?.toString() ?? notification.data['id']?.toString();

    if (donationId != null && donationId.isNotEmpty) {
      await donationVM.fetchDonationDetails(donationId);
      final donation = donationVM.currentDonation;
      if (context.mounted && donation != null) {
        if (userRole == UserRole.ngo) {
          if (donation.status == 'accepted' || donation.status == 'on_the_way' || donation.status == 'arrived' || donation.status == 'picked_up') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NgoTrackingScreen(donationId: donation.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DonationDetailsScreen(donation: donation)));
          }
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DonationTrackingScreen(donationId: donation.id)));
        }
        return;
      }
    }

    // Category fallback navigation
    if (notification.category == 'DONATION' || notification.category == 'EMERGENCY') {
      if (context.mounted) {
        if (userRole == UserRole.ngo) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NgoDonationRequestsScreen()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: "Notifications",
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
            tooltip: "Mark all as read",
            onPressed: () {
              final vm = Provider.of<NotificationViewModel>(context, listen: false);
              vm.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All notifications marked as read")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textSecondary, size: 22),
            tooltip: "Clear all",
            onPressed: () {
              final vm = Provider.of<NotificationViewModel>(context, listen: false);
              vm.deleteAll();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<NotificationViewModel>(context, listen: false).fetchNotifications(refresh: true);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [

          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),

          Consumer<NotificationViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading && vm.notifications.isEmpty) {
                return const SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: ShimmerListLoading(count: 6),
                  ),
                );
              }

              if (vm.notifications.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == vm.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }

                      final notification = vm.notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () {
                            vm.markAsRead(notification.id);
                            _handleNotificationTap(context, notification);
                          },
                          onDelete: () => vm.deleteNotification(notification.id),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                      );
                    },
                    childCount: vm.notifications.length + (vm.hasMore ? 1 : 0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              ),
              onChanged: (value) {
                setState(() {});
                context.read<NotificationViewModel>().setSearchQuery(value.isEmpty ? null : value);
              },
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: const [
                _FilterChip(label: 'All', category: null),
                _FilterChip(label: 'Donations', category: 'DONATION'),
                _FilterChip(label: 'Chats', category: 'CHAT'),
                _FilterChip(label: 'Urgent', category: 'EMERGENCY'),
                _FilterChip(label: 'System', category: 'SYSTEM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined, size: 54, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have no new notifications.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? category;

  const _FilterChip({required this.label, this.category});

  @override
  Widget build(BuildContext context) {
    final selectedCategory = context.watch<NotificationViewModel>().selectedCategory;
    final isSelected = selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => context.read<NotificationViewModel>().setCategoryFilter(category),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
      ),
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
    final color = AppColors.primary;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getCategoryIcon(notification.category), color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              timeago.format(notification.createdAt, locale: 'en_short'),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8, top: 6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'DONATION': return Icons.volunteer_activism_rounded;
      case 'CHAT': return Icons.chat_bubble_rounded;
      case 'PROFILE': return Icons.person_rounded;
      case 'EMERGENCY': return Icons.flash_on_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }
}
