import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/domain/entities/chat_room_entity.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/matching/presentation/providers/matching_provider.dart';

// =============================================================================
// 하단 탭 뱃지 카운트 Providers
// =============================================================================

/// 채팅 탭 뱃지: 전체 안읽은 메시지 수
///
/// chatRoomsProvider에서 unreadCount 합계만 선택적으로 감시(.select)하여
/// 불필요한 내비게이션 바 리빌드를 방지합니다.
final chatBadgeCountProvider = Provider<int>((ref) {
  final totalUnread = ref.watch(
    chatRoomsProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (List<ChatRoom> rooms) =>
            rooms.fold(0, (sum, room) => sum + room.unreadCount),
        orElse: () => 0,
      ),
    ),
  );
  return totalUnread;
});

/// 매칭 탭 뱃지: 응답 대기 중인 받은 좋아요 수
///
/// receivedLikesProvider에서 pending 상태인 좋아요만 카운트.
/// 이 Provider가 watch하는 동안 receivedLikesProvider의 AutoDispose가
/// 해제되지 않도록 Riverpod이 자동 보장합니다.
final matchingBadgeCountProvider = Provider<int>((ref) {
  final pendingCount = ref.watch(
    receivedLikesProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (likes) => likes.where((l) => l.isPending).length,
        orElse: () => 0,
      ),
    ),
  );
  return pendingCount;
});

/// 전체 알림 뱃지 합계 (홈 탭 등에서 표시 가능)
final totalBadgeCountProvider = Provider<int>((ref) {
  return ref.watch(chatBadgeCountProvider) +
      ref.watch(matchingBadgeCountProvider);
});
