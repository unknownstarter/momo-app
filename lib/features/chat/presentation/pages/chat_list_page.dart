import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/saju_avatar.dart';
import '../../../../core/widgets/saju_badge.dart';
import '../../../../core/widgets/saju_enums.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../providers/chat_provider.dart';

/// 채팅 목록 화면 — 미니멀 Sendbird 스타일
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Theme.of(context).textTheme.headlineMedium?.color,
        ),
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                '채팅 목록을 불러올 수 없어요',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (context2, index) => Divider(
              height: 1,
              indent: 72,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) => _ChatRoomTile(room: rooms[index]),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 채팅방 타일
// =============================================================================

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push(RoutePaths.chatRoomPath(room.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아바타
            SajuAvatar(
              name: room.partnerName ?? '?',
              size: SajuSize.lg,
              elementColor: _elementToColor(room.partnerElementType),
            ),

            const SizedBox(width: 12),

            // 이름 + 마지막 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 첫째 줄: 이름 + 궁합 뱃지
                  Row(
                    children: [
                      Text(
                        room.partnerName ?? '알 수 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (room.compatibilityScore != null) ...[
                        const SizedBox(width: 6),
                        SajuBadge(
                          label: '${room.compatibilityScore}%',
                          color: _scoreToColor(room.compatibilityScore!),
                          size: SajuSize.xs,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 둘째 줄: 마지막 메시지 미리보기
                  Text(
                    room.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: room.hasUnread
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.grey.shade500),
                      fontWeight:
                          room.hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 시간 + 안읽음 뱃지
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(room.lastMessageAt ?? room.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: room.hasUnread
                        ? AppTheme.compatibilityGood
                        : Colors.grey.shade400,
                  ),
                ),
                if (room.hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8C8E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      room.unreadCount > 99
                          ? '99+'
                          : '${room.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) {
      final hour = time.hour;
      final amPm = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$amPm $displayHour:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }

  static SajuColor _elementToColor(String? element) {
    return switch (element) {
      'wood' => SajuColor.wood,
      'fire' => SajuColor.fire,
      'earth' => SajuColor.earth,
      'metal' => SajuColor.metal,
      'water' => SajuColor.water,
      _ => SajuColor.primary,
    };
  }

  static SajuColor _scoreToColor(int score) {
    if (score >= 90) return SajuColor.fire;
    if (score >= 70) return SajuColor.earth;
    return SajuColor.primary;
  }
}

// =============================================================================
// 빈 상태
// =============================================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 채팅이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '매칭이 성사되면 여기서\n대화를 시작할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
