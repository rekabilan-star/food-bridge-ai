import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import 'chat_room_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthViewModel>().user!.id;
      context.read<ChatViewModel>().fetchChats();
      context.read<ChatViewModel>().initSocketListeners(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().user!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat search feature active. Filter chats by recipient name.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Additional chat settings and filtering options.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.chats.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.fetchChats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.fetchChats,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: vm.chats.length,
              itemBuilder: (context, index) {
                final chat = vm.chats[index];
                final otherUser = chat.getOtherParticipant(currentUserId);
                final lastMsg = chat.lastMessage;
                final unreadCount = chat.unreadCounts[currentUserId] ?? 0;
                final isOnline = vm.getUserStatus(otherUser.id) == 'online';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatRoomScreen(chat: chat)),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.03) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isOnline ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: (otherUser.profileImage == null || otherUser.profileImage!.isEmpty)
                                      ? Text(
                                          otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        )
                                      : null,
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2)),
                                    if (lastMsg != null)
                                      Text(
                                        timeago.format(lastMsg.createdAt, locale: 'en_short'),
                                        style: TextStyle(fontSize: 11, color: unreadCount > 0 ? AppColors.primary : Colors.grey[500], fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vm.isUserTyping(chat.id) ? 'typing...' : (lastMsg?.text ?? 'Started a conversation'),
                                        style: TextStyle(color: vm.isUserTyping(chat.id) ? AppColors.primary : Colors.grey[600], fontSize: 13, fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                        child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          const Text('No messages yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Connect with rescue partners to start chatting.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
