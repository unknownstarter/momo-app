import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_room_entity.dart';

// =============================================================================
// 채팅방 목록 Provider
// =============================================================================

/// 채팅방 목록 스트림
///
/// Realtime으로 업데이트되는 채팅방 목록을 제공합니다.
final chatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  // TODO: 실제 userId로 교체 (현재는 Mock)
  return repo.watchChatRooms('current-user');
});

/// 전체 안읽은 메시지 수
final totalUnreadCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getTotalUnreadCount('current-user');
});

// =============================================================================
// 채팅방 메시지 Provider
// =============================================================================

/// 특정 채팅방 메시지 스트림
///
/// [roomId]를 family 파라미터로 받아 해당 방의 메시지를 실시간 제공합니다.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);

  // 채팅방 진입 시 읽음 처리
  repo.markAsRead(roomId, 'current-user');

  return repo.watchMessages(roomId);
});

/// 특정 채팅방 정보
final chatRoomProvider =
    FutureProvider.family<ChatRoom?, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChatRoom(roomId);
});

// =============================================================================
// 메시지 전송 Notifier
// =============================================================================

/// 메시지 전송 상태
class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  SendMessageNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// 텍스트 메시지 전송
  Future<void> send({
    required String roomId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        roomId: roomId,
        senderId: 'current-user',
        content: content.trim(),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 이미지 메시지 전송
  Future<void> sendImage({
    required String roomId,
    required String imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(chatRepositoryProvider);
      await repo.sendImageMessage(
        roomId: roomId,
        senderId: 'current-user',
        imagePath: imagePath,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      final repo = _ref.read(chatRepositoryProvider);
      await repo.deleteMessage(messageId);
    } catch (_) {
      // 삭제 실패는 무시
    }
  }
}

/// 메시지 전송 Provider
final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
  return SendMessageNotifier(ref);
});
