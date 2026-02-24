import '../../domain/entities/chat_message_entity.dart';

/// ChatMessage DTO — Supabase ↔ Entity 변환
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.isDeleted = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final bool isDeleted;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
    };
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content,
      messageType: MessageType.fromString(messageType),
      isRead: isRead,
      createdAt: createdAt,
      isDeleted: isDeleted,
    );
  }
}
