import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/matching/presentation/providers/matching_provider.dart';

// =============================================================================
// 하단 탭 뱃지 카운트 Providers
// =============================================================================

/// 채팅 탭 뱃지: 전체 안읽은 메시지 수
///
/// chatRoomsProvider(StreamProvider)에서 파생하여 실시간 업데이트.
/// 채팅방 목록이 갱신될 때마다 자동으로 합산됩니다.
final chatBadgeCountProvider = Provider<int>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);
  return roomsAsync.when(
    data: (rooms) => rooms.fold(0, (sum, room) => sum + room.unreadCount),
    loading: () => 0,
    error: (e, st) => 0,
  );
});

/// 매칭 탭 뱃지: 응답 대기 중인 받은 좋아요 수
///
/// receivedLikesProvider에서 pending 상태인 좋아요만 카운트.
/// 새 좋아요가 오거나 수락/거절하면 자동 업데이트됩니다.
final matchingBadgeCountProvider = Provider<int>((ref) {
  final likesAsync = ref.watch(receivedLikesProvider);
  return likesAsync.when(
    data: (likes) => likes.where((l) => l.isPending).length,
    loading: () => 0,
    error: (e, st) => 0,
  );
});

/// 전체 알림 뱃지 합계 (홈 탭 등에서 표시 가능)
final totalBadgeCountProvider = Provider<int>((ref) {
  return ref.watch(chatBadgeCountProvider) +
      ref.watch(matchingBadgeCountProvider);
});
