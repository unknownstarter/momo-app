import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';

/// 채팅 입력 바 — Sendbird 기본형 스타일
///
/// 텍스트 입력 + 전송 버튼 + 이미지 첨부 버튼
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onImageTap,
    this.enabled = true,
  });

  final void Function(String text) onSend;
  final VoidCallback? onImageTap;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(SajuSpacing.space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 이미지 첨부 버튼
              IconButton(
                onPressed: widget.enabled ? widget.onImageTap : null,
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colorScheme.outline,
                  size: 24,
                ),
                padding: const EdgeInsets.all(SajuSpacing.space8),
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: SajuSpacing.space4),

              // 텍스트 입력
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    maxLines: null,
                    maxLength: 1000,
                    textInputAction: TextInputAction.newline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SajuSpacing.space16,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: SajuSpacing.space4),

              // 전송 버튼
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hasText ? 1.0 : 0.4,
                child: IconButton(
                  onPressed:
                      _hasText && widget.enabled ? _handleSend : null,
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasText
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
