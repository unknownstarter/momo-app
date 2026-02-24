import 'dart:async';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// Chat Repository Supabase 구현체
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._datasource);

  final ChatRemoteDatasource _datasource;

  @override
  Stream<List<ChatRoom>> watchChatRooms(String userId) {
    // 초기 로드 + Realtime 변경 감지 시 재조회
    final controller = StreamController<List<ChatRoom>>();

    // 초기 데이터 로드
    _loadAndEmitRooms(userId, controller);

    // Realtime 구독: 채팅방 변경 감지
    final roomChannel = _datasource.subscribeToChatRooms(
      onChanged: () => _loadAndEmitRooms(userId, controller),
    );

    // 메시지 테이블 변경도 감지 (새 메시지 → 목록 업데이트)
    final msgChannel = _datasource.subscribeToMessages(
      '', // 전체 메시지 감지를 위해 빈 roomId는 사용하지 않음
      onNewMessage: (_) => _loadAndEmitRooms(userId, controller),
    );

    controller.onCancel = () {
      _datasource.unsubscribe(roomChannel);
      _datasource.unsubscribe(msgChannel);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _loadAndEmitRooms(
    String userId,
    StreamController<List<ChatRoom>> controller,
  ) async {
    try {
      final models = await _datasource.getChatRooms(userId);
      if (!controller.isClosed) {
        controller.add(models.map((m) => m.toEntity()).toList());
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    final controller = StreamController<List<ChatMessage>>();
    final messages = <ChatMessage>[];

    // 초기 메시지 로드
    _datasource.getMessages(roomId).then((models) {
      messages.addAll(models.map((m) => m.toEntity()));
      // 시간순 정렬 (오래된 것 → 최신)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(messages));
      }
    }).catchError((Object e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Realtime 구독: 새 메시지 수신
    final channel = _datasource.subscribeToMessages(
      roomId,
      onNewMessage: (model) {
        final msg = model.toEntity();
        // 중복 방지
        if (!messages.any((m) => m.id == msg.id)) {
          messages.add(msg);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          if (!controller.isClosed) {
            controller.add(List.unmodifiable(messages));
          }
        }
      },
    );

    controller.onCancel = () {
      _datasource.unsubscribe(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<ChatMessage>> loadMessages(
    String roomId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final models = await _datasource.getMessages(
      roomId,
      limit: limit,
      before: before,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
  }) async {
    final model = await _datasource.sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: content,
      messageType: messageType.name,
    );
    return model.toEntity();
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String roomId,
    required String senderId,
    required String imagePath,
  }) async {
    final model = await _datasource.sendImageMessage(
      roomId: roomId,
      senderId: senderId,
      imagePath: imagePath,
    );
    return model.toEntity();
  }

  @override
  Future<void> markAsRead(String roomId, String userId) async {
    await _datasource.markAsRead(roomId, userId);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _datasource.deleteMessage(messageId);
  }

  @override
  Future<ChatRoom> createChatRoom({
    required String matchId,
    required String user1Id,
    required String user2Id,
  }) async {
    final model = await _datasource.createChatRoom(
      matchId: matchId,
      user1Id: user1Id,
      user2Id: user2Id,
    );
    return model.toEntity();
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) async {
    final model = await _datasource.getChatRoom(roomId);
    return model?.toEntity();
  }

  @override
  Future<int> getTotalUnreadCount(String userId) async {
    return _datasource.getTotalUnreadCount(userId);
  }
}
