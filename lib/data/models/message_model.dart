enum MessageType { text, image, pdf, audio, location }
enum MessageStatus { sent, delivered, seen }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String? text;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  MessageStatus status;
  final String? replyTo;
  final bool isEdited;
  final bool isDeleted;
  final List<String> deletedFor;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.status = MessageStatus.sent,
    this.replyTo,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedFor = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'],
      messageType: MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == (json['messageType'] ?? 'text'),
          orElse: () => MessageType.text),
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      status: MessageStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (json['status'] ?? 'sent'),
          orElse: () => MessageStatus.sent),
      replyTo: json['replyTo'] is Map ? json['replyTo']['_id'] : json['replyTo'],
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      deletedFor: List<String>.from(json['deletedFor'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'messageType': messageType.toString().split('.').last,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'status': status.toString().split('.').last,
      'replyTo': replyTo,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? messageType,
    String? fileUrl,
    String? fileName,
    MessageStatus? status,
    String? replyTo,
    bool? isEdited,
    bool? isDeleted,
    List<String>? deletedFor,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
