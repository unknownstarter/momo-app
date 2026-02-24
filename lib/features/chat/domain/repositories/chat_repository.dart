import '../entities/chat_room_entity.dart';
import '../entities/chat_message_entity.dart';

/// Chat Repository 인터페이스
///
/// 채팅 기능의 데이터 접근을 추상화합니다.
/// Supabase Realtime 기반 실시간 메시징을 지원합니다.
abstract class ChatRepository {
  /// 내 채팅방 목록 스트림 (실시간 업데이트)
  Stream<List<ChatRoom>> watchChatRooms(String userId);

  /// 채팅방 메시지 스트림 (실시간 수신)
  Stream<List<ChatMessage>> watchMessages(String roomId);

  /// 이전 메시지 로드 (페이지네이션)
  Future<List<ChatMessage>> loadMessages(
    String roomId, {
    int limit = 50,
    DateTime? before,
  });

  /// 텍스트 메시지 전송
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
  });

  /// 이미지 메시지 전송
  Future<ChatMessage> sendImageMessage({
    required String roomId,
    required String senderId,
    required String imagePath,
  });

  /// 메시지 읽음 처리
  Future<void> markAsRead(String roomId, String userId);

  /// 메시지 삭제 (soft delete)
  Future<void> deleteMessage(String messageId);

  /// 매칭 성사 시 채팅방 생성
  Future<ChatRoom> createChatRoom({
    required String matchId,
    required String user1Id,
    required String user2Id,
  });

  /// 채팅방 정보 조회
  Future<ChatRoom?> getChatRoom(String roomId);

  /// 전체 안읽은 메시지 수
  Future<int> getTotalUnreadCount(String userId);
}
