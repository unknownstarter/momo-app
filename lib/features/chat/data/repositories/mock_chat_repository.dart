import 'dart:async';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Mock Chat Repository — Supabase 연동 전 UI 개발용
class MockChatRepository implements ChatRepository {
  final _messageController = StreamController<List<ChatMessage>>.broadcast();
  final _messages = <String, List<ChatMessage>>{};

  @override
  Stream<List<ChatRoom>> watchChatRooms(String userId) async* {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield _mockRooms;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    // 초기 Mock 메시지 로드
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = _generateMockMessages(roomId);
    }

    final controller = StreamController<List<ChatMessage>>();
    controller.add(_messages[roomId]!);

    // broadcast 스트림에서 해당 방 메시지 필터링
    final sub = _messageController.stream.listen((msgs) {
      final roomMsgs = msgs.where((m) => m.roomId == roomId).toList();
      if (roomMsgs.isNotEmpty) {
        controller.add(_messages[roomId]!);
      }
    });

    controller.onCancel = () {
      sub.cancel();
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _messages[roomId] ?? [];
  }

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final msg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _messages.putIfAbsent(roomId, () => []);
    _messages[roomId]!.add(msg);
    _messageController.add(_messages[roomId]!);

    return msg;
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String roomId,
    required String senderId,
    required String imagePath,
  }) async {
    return sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: imagePath,
      messageType: MessageType.image,
    );
  }

  @override
  Future<void> markAsRead(String roomId, String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    for (final msgs in _messages.values) {
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(isDeleted: true);
        break;
      }
    }
  }

  @override
  Future<ChatRoom> createChatRoom({
    required String matchId,
    required String user1Id,
    required String user2Id,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockRooms.first;
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockRooms.where((r) => r.id == roomId).firstOrNull;
  }

  @override
  Future<int> getTotalUnreadCount(String userId) async {
    return 3;
  }
}

// =============================================================================
// Mock 데이터
// =============================================================================

final _mockRooms = [
  ChatRoom(
    id: 'room-001',
    matchId: 'match-001',
    user1Id: 'current-user',
    user2Id: 'mock-user-001',
    lastMessage: ChatMessage(
      id: 'last-msg-001',
      roomId: 'room-001',
      senderId: 'mock-user-001',
      content: '오늘 저녁에 시간 괜찮아요?',
      messageType: MessageType.text,
      isRead: false,
      createdAt: _now,
    ),
    lastMessageAt: _now,
    createdAt: _threeDaysAgo,
    unreadCount: 2,
    partnerName: '하늘',
    partnerElementType: 'water',
    partnerCharacterAsset:
        'assets/images/characters/mulgyeori_water_default.png',
    compatibilityScore: 92,
  ),
  ChatRoom(
    id: 'room-002',
    matchId: 'match-002',
    user1Id: 'current-user',
    user2Id: 'mock-user-002',
    lastMessage: ChatMessage(
      id: 'last-msg-002',
      roomId: 'room-002',
      senderId: 'current-user',
      content: '네! 좋아요 😊',
      messageType: MessageType.text,
      isRead: true,
      createdAt: _yesterday,
    ),
    lastMessageAt: _yesterday,
    createdAt: _fiveDaysAgo,
    unreadCount: 0,
    partnerName: '수아',
    partnerElementType: 'fire',
    partnerCharacterAsset:
        'assets/images/characters/bulkkori_fire_default.png',
    compatibilityScore: 78,
  ),
  ChatRoom(
    id: 'room-003',
    matchId: 'match-003',
    user1Id: 'mock-user-006',
    user2Id: 'current-user',
    lastMessage: ChatMessage(
      id: 'last-msg-003',
      roomId: 'room-003',
      senderId: 'mock-user-006',
      content: '매칭이 성사되었어요! 사주 궁합으로 이어진 인연이에요.',
      messageType: MessageType.system,
      isRead: true,
      createdAt: _twoDaysAgo,
    ),
    lastMessageAt: _twoDaysAgo,
    createdAt: _twoDaysAgo,
    unreadCount: 0,
    partnerName: '유진',
    partnerElementType: 'metal',
    partnerCharacterAsset:
        'assets/images/characters/gold_tokki_default.png',
    compatibilityScore: 88,
  ),
];

// 시간 상수 (const가 아니라 final로)
final _now = DateTime.now();
final _yesterday = DateTime.now().subtract(const Duration(days: 1));
final _twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
final _threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
final _fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));

List<ChatMessage> _generateMockMessages(String roomId) {
  final now = DateTime.now();

  if (roomId == 'room-001') {
    return [
      ChatMessage(
        id: 'msg-001-1',
        roomId: roomId,
        senderId: 'mock-user-001',
        content: '매칭이 성사되었어요! 사주 궁합으로 이어진 인연이에요.',
        messageType: MessageType.system,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ChatMessage(
        id: 'msg-001-2',
        roomId: roomId,
        senderId: 'current-user',
        content: '안녕하세요! 만나서 반가워요 😊',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3, hours: -1)),
      ),
      ChatMessage(
        id: 'msg-001-3',
        roomId: roomId,
        senderId: 'mock-user-001',
        content: '반가워요! 궁합이 92점이래요, 신기하죠?',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3, hours: -2)),
      ),
      ChatMessage(
        id: 'msg-001-4',
        roomId: roomId,
        senderId: 'current-user',
        content: '네! 사주로 보는 궁합이 이렇게 높다니 놀라워요',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ChatMessage(
        id: 'msg-001-5',
        roomId: roomId,
        senderId: 'mock-user-001',
        content: '혹시 이번 주말에 시간 있으세요?',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: 'msg-001-6',
        roomId: roomId,
        senderId: 'mock-user-001',
        content: '오늘 저녁에 시간 괜찮아요?',
        messageType: MessageType.text,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  if (roomId == 'room-002') {
    return [
      ChatMessage(
        id: 'msg-002-1',
        roomId: roomId,
        senderId: 'mock-user-002',
        content: '매칭이 성사되었어요! 사주 궁합으로 이어진 인연이에요.',
        messageType: MessageType.system,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ChatMessage(
        id: 'msg-002-2',
        roomId: roomId,
        senderId: 'mock-user-002',
        content: '안녕하세요~ 프로필 보고 반가워서 먼저 인사해요!',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5, hours: -1)),
      ),
      ChatMessage(
        id: 'msg-002-3',
        roomId: roomId,
        senderId: 'current-user',
        content: '네! 좋아요 😊',
        messageType: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  // room-003: 시스템 메시지만
  return [
    ChatMessage(
      id: 'msg-003-1',
      roomId: roomId,
      senderId: 'mock-user-006',
      content: '매칭이 성사되었어요! 사주 궁합으로 이어진 인연이에요.',
      messageType: MessageType.system,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}
