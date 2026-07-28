import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime time;
  final bool read;

  MessageModel({required this.senderId, required this.text, required this.time, this.read = false});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'],
      text: json['text'],
      time: DateTime.parse(json['time']),
      read: json['read'] ?? false,
    );
  }
}

class ChatModel {
  final String id;
  final List<String> participantIds;
  final String? otherUserName;
  final String? donationId;
  final List<MessageModel> messages;

  ChatModel({required this.id, required this.participantIds, this.otherUserName, this.donationId, this.messages = const []});

  factory ChatModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = json['participants'] as List;
    String? otherName;
    for (var p in participants) {
        if (p is Map && p['_id'] != currentUserId) {
            otherName = p['name'];
        }
    }
    
    return ChatModel(
      id: json['_id'] ?? json['id'],
      participantIds: participants.map((p) => p is Map ? p['_id'].toString() : p.toString()).toList(),
      otherUserName: otherName,
      donationId: json['donationId'] is Map ? json['donationId']['_id'] : json['donationId'],
      messages: (json['messages'] as List? ?? []).map((m) => MessageModel.fromJson(m)).toList(),
    );
  }
}

class ChatRepository {
  final ApiService _apiService = ApiService();

  Future<ChatModel> getOrCreateChat(String receiverId, String donationId, String currentUserId) async {
    try {
      final response = await _apiService.dio.post(
        'chat',
        data: {'receiverId': receiverId, 'donationId': donationId},
      );
      return ChatModel.fromJson(response.data['data'], currentUserId);
    } on DioException catch (e) {
      throw e.error ?? "Failed to initialize chat";
    }
  }

  Future<MessageModel> sendMessage(String chatId, String text) async {
    try {
      final response = await _apiService.dio.post(
        'chat/$chatId/messages',
        data: {'text': text},
      );
      return MessageModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to send message";
    }
  }

  Future<List<ChatModel>> getUserChats(String currentUserId) async {
    try {
      final response = await _apiService.dio.get('chat');
      final List data = response.data['data'];
      return data.map((json) => ChatModel.fromJson(json, currentUserId)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch chats";
    }
  }
}
