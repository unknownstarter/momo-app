import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/saju_avatar.dart';
import '../../../../core/widgets/saju_enums.dart';
import '../../domain/entities/chat_message_entity.dart';

/// 채팅 메시지 버블 — Sendbird 기본형 스타일
///
/// [isMine]: 내 메시지면 우측, 상대 메시지면 좌측
/// [showAvatar]: 그룹화된 메시지의 첫 번째만 아바타 표시
/// [showTime]: 그룹의 마지막 메시지만 시간 표시
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = true,
    this.showTime = true,
    this.partnerName,
    this.partnerElement,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final bool showTime;
  final String? partnerName;
  final String? partnerElement;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _DeletedBubble(isMine: isMine);
    }

    if (message.isImage) {
      return _ImageBubble(
        message: message,
        isMine: isMine,
        showTime: showTime,
        onLongPress: onLongPress,
      );
    }

    return _TextBubble(
      message: message,
      isMine: isMine,
      showAvatar: showAvatar,
      showTime: showTime,
      partnerName: partnerName,
      partnerElement: partnerElement,
      onLongPress: onLongPress,
    );
  }
}

// =============================================================================
// 텍스트 버블
// =============================================================================

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.isMine,
    required this.showAvatar,
    required this.showTime,
    this.partnerName,
    this.partnerElement,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final bool showTime;
  final String? partnerName;
  final String? partnerElement;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 내 버블: primary 색상 기반 / 상대 버블: surface 색상 기반
    final bubbleColor = isMine
        ? colorScheme.primary.withValues(alpha: isDark ? 0.3 : 1.0)
        : isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface;

    final textColor = isMine
        ? (isDark ? colorScheme.onSurface : colorScheme.onPrimary)
        : colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(AppTheme.radiusLg),
      topRight: const Radius.circular(AppTheme.radiusLg),
      bottomLeft: Radius.circular(isMine ? AppTheme.radiusLg : 4),
      bottomRight: Radius.circular(isMine ? 4 : AppTheme.radiusLg),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : (showAvatar ? 0 : 36),
        right: isMine ? 0 : 60,
        bottom: showTime ? AppTheme.spacingSm : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대 아바타 — SajuAvatar 디자인 시스템 컴포넌트 사용
          if (!isMine && showAvatar) ...[
            SajuAvatar(
              name: partnerName ?? '?',
              size: SajuSize.sm,
              elementColor: SajuColor.fromElement(partnerElement),
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],

          // 시간 (내 메시지 좌측)
          if (isMine && showTime)
            _TimeLabel(time: message.createdAt, isRead: message.isRead),

          // 버블
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onLongPress?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  border: !isMine && !isDark
                      ? Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        )
                      : null,
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),

          // 시간 (상대 메시지 우측)
          if (!isMine && showTime)
            _TimeLabel(time: message.createdAt, isRead: false),
        ],
      ),
    );
  }
}

// =============================================================================
// 이미지 버블
// =============================================================================

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.message,
    required this.isMine,
    required this.showTime,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTime;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : 36,
        right: isMine ? 0 : 60,
        bottom: showTime ? AppTheme.spacingSm : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMine && showTime)
            _TimeLabel(time: message.createdAt, isRead: message.isRead),
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Image.network(
                    message.content,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 220,
                      height: 160,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!isMine && showTime)
            _TimeLabel(time: message.createdAt, isRead: false),
        ],
      ),
    );
  }
}

// =============================================================================
// 삭제된 메시지
// =============================================================================

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isMine});

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : 36,
        right: isMine ? 0 : 60,
        bottom: AppTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              '삭제된 메시지',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 시간 라벨
// =============================================================================

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.time, required this.isRead});

  final DateTime time;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRead)
            Icon(
              Icons.done_all,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          Text(
            DateFormatter.formatTime(time),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
