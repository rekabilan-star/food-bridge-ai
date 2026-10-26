import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

import '../common/widgets/status_badge.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatRoomScreen({super.key, required this.chat});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatViewModel? _chatVM;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatVM = context.read<ChatViewModel>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthViewModel>().user?.id ?? '';
      final chatVM = context.read<ChatViewModel>();
      chatVM.initSocketListeners(currentUserId);
      chatVM.fetchMessages(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _chatVM?.clearActiveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<AuthViewModel>().user?.id ?? '';
    final otherUser = widget.chat.getOtherParticipant(currentUserId);

    context.read<ChatViewModel>().sendMessage(
      chatId: widget.chat.id,
      receiverId: otherUser.id,
      text: text,
    );

    _messageController.clear();
    context.read<ChatViewModel>().setTyping(widget.chat.id, otherUser.id, false);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleAttachPhotos() async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        _sendMediaMessage(File(picked.path), MessageType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  Future<void> _handleAttachCamera() async {
    Navigator.pop(context);
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to capture photos')),
          );
        }
        return;
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        _sendMediaMessage(File(picked.path), MessageType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _handleAttachLocation() async {
    Navigator.pop(context);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to share current location')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final currentUserId = context.read<AuthViewModel>().user?.id ?? '';
      final otherUser = widget.chat.getOtherParticipant(currentUserId);
      final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      context.read<ChatViewModel>().sendMessage(
        chatId: widget.chat.id,
        receiverId: otherUser.id,
        text: '📍 Shared Location: $locationUrl',
        type: MessageType.location,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to obtain location: $e')),
        );
      }
    }
  }

  Future<void> _handleAttachFile() async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMedia();
      if (picked != null) {
        _sendMediaMessage(File(picked.path), MessageType.pdf);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  Future<void> _sendMediaMessage(File file, MessageType type) async {
    final currentUserId = context.read<AuthViewModel>().user?.id ?? '';
    final otherUser = widget.chat.getOtherParticipant(currentUserId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading attachment...'), duration: Duration(seconds: 2)),
      );
    }

    try {
      final repo = DonationRepository();
      final uploadedUrl = await repo.uploadImage(file);

      if (!mounted) return;
      context.read<ChatViewModel>().sendMessage(
        chatId: widget.chat.id,
        receiverId: otherUser.id,
        text: type == MessageType.image ? 'Shared an image' : 'Shared an attachment',
        type: type,
        fileUrl: uploadedUrl,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().user?.id ?? '';
    final otherUser = widget.chat.getOtherParticipant(currentUserId);
    final vm = context.watch<ChatViewModel>();
    final isOnline = vm.getUserStatus(otherUser.id) == 'online';
    final isTyping = vm.isUserTyping(widget.chat.id);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, otherUser, isOnline, isTyping),
      body: Column(
        children: [
          if (widget.chat.donation != null) _buildMissionContextBanner(),
          Expanded(
            child: vm.isMessagesLoading && vm.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildMessageList(vm.messages, currentUserId),
          ),
          _buildInputArea(otherUser.id),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserModel otherUser,
    bool isOnline,
    bool isTyping,
  ) {
    final roleColor = otherUser.role == UserRole.ngo
        ? AppColors.primary
        : (otherUser.role == UserRole.admin ? AppColors.adminColor : AppColors.accent);

    return AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      titleSpacing: 0,
      foregroundColor: AppColors.textPrimary,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.border, height: 1.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.12),
                child: (otherUser.profileImage == null || otherUser.profileImage!.isEmpty)
                    ? Text(
                        otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        otherUser.name,
                        style: AppTypography.subsectionHeading.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        otherUser.role.name.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isTyping
                      ? 'typing...'
                      : (isOnline ? 'Online now' : 'Offline'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isTyping ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isTyping ? FontWeight.bold : FontWeight.w500,
                    fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          onPressed: () {
            _showChatInfoDialog(otherUser);
          },
          tooltip: "Chat Info",
        ),
      ],
    );
  }

  Widget _buildMissionContextBanner() {
    final donation = widget.chat.donation!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 16),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.foodName,
                  style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${donation.category} • ${donation.membersServed} meals",
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          StatusBadge(status: donation.status),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, String currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.primary),
            ),
            AppSpacing.vGapBase,
            Text("Rescue Coordination Channel", style: AppTypography.subsectionHeading),
            AppSpacing.vGapXs,
            Text(
              "Send a message to coordinate pickup and handover details.",
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;

        bool showDate = false;
        if (index == messages.length - 1) {
          showDate = true;
        } else {
          final nextMessage = messages[index + 1];
          if (message.createdAt.day != nextMessage.createdAt.day ||
              message.createdAt.month != nextMessage.createdAt.month) {
            showDate = true;
          }
        }

        return Column(
          children: [
            if (showDate) _buildDateHeader(message.createdAt),
            _buildMessageBubble(message: message, isMe: isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String text = DateFormat('MMMM dd').format(date);
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      text = "Today";
    } else if (date.day == now.subtract(const Duration(days: 1)).day &&
        date.month == now.month &&
        date.year == now.year) {
      text = "Yesterday";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.captionBold.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMessageBubble({required MessageModel message, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 16),
          ),
          boxShadow: isMe ? AppShadows.subtle : AppShadows.subtle,
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.fileUrl != null &&
                message.fileUrl!.isNotEmpty &&
                message.messageType == MessageType.image) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: AppRadius.borderMd,
                  child: Image.network(
                    message.fileUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: AppColors.backgroundLight,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (message.messageType == MessageType.location) ...[
              InkWell(
                onTap: () async {
                  final text = message.text ?? '';
                  final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(text);
                  if (urlMatch != null) {
                    final uri = Uri.parse(urlMatch.group(0)!);
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: isMe ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Open Shared Location",
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (message.text != null && message.text!.isNotEmpty) ...[
              Text(
                message.text!,
                style: AppTypography.bodySmall.copyWith(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.seen
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 13,
                    color: message.status == MessageStatus.seen
                        ? const Color(0xFF67E8F9)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(String receiverId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppShadows.subtle,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
              onPressed: _showAttachOptions,
              tooltip: "Attach media or location",
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTypography.fieldHint,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderFull,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderFull,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderFull,
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onChanged: (val) {
                  context.read<ChatViewModel>().setTyping(widget.chat.id, receiverId, val.isNotEmpty);
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      backgroundColor: AppColors.surfaceLight,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Share with Partner", style: AppTypography.subsectionHeading),
            AppSpacing.vGapLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachOptionItem(
                  icon: Icons.image_rounded,
                  label: 'Photos',
                  color: const Color(0xFF0284C7),
                  onTap: _handleAttachPhotos,
                ),
                _AttachOptionItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFFD97706),
                  onTap: _handleAttachCamera,
                ),
                _AttachOptionItem(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: AppColors.primary,
                  onTap: _handleAttachLocation,
                ),
                _AttachOptionItem(
                  icon: Icons.description_rounded,
                  label: 'Document',
                  color: AppColors.adminColor,
                  onTap: _handleAttachFile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfoDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        backgroundColor: AppColors.surfaceLight,
        title: Row(
          children: [
            const Icon(Icons.info_rounded, color: AppColors.primary),
            AppSpacing.hGapSm,
            Text("Rescue Participant", style: AppTypography.subsectionHeading),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: AppTypography.subsectionHeading.copyWith(fontSize: 16)),
            Text(user.role.name.toUpperCase(), style: AppTypography.captionBold.copyWith(color: AppColors.primary)),
            AppSpacing.vGapMd,
            if (user.phoneNumber.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: AppColors.textSecondary),
                  AppSpacing.hGapSm,
                  Text(user.phoneNumber, style: AppTypography.bodySmall),
                ],
              ),
            if (user.email.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                  AppSpacing.hGapSm,
                  Expanded(child: Text(user.email, style: AppTypography.bodySmall)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _AttachOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.captionBold.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
