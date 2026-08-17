import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/push_notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  final SocketService _socketService = SocketService();
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _socketService.socket.off('new_notification');
    _socketService.socket.off('unread_count_update');
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isMoreLoading = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  // Filters
  String? _selectedCategory;
  String? _searchQuery;
  bool? _readFilter;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _currentPage < _totalPages;
  String? get selectedCategory => _selectedCategory;

  void initSocketListeners() {
    if (!_socketService.isConnected) return;

    _socketService.socket.off('new_notification');
    _socketService.socket.on('new_notification', (data) {
      final newNotification = NotificationModel.fromJson(data);
      _notifications.insert(0, newNotification);
      _unreadCount++;
      
      PushNotificationService.showNotification(
        title: newNotification.title,
        body: newNotification.body,
        data: newNotification.data,
      );

      _safeNotify();
    });

    _socketService.socket.off('unread_count_update');
    _socketService.socket.on('unread_count_update', (data) {
      _unreadCount = data['unreadCount'] ?? _unreadCount;
      _safeNotify();
    });
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading || _isMoreLoading) return;

    if (refresh) {
      _currentPage = 1;
      _isLoading = true;
    } else {
      if (_currentPage >= _totalPages && _notifications.isNotEmpty) return;
      _isMoreLoading = true;
    }
    
    _safeNotify();

    try {
      final result = await _repository.getNotifications(
        page: _currentPage,
        limit: _limit,
        category: _selectedCategory,
        search: _searchQuery,
        read: _readFilter,
      );

      final List<NotificationModel> fetchedNotifications = (result['notifications'] as List?)?.cast<NotificationModel>() ?? [];
      
      if (refresh) {
        _notifications = fetchedNotifications;
      } else {
        _notifications.addAll(fetchedNotifications);
      }

      _unreadCount = result['unreadCount'] ?? 0;
      final pagination = result['pagination'];
      _totalPages = (pagination != null && pagination['pages'] != null)
          ? (pagination['pages'] as int)
          : 1;
      _currentPage++;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isMoreLoading = false;
      _safeNotify();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index].isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 1000000);
        _safeNotify();
        await _repository.markAsRead(id);
      }
    } catch (e) {
      _errorMessage = e.toString();
      await fetchNotifications(refresh: true);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllRead();
      for (var n in _notifications) {
        n.isRead = true;
      }
      _unreadCount = 0;
      _errorMessage = null;
      _safeNotify();
    } catch (e) {
      _errorMessage = e.toString();
      await fetchNotifications(refresh: true);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final bool wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, 1000000);
        }
      }
      _errorMessage = null;
      _safeNotify();
    } catch (e) {
      _errorMessage = e.toString();
      await fetchNotifications(refresh: true);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _repository.deleteAllNotifications();
      _notifications.clear();
      _unreadCount = 0;
      _errorMessage = null;
      _safeNotify();
    } catch (e) {
      _errorMessage = e.toString();
      await fetchNotifications(refresh: true);
    }
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    fetchNotifications(refresh: true);
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchNotifications(refresh: true);
  }
  
  void setReadFilter(bool? read) {
    _readFilter = read;
    fetchNotifications(refresh: true);
  }
}
