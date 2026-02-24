/// 채팅 메시지 타입
enum MessageType {
  text,
  image,
  icebreaker,
  system;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// 채팅 메시지 엔티티
class ChatMessage {
  const ChatMessage({
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
  final MessageType messageType;
  final bool isRead;
  final DateTime createdAt;
  final bool isDeleted;

  bool get isSystemMessage => messageType == MessageType.system;
  bool get isIcebreaker => messageType == MessageType.icebreaker;
  bool get isImage => messageType == MessageType.image;

  /// 내가 보낸 메시지인지 확인
  bool isMine(String myUserId) => senderId == myUserId;

  ChatMessage copyWith({
    bool? isRead,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: isDeleted == true ? '' : content,
      messageType: messageType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
