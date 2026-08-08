import 'user_model.dart';
import 'message_model.dart';
import 'donation_model.dart';

class ChatModel {
  final String id;
  final List<UserModel> participants;
  final DonationModel? donation;
  MessageModel? lastMessage;
  final Map<String, int> unreadCounts;
  final List<String> pinnedBy;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.donation,
    this.lastMessage,
    this.unreadCounts = const {},
    this.pinnedBy = const [],
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) => p is Map<String, dynamic> ? UserModel.fromJson(p) : UserModel(id: p.toString(), email: '', name: 'User', role: UserRole.donor, phoneNumber: ''))
          .toList(),
      donation: json['donationId'] is Map<String, dynamic> ? DonationModel.fromJson(json['donationId']) : null,
      lastMessage: json['lastMessage'] is Map<String, dynamic> ? MessageModel.fromJson(json['lastMessage']) : null,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      pinnedBy: List<String>.from(json['pinnedBy'] ?? []),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  UserModel getOtherParticipant(String currentUserId) {
    return participants.firstWhere((p) => p.id != currentUserId);
  }

  ChatModel copyWith({
    String? id,
    List<UserModel>? participants,
    DonationModel? donation,
    MessageModel? lastMessage,
    Map<String, int>? unreadCounts,
    List<String>? pinnedBy,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      donation: donation ?? this.donation,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
