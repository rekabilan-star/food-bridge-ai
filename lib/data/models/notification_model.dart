class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String category;
  final String priority;
  final Map<String, dynamic> data;
  bool isRead;
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
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? 'SYSTEM',
      priority: json['priority'] ?? 'medium',
      data: json['data'] ?? {},
      isRead: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
