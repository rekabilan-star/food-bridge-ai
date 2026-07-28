import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  ChatModel? _activeChat;
  List<ChatModel> _userChats = [];
  bool _isLoading = false;
  String? _errorMessage;

  ChatModel? get activeChat => _activeChat;
  List<ChatModel> get userChats => _userChats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchUserChats(String currentUserId) async {
    _setLoading(true);
    try {
      _userChats = await _repository.getUserChats(currentUserId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> openChat(String receiverId, String donationId, String currentUserId) async {
    _setLoading(true);
    try {
      _activeChat = await _repository.getOrCreateChat(receiverId, donationId, currentUserId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> sendMessage(String text) async {
    if (_activeChat == null) return false;
    try {
      final newMessage = await _repository.sendMessage(_activeChat!.id, text);
      _activeChat!.messages.add(newMessage);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
