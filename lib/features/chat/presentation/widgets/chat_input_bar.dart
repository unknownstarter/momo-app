import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E23) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF35363F) : const Color(0xFFE8E4DF),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 이미지 첨부 버튼
              IconButton(
                onPressed: widget.enabled ? widget.onImageTap : null,
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade500,
                  size: 24,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 4),

              // 텍스트 입력
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2B32)
                        : const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    maxLines: null,
                    maxLength: 1000,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

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
                          ? const Color(0xFFA8C8E8)
                          : Colors.grey.shade300,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
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
