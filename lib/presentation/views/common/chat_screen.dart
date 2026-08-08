import 'package:flutter/material.dart';
import '../../../data/repositories/chat_repository.dart';
import '../chat/chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String donationId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.donationId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    try {
      final chat = await ChatRepository().getOrCreateChat(
        widget.receiverId,
        donationId: widget.donationId
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatRoomScreen(chat: chat)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening chat: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
