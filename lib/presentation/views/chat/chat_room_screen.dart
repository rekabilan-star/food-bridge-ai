import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatRoomScreen({super.key, required this.chat});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthViewModel>().user!.id;
      final chatVm = context.read<ChatViewModel>();
      chatVm.initSocketListeners(currentUserId);
      chatVm.fetchMessages(widget.chat.id);
    });
  }

  @override
  void dispose() {
    context.read<ChatViewModel>().clearActiveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUserId = context.read<AuthViewModel>().user!.id;
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
            _scrollController.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
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
      final currentUserId = context.read<AuthViewModel>().user!.id;
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
    final currentUserId = context.read<AuthViewModel>().user!.id;
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
    final currentUserId = context.watch<AuthViewModel>().user!.id;
    final otherUser = widget.chat.getOtherParticipant(currentUserId);
    final vm = context.watch<ChatViewModel>();
    final isOnline = vm.getUserStatus(otherUser.id) == 'online';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: _buildAppBar(otherUser, isOnline, vm),
      body: Column(
        children: [
          Expanded(
            child: vm.isMessagesLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(vm.messages, currentUserId),
          ),
          _buildInputArea(otherUser.id),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic otherUser, bool isOnline, ChatViewModel vm) {
    return AppBar(
      backgroundColor: Colors.white,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: (otherUser.profileImage == null || otherUser.profileImage!.isEmpty)
                    ? Text(otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherUser.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                Text(
                  vm.isUserTyping(widget.chat.id) ? 'typing...' : (isOnline ? 'Online' : 'Offline'),
                  style: TextStyle(fontSize: 11, color: vm.isUserTyping(widget.chat.id) ? AppColors.primary : Colors.grey[500], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Direct audio calling feature initialising...')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Direct video calling feature initialising...')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, String currentUserId) {
    if (messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey[300])),
              const SizedBox(height: 16),
              const Text("Securely connected", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
    }
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        
        bool showDate = false;
        if (index == messages.length - 1) {
            showDate = true;
        } else {
            final nextMessage = messages[index + 1];
            if (message.createdAt.day != nextMessage.createdAt.day) {
                showDate = true;
            }
        }

        return Column(
          children: [
            if (showDate) _buildDateHeader(message.createdAt),
            _MessageBubble(message: message, isMe: isMe)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String text = DateFormat('MMMM dd').format(date);
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) text = "Today";
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 1)),
    );
  }

  Widget _buildInputArea(String receiverId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            onPressed: _showAttachOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF1F2F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Wrap(
          spacing: 32, runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            _AttachItem(icon: Icons.image_rounded, label: 'Photos', color: Colors.blue, onTap: _handleAttachPhotos),
            _AttachItem(icon: Icons.camera_alt_rounded, label: 'Camera', color: Colors.orange, onTap: _handleAttachCamera),
            _AttachItem(icon: Icons.location_on_rounded, label: 'Location', color: Colors.green, onTap: _handleAttachLocation),
            _AttachItem(icon: Icons.description_rounded, label: 'File', color: Colors.purple, onTap: _handleAttachFile),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
          border: isMe ? null : Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.fileUrl != null && message.fileUrl!.isNotEmpty && message.messageType == MessageType.image)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.fileUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            Text(
              message.text ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(color: isMe ? Colors.white60 : Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.seen ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.status == MessageStatus.seen ? Colors.white : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }
}
