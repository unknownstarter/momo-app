import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/saju_avatar.dart';
import '../../../../core/widgets/saju_badge.dart';
import '../../../../core/widgets/saju_enums.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_system_message.dart';

/// 채팅방 화면 — Sendbird 기본형 스타일
class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomAsync = ref.watch(chatRoomProvider(widget.roomId));

    // listen으로 새 메시지 감지 + 스크롤
    ref.listen(chatMessagesProvider(widget.roomId), (prev, next) {
      _scrollToBottom();
    });

    // 메시지는 watch로 UI 빌드용
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));

    return Scaffold(
      appBar: _buildAppBar(context, theme, roomAsync),
      body: Column(
        children: [
          // 메시지 영역
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, st) => Center(
                child: Text(
                  '메시지를 불러올 수 없어요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              data: (messages) => _MessageList(
                messages: messages,
                scrollController: _scrollController,
                partnerName: roomAsync.valueOrNull?.partnerName,
                partnerElement: roomAsync.valueOrNull?.partnerElementType,
                onDeleteMessage: (id) {
                  ref.read(sendMessageProvider.notifier).deleteMessage(id);
                },
              ),
            ),
          ),

          // 입력 바
          ChatInputBar(
            onSend: (text) {
              ref.read(sendMessageProvider.notifier).send(
                    roomId: widget.roomId,
                    content: text,
                  );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    AsyncValue<ChatRoom?> roomAsync,
  ) {
    final room = roomAsync.valueOrNull;

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // 상대 아바타 — SajuAvatar 디자인 시스템 컴포넌트
          if (room?.partnerElementType != null) ...[
            SajuAvatar(
              name: room!.partnerName ?? '?',
              size: SajuSize.sm,
              elementColor: SajuColor.fromElement(room.partnerElementType),
            ),
            const SizedBox(width: 10),
          ],

          // 이름 + 궁합
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                room?.partnerName ?? '채팅',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              if (room?.compatibilityScore != null)
                SajuBadge(
                  label: '궁합 ${room!.compatibilityScore}%',
                  size: SajuSize.xs,
                  color: _scoreToColor(room.compatibilityScore!),
                ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, size: 22),
          onPressed: () => _showChatMenu(context),
        ),
      ],
    );
  }

  void _showChatMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: SajuSpacing.space8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SajuSpacing.space16),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('차단'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 차단 로직
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined,
                  color: AppTheme.fireColor),
              title: Text('신고',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.fireColor,
                  )),
              onTap: () {
                Navigator.pop(context);
                // TODO: 신고 로직
              },
            ),
            const SizedBox(height: SajuSpacing.space8),
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
// 메시지 리스트
// =============================================================================

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
    this.partnerName,
    this.partnerElement,
    this.onDeleteMessage,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final String? partnerName;
  final String? partnerElement;
  final void Function(String id)? onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (messages.isEmpty) {
      return Center(
        child: Text(
          '첫 메시지를 보내보세요!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space16 * 0.75,
        vertical: SajuSpacing.space8,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prevMsg = index > 0 ? messages[index - 1] : null;
        final nextMsg =
            index < messages.length - 1 ? messages[index + 1] : null;

        // 날짜 구분선 표시 여부
        final showDate = prevMsg == null ||
            !DateFormatter.isSameDay(prevMsg.createdAt, msg.createdAt);

        // 시스템 메시지
        if (msg.isSystemMessage) {
          return Column(
            key: ValueKey(msg.id),
            children: [
              if (showDate) ChatDateDivider(date: msg.createdAt),
              ChatSystemMessage(
                text: msg.content,
                icon: Icons.favorite,
              ),
            ],
          );
        }

        final isMine = msg.isMine('current-user');

        // 그룹화: 같은 발신자 + 1분 이내
        final isGroupedWithPrev = prevMsg != null &&
            !prevMsg.isSystemMessage &&
            prevMsg.senderId == msg.senderId &&
            msg.createdAt.difference(prevMsg.createdAt).inMinutes < 1;

        final isGroupedWithNext = nextMsg != null &&
            !nextMsg.isSystemMessage &&
            nextMsg.senderId == msg.senderId &&
            nextMsg.createdAt.difference(msg.createdAt).inMinutes < 1;

        final showAvatar = !isMine && !isGroupedWithPrev;
        final showTime = !isGroupedWithNext;

        return Column(
          key: ValueKey(msg.id),
          children: [
            if (showDate) ChatDateDivider(date: msg.createdAt),
            ChatMessageBubble(
              message: msg,
              isMine: isMine,
              showAvatar: showAvatar,
              showTime: showTime,
              partnerName: partnerName,
              partnerElement: partnerElement,
              onLongPress: isMine
                  ? () => _showDeleteDialog(context, msg.id)
                  : null,
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteMessage?.call(messageId);
            },
            child: Text(
              '삭제',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.fireColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
