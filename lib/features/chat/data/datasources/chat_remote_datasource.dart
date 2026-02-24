import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

/// Chat Supabase 데이터소스
///
/// Supabase DB 쿼리 + Realtime 구독 + Storage 업로드를 담당합니다.
class ChatRemoteDatasource {
  const ChatRemoteDatasource(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // 채팅방 목록
  // ---------------------------------------------------------------------------

  /// 내 채팅방 목록 조회 (마지막 메시지 시간순 정렬)
  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    // 내가 참여한 채팅방 조회
    final response = await _client
        .from(SupabaseTables.chatRooms)
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_message_at', ascending: false, nullsFirst: false);

    final rooms = <ChatRoomModel>[];
    for (final row in response) {
      // 상대방 프로필 조회
      final partnerId =
          row['user1_id'] == userId ? row['user2_id'] : row['user1_id'];
      final partner = await _client
          .from(SupabaseTables.profiles)
          .select('name, profile_images, dominant_element, character_type')
          .eq('id', partnerId)
          .maybeSingle();

      // 마지막 메시지 조회
      final lastMsg = await _client
          .from(SupabaseTables.chatMessages)
          .select()
          .eq('room_id', row['id'])
          .order('created_at', ascending: false)
          .limit(1);

      // 안읽은 메시지 수
      final unreadResponse = await _client
          .from(SupabaseTables.chatMessages)
          .select()
          .eq('room_id', row['id'])
          .neq('sender_id', userId)
          .eq('is_read', false);
      final unreadCount = (unreadResponse as List).length;

      // 궁합 점수 조회
      final compat = await _client
          .from(SupabaseTables.sajuCompatibility)
          .select('total_score')
          .or('user_id.eq.$userId,partner_id.eq.$userId')
          .or('user_id.eq.$partnerId,partner_id.eq.$partnerId')
          .maybeSingle();

      rooms.add(ChatRoomModel.fromJson({
        ...row,
        'partner_profile': partner,
        'last_message': lastMsg,
        'unread_count': unreadCount,
        'compatibility_score': compat?['total_score'],
      }));
    }

    return rooms;
  }

  /// 채팅방 단건 조회
  Future<ChatRoomModel?> getChatRoom(String roomId) async {
    final row = await _client
        .from(SupabaseTables.chatRooms)
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (row == null) return null;

    final userId = _currentUserId;
    final partnerId =
        row['user1_id'] == userId ? row['user2_id'] : row['user1_id'];
    final partner = await _client
        .from(SupabaseTables.profiles)
        .select('name, profile_images, dominant_element, character_type')
        .eq('id', partnerId)
        .maybeSingle();

    return ChatRoomModel.fromJson({
      ...row,
      'partner_profile': partner,
    });
  }

  // ---------------------------------------------------------------------------
  // 메시지
  // ---------------------------------------------------------------------------

  /// 메시지 목록 로드 (페이지네이션)
  Future<List<ChatMessageModel>> getMessages(
    String roomId, {
    int limit = AppLimits.chatPageSize,
    DateTime? before,
  }) async {
    var query = _client
        .from(SupabaseTables.chatMessages)
        .select()
        .eq('room_id', roomId);

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final response =
        await query.order('created_at', ascending: false).limit(limit);

    return (response as List)
        .map((row) =>
            ChatMessageModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// 메시지 전송
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    String messageType = 'text',
  }) async {
    final response = await _client
        .from(SupabaseTables.chatMessages)
        .insert({
          'room_id': roomId,
          'sender_id': senderId,
          'content': content,
          'message_type': messageType,
        })
        .select()
        .single();

    // 채팅방 마지막 메시지 시간 업데이트
    await _client
        .from(SupabaseTables.chatRooms)
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', roomId);

    return ChatMessageModel.fromJson(response);
  }

  /// 이미지 업로드 후 메시지 전송
  Future<ChatMessageModel> sendImageMessage({
    required String roomId,
    required String senderId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    final ext = imagePath.split('.').last;
    final storagePath = '$roomId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    // Storage에 업로드
    await _client.storage
        .from(SupabaseBuckets.chatImages)
        .upload(storagePath, file);

    final imageUrl = _client.storage
        .from(SupabaseBuckets.chatImages)
        .getPublicUrl(storagePath);

    return sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: imageUrl,
      messageType: 'image',
    );
  }

  /// 메시지 읽음 처리 (해당 채팅방의 상대 메시지 모두)
  Future<void> markAsRead(String roomId, String userId) async {
    await _client
        .from(SupabaseTables.chatMessages)
        .update({'is_read': true})
        .eq('room_id', roomId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  /// 메시지 삭제 (soft delete — 내용만 비움)
  Future<void> deleteMessage(String messageId) async {
    await _client
        .from(SupabaseTables.chatMessages)
        .update({
          'content': '',
          'is_deleted': true,
        })
        .eq('id', messageId);
  }

  // ---------------------------------------------------------------------------
  // 채팅방 생성
  // ---------------------------------------------------------------------------

  /// 매칭 성사 시 채팅방 생성 + 시스템 메시지 삽입
  Future<ChatRoomModel> createChatRoom({
    required String matchId,
    required String user1Id,
    required String user2Id,
  }) async {
    final response = await _client
        .from(SupabaseTables.chatRooms)
        .insert({
          'match_id': matchId,
          'user1_id': user1Id,
          'user2_id': user2Id,
        })
        .select()
        .single();

    final roomId = response['id'] as String;

    // 시스템 메시지: 매칭 알림
    await _client.from(SupabaseTables.chatMessages).insert({
      'room_id': roomId,
      'sender_id': user1Id,
      'content': '매칭이 성사되었어요! 사주 궁합으로 이어진 인연이에요.',
      'message_type': 'system',
    });

    return ChatRoomModel.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Realtime 구독
  // ---------------------------------------------------------------------------

  /// 특정 채팅방 새 메시지 구독
  RealtimeChannel subscribeToMessages(
    String roomId, {
    required void Function(ChatMessageModel message) onNewMessage,
  }) {
    final channel = _client.channel('chat:$roomId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseTables.chatMessages,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        final data = payload.newRecord;
        if (data.isNotEmpty) {
          onNewMessage(ChatMessageModel.fromJson(data));
        }
      },
    );

    channel.subscribe();
    return channel;
  }

  /// 채팅방 목록 변경 구독 (새 채팅방 생성 감지)
  RealtimeChannel subscribeToChatRooms({
    required void Function() onChanged,
  }) {
    final channel = _client.channel('chat_rooms_changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: SupabaseTables.chatRooms,
      callback: (_) => onChanged(),
    );

    channel.subscribe();
    return channel;
  }

  /// 채널 구독 해제
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // 통계
  // ---------------------------------------------------------------------------

  /// 전체 안읽은 메시지 수
  Future<int> getTotalUnreadCount(String userId) async {
    // 내가 참여한 채팅방 ID들
    final rooms = await _client
        .from(SupabaseTables.chatRooms)
        .select('id')
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    final roomIds = (rooms as List).map((r) => r['id'] as String).toList();
    if (roomIds.isEmpty) return 0;

    int total = 0;
    for (final roomId in roomIds) {
      final unread = await _client
          .from(SupabaseTables.chatMessages)
          .select()
          .eq('room_id', roomId)
          .neq('sender_id', userId)
          .eq('is_read', false);
      total += (unread as List).length;
    }

    return total;
  }
}
