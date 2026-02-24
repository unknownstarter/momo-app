import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMine
        ? const Color(0xFFA8C8E8).withValues(alpha: isDark ? 0.3 : 1.0)
        : isDark
            ? const Color(0xFF35363F)
            : const Color(0xFFFEFCF9);

    final textColor = isMine
        ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
        : Theme.of(context).textTheme.bodyLarge?.color;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : (showAvatar ? 0 : 36),
        right: isMine ? 0 : 60,
        bottom: showTime ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대 아바타
          if (!isMine && showAvatar) ...[
            _PartnerAvatar(
              name: partnerName,
              element: partnerElement,
            ),
            const SizedBox(width: 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  border: !isMine && !isDark
                      ? Border.all(
                          color: const Color(0xFFE8E4DF),
                          width: 0.5,
                        )
                      : null,
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 15,
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
        bottom: showTime ? 8 : 2,
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
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Image.network(
                    message.content,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 220,
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
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
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : 36,
        right: isMine ? 0 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              '삭제된 메시지',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
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
// 공통 위젯
// =============================================================================

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({this.name, this.element});

  final String? name;
  final String? element;

  @override
  Widget build(BuildContext context) {
    final color = element != null
        ? AppTheme.fiveElementColor(element!)
        : Colors.grey;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: element != null
            ? AppTheme.fiveElementPastel(element!)
            : Colors.grey.shade200,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          name?.isNotEmpty == true ? name!.characters.first : '?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.time, required this.isRead});

  final DateTime time;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRead)
            Icon(
              Icons.done_all,
              size: 14,
              color: const Color(0xFFA8C8E8),
            ),
          Text(
            '$amPm $displayHour:$minute',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
