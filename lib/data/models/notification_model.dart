class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String category;
  final String priority;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime? expiresAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.data,
    required this.isRead,
    this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired {
    if (expiresAt != null) {
      return DateTime.now().isAfter(expiresAt!);
    }
    return false;
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? category,
    String? priority,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiry;
    if (json['expiresAt'] != null) {
      try {
        parsedExpiry = DateTime.parse(json['expiresAt'].toString()).toLocal();
      } catch (_) {
        parsedExpiry = null;
      }
    }

    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? 'SYSTEM',
      priority: json['priority'] ?? 'medium',
      data: json['data'] ?? {},
      isRead: json['read'] ?? false,
      expiresAt: parsedExpiry,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'category': category,
      'priority': priority,
      'data': data,
      'read': isRead,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
