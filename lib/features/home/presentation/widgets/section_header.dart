import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 홈 섹션 헤더 — 타이틀 + 선택적 액션 + 선택적 카운트 뱃지
///
/// ```
/// 궁합 매칭 추천 이성          더보기 >
/// 받은 좋아요  ③
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.badgeCount,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(title, style: textTheme.titleLarge),
        if (badgeCount != null && badgeCount! > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppTheme.fireColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
