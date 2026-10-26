import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/empty_state.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthViewModel>().user?.id ?? '';
      final chatVM = context.read<ChatViewModel>();
      chatVM.fetchChats();
      chatVM.initSocketListeners(currentUserId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatModel> _filterChats(List<ChatModel> chats, String currentUserId) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return chats;

    return chats.where((chat) {
      final other = chat.getOtherParticipant(currentUserId);
      final nameMatches = other.name.toLowerCase().contains(query);
      final donationMatches = chat.donation?.foodName.toLowerCase().contains(query) ?? false;
      final msgMatches = chat.lastMessage?.text?.toLowerCase().contains(query) ?? false;
      return nameMatches || donationMatches || msgMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().user?.id ?? '';
    final chatVM = context.watch<ChatViewModel>();
    final filteredChats = _filterChats(chatVM.chats, currentUserId);

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
        title: Text(
          'Rescue Comms & Messages',
          style: AppTypography.pageTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => chatVM.fetchChats(),
            tooltip: "Refresh chats",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: chatVM.fetchChats,
              color: AppColors.primary,
              child: chatVM.isLoading && chatVM.chats.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : chatVM.errorMessage != null && chatVM.chats.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyState(
                              icon: Icons.cloud_off_rounded,
                              iconColor: AppColors.error,
                              title: "Unable to Load Messages",
                              message: chatVM.errorMessage!,
                              actionText: "RETRY",
                              onActionPressed: chatVM.fetchChats,
                            ),
                          ),
                        )
                      : filteredChats.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: EmptyState(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  title: _searchController.text.isNotEmpty ? "No Matching Conversations" : "No Messages Yet",
                                  message: _searchController.text.isNotEmpty
                                      ? "No chats found matching '${_searchController.text}'."
                                      : "Coordination chats with donors, NGOs, and volunteers appear here.",
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                final otherUser = chat.getOtherParticipant(currentUserId);
                                final lastMsg = chat.lastMessage;
                                final unreadCount = chat.unreadCounts[currentUserId] ?? 0;
                                final isOnline = chatVM.getUserStatus(otherUser.id) == 'online';
                                final isTyping = chatVM.isUserTyping(chat.id);

                                return _buildChatTile(
                                  context: context,
                                  chat: chat,
                                  otherUser: otherUser,
                                  lastMsg: lastMsg,
                                  unreadCount: unreadCount,
                                  isOnline: isOnline,
                                  isTyping: isTyping,
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search chats by person or food item...',
          hintStyle: AppTypography.fieldHint,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
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
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required ChatModel chat,
    required UserModel otherUser,
    required dynamic lastMsg,
    required int unreadCount,
    required bool isOnline,
    required bool isTyping,
  }) {
    final roleColor = otherUser.role == UserRole.ngo
        ? AppColors.primary
        : (otherUser.role == UserRole.admin ? AppColors.adminColor : AppColors.accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
          width: unreadCount > 0 ? 1.5 : 1.0,
        ),
        boxShadow: unreadCount > 0 ? AppShadows.card : AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatRoomScreen(chat: chat)),
            );
          },
          borderRadius: AppRadius.borderXl,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: roleColor.withValues(alpha: 0.12),
                      child: (otherUser.profileImage == null || otherUser.profileImage!.isEmpty)
                          ? Text(
                              otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: roleColor,
                              ),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.hGapBase,
                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser.name,
                              style: AppTypography.subsectionHeading.copyWith(
                                fontSize: 15,
                                fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              otherUser.role.name.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (lastMsg != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeago.format(lastMsg.createdAt, locale: 'en_short'),
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Associated donation reference pill
                      if (chat.donation != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.restaurant_rounded, size: 11, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Rescue: ${chat.donation!.foodName}",
                                style: AppTypography.captionBold.copyWith(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isTyping
                                  ? 'typing...'
                                  : (lastMsg?.text ?? (lastMsg?.fileUrl != null ? 'Shared an attachment' : 'Started a conversation')),
                              style: TextStyle(
                                color: isTyping
                                    ? AppColors.primary
                                    : (unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary),
                                fontSize: 13,
                                fontWeight: unreadCount > 0 || isTyping ? FontWeight.bold : FontWeight.normal,
                                fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.borderFull,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
