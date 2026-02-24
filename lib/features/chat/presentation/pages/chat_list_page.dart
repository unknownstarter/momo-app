import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
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
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                '채팅 목록을 불러올 수 없어요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) =>
                _ChatRoomTile(room: rooms[index]),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push(RoutePaths.chatRoomPath(room.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd * 0.75,
        ),
        child: Row(
          children: [
            // 아바타 — 디자인 시스템 SajuAvatar
            SajuAvatar(
              name: room.partnerName ?? '?',
              size: SajuSize.lg,
              elementColor: SajuColor.fromElement(room.partnerElementType),
            ),

            const SizedBox(width: AppTheme.spacingMd * 0.75),

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
                        style: theme.textTheme.titleSmall?.copyWith(
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

                  const SizedBox(height: AppTheme.spacingXs),

                  // 둘째 줄: 마지막 메시지 미리보기
                  Text(
                    room.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: room.hasUnread
                          ? colorScheme.onSurface.withValues(alpha: 0.8)
                          : colorScheme.outline,
                      fontWeight:
                          room.hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppTheme.spacingSm),

            // 시간 + 안읽음 뱃지
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.formatRelativeTime(
                    room.lastMessageAt ?? room.createdAt,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: room.hasUnread
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
                if (room.hasUnread) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      room.unreadCount > 99
                          ? '99+'
                          : '${room.unreadCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '아직 채팅이 없어요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '매칭이 성사되면 여기서\n대화를 시작할 수 있어요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
