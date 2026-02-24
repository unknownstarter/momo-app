import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/chat_room_entity.dart';
import 'chat_message_model.dart';

/// ChatRoom DTO — Supabase ↔ Entity 변환
class ChatRoomModel {
  const ChatRoomModel({
    required this.id,
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    this.lastMessageAt,
    required this.createdAt,
    this.lastMessage,
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
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerElementType;
  final String? partnerCharacterAsset;
  final int? compatibilityScore;

  factory ChatRoomModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // 상대방 프로필 정보 (조인된 경우)
    final partner = json['partner_profile'] as Map<String, dynamic>?;

    // 마지막 메시지 (조인된 경우)
    ChatMessageModel? lastMsg;
    final lastMsgData = json['last_message'];
    if (lastMsgData is List && lastMsgData.isNotEmpty) {
      lastMsg = ChatMessageModel.fromJson(
        lastMsgData.first as Map<String, dynamic>,
      );
    } else if (lastMsgData is Map<String, dynamic>) {
      lastMsg = ChatMessageModel.fromJson(lastMsgData);
    }

    return ChatRoomModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessage: lastMsg,
      unreadCount: json['unread_count'] as int? ?? 0,
      partnerName: partner?['name'] as String?,
      partnerPhotoUrl: (partner?['profile_images'] as List?)?.isNotEmpty == true
          ? (partner!['profile_images'] as List).first as String
          : null,
      partnerElementType: partner?['dominant_element'] as String?,
      partnerCharacterAsset: _characterAsset(partner?['character_type'] as String?),
      compatibilityScore: json['compatibility_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'user1_id': user1Id,
      'user2_id': user2Id,
    };
  }

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      matchId: matchId,
      user1Id: user1Id,
      user2Id: user2Id,
      lastMessage: lastMessage?.toEntity(),
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      unreadCount: unreadCount,
      partnerName: partnerName,
      partnerPhotoUrl: partnerPhotoUrl,
      partnerElementType: partnerElementType,
      partnerCharacterAsset: partnerCharacterAsset,
      compatibilityScore: compatibilityScore,
    );
  }

  static String? _characterAsset(String? characterType) {
    if (characterType == null) return null;
    const assetMap = {
      'namuri': CharacterAssets.namuriWoodDefault,
      'bulkkori': CharacterAssets.bulkkoriFireDefault,
      'heuksuni': CharacterAssets.heuksuniEarthDefault,
      'soedongi': CharacterAssets.soedongiMetalDefault,
      'mulgyeori': CharacterAssets.mulgyeoriWaterDefault,
    };
    return assetMap[characterType];
  }
}
