import 'chat_message_entity.dart';

/// 채팅방 엔티티
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = 0,
    this.partnerName,
    this.partnerPhotoUrl,
    this.partnerElementType,
    this.partnerCharacterAsset,
    this.compatibilityScore,
  });

  final String id;
  final String matchId;
  final String user1Id;
  final String user2Id;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;

  // 상대방 정보 (조인해서 가져옴)
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerElementType;
  final String? partnerCharacterAsset;
  final int? compatibilityScore;

  /// 상대방 ID 반환
  String partnerId(String myUserId) =>
      myUserId == user1Id ? user2Id : user1Id;

  /// 마지막 메시지 미리보기 텍스트
  String get lastMessagePreview {
    if (lastMessage == null) return '매칭이 성사되었어요!';
    if (lastMessage!.isDeleted) return '삭제된 메시지';
    if (lastMessage!.isImage) return '사진';
    if (lastMessage!.isIcebreaker) return '아이스브레이커';
    return lastMessage!.content;
  }

  bool get hasUnread => unreadCount > 0;

  ChatRoom copyWith({
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id,
      matchId: matchId,
      user1Id: user1Id,
      user2Id: user2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
      partnerName: partnerName,
      partnerPhotoUrl: partnerPhotoUrl,
      partnerElementType: partnerElementType,
      partnerCharacterAsset: partnerCharacterAsset,
      compatibilityScore: compatibilityScore,
    );
  }
}
