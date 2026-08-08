import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ApiService _apiService = ApiService();

  Future<ChatModel> getOrCreateChat(String receiverId, {String? donationId}) async {
    try {
      final Map<String, dynamic> body = {
        'receiverId': receiverId,
      };
      if (donationId != null) {
        body['donationId'] = donationId;
      }

      final response = await _apiService.dio.post(
        'chat',
        data: body,
      );
      return ChatModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to create chat";
    }
  }

  Future<List<ChatModel>> getUserChats() async {
    try {
      final response = await _apiService.dio.get('chat');
      final List data = response.data['data'];
      return data.map((json) => ChatModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch chats";
    }
  }

  Future<List<MessageModel>> getChatMessages(String chatId, {int page = 1}) async {
    try {
      final response = await _apiService.dio.get(
        'chat/$chatId/messages',
        queryParameters: {'page': page, 'limit': 30},
      );
      final List data = response.data['data'];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch messages";
    }
  }

  Future<MessageModel> sendMessage(String chatId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        'chat/$chatId/messages',
        data: data,
      );
      return MessageModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to send message";
    }
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _apiService.dio.put(
        'chat/messages/$messageId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to update status";
    }
  }
}
