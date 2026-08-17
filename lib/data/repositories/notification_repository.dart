import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? read,
    String? category,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiService.dio.get(
        'notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          'read': read,
          'category': category,
          'search': search,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      
      final List data = response.data['notifications'] ?? [];
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      return {
        'notifications': notifications,
        'unreadCount': response.data['unreadCount'] ?? 0,
        'pagination': response.data['pagination'] ?? {
          'page': page,
          'limit': limit,
          'total': notifications.length,
          'pages': 1,
        },
      };
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch notifications";
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiService.dio.put('notifications/$id/read');
    } on DioException catch (e) {
      throw e.error ?? "Failed to mark notification as read";
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiService.dio.put('notifications/read-all');
    } on DioException catch (e) {
      throw e.error ?? "Failed to mark all notifications as read";
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _apiService.dio.delete('notifications/$id');
    } on DioException catch (e) {
      throw e.error ?? "Failed to delete notification";
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _apiService.dio.delete('notifications/delete-all');
    } on DioException catch (e) {
      throw e.error ?? "Failed to delete all notifications";
    }
  }
}
