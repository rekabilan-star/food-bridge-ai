import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../core/services/socket_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();
  final SocketService _socketService = SocketService();
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _socketService.socket.off('new_message');
    _socketService.socket.off('message_status_update');
    _socketService.socket.off('typing_status');
    _socketService.socket.off('user_online');
    _socketService.socket.off('user_offline');
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  String? _activeChatId;
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  String? _errorMessage;

  // Real-time states
  final Map<String, bool> _typingUsers = {}; // chatId -> bool
  final Map<String, String> _userStatuses = {}; // userId -> status (online/offline)
  
  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isMessagesLoading => _isMessagesLoading;
  String? get errorMessage => _errorMessage;

  void initSocketListeners(String currentUserId) {
    if (!_socketService.isConnected) return;

    _socketService.socket.off('new_message');
    _socketService.socket.on('new_message', (data) {
      final message = MessageModel.fromJson(data);
      if (_activeChatId == message.chatId) {
        _messages.insert(0, message);
        _socketService.socket.emit('message_seen', {
          'chatId': message.chatId,
          'messageId': message.id
        });
        _safeNotify();
      }
      _updateChatListWithNewMessage(message);
    });

    _socketService.socket.off('message_status_update');
    _socketService.socket.on('message_status_update', (data) {
      final String messageId = data['messageId'];
      final String status = data['status'];
      
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: status == 'seen' ? MessageStatus.seen : MessageStatus.sent
        );
        _safeNotify();
      }
    });

    _socketService.socket.off('typing_status');
    _socketService.socket.on('typing_status', (data) {
      final String chatId = data['chatId'];
      final bool isTyping = data['isTyping'];
      _typingUsers[chatId] = isTyping;
      _safeNotify();
    });

    _socketService.socket.off('user_online');
    _socketService.socket.on('user_online', (data) {
      _userStatuses[data['userId']] = 'online';
      _safeNotify();
    });

    _socketService.socket.off('user_offline');
    _socketService.socket.on('user_offline', (data) {
      _userStatuses[data['userId']] = 'offline';
      _safeNotify();
    });
  }

  bool isUserTyping(String chatId) => _typingUsers[chatId] ?? false;
  String getUserStatus(String userId) => _userStatuses[userId] ?? 'offline';

  Future<void> fetchChats() async {
    _isLoading = true;
    _safeNotify();
    try {
      _chats = await _repository.getUserChats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> fetchMessages(String chatId) async {
    _isMessagesLoading = true;
    _messages = [];
    _activeChatId = chatId;
    _safeNotify();
    try {
      _messages = await _repository.getChatMessages(chatId);
      if (_socketService.isConnected) {
        _socketService.socket.emit('join_chat', chatId);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isMessagesLoading = false;
      _safeNotify();
    }
  }

  void clearActiveChat() {
    _activeChatId = null;
    _messages = [];
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    String? text,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
  }) async {
    if (text == null && fileUrl == null) return;
    
    try {
      final message = await _repository.sendMessage(chatId, {
        'text': text,
        'receiverId': receiverId,
        'messageType': type.toString().split('.').last,
        'fileUrl': fileUrl,
        'fileName': fileName,
      });

      final alreadyExists = _messages.any((m) => m.id == message.id);
      if (!alreadyExists && _messages.isNotEmpty && _messages.first.chatId == chatId) {
        _messages.insert(0, message);
        _safeNotify();
      }
      _updateChatListWithNewMessage(message);
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  void setTyping(String chatId, String receiverId, bool isTyping) {
    if (_socketService.isConnected) {
      if (isTyping) {
        _socketService.socket.emit('typing', {'chatId': chatId, 'receiverId': receiverId});
      } else {
        _socketService.socket.emit('stop_typing', {'chatId': chatId, 'receiverId': receiverId});
      }
    }
  }

  void _updateChatListWithNewMessage(MessageModel message) {
    final index = _chats.indexWhere((c) => c.id == message.chatId);
    if (index != -1) {
      final chat = _chats.removeAt(index);
      chat.lastMessage = message;
      _chats.insert(0, chat);
      _safeNotify();
    } else {
      fetchChats();
    }
  }
}
