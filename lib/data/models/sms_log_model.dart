class SmsLogModel {
  final String id;
  final String phoneNumber;
  final String message;
  final String status;
  final String provider;
  final String? error;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  SmsLogModel({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.provider,
    this.error,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory SmsLogModel.fromJson(Map<String, dynamic> json) {
    final userData = json['userId'] is Map ? json['userId'] : null;
    DateTime date;
    try {
      date = json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()).toLocal() : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return SmsLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'unknown',
      provider: json['provider'] ?? 'simulated',
      error: json['error'],
      createdAt: date,
      userName: userData?['name'],
      userEmail: userData?['email'],
    );
  }
}
