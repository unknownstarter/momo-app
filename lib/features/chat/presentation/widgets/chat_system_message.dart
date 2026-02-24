import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 시스템 메시지 — 매칭 알림, 날짜 구분 등
class ChatSystemMessage extends StatelessWidget {
  const ChatSystemMessage({
    super.key,
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: AppTheme.mysticGlow,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.4),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 날짜 구분선
class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = '오늘';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = '어제';
    } else if (date.year == now.year) {
      label = '${date.month}월 ${date.day}일';
    } else {
      label = '${date.year}년 ${date.month}월 ${date.day}일';
    }

    return ChatSystemMessage(text: label);
  }
}
