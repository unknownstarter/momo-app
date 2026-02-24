import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 알림/상태 뱃지 — 궁합 등급, 새 메시지, 프리미엄 표시 등
///
/// ```dart
/// SajuBadge(
///   label: '천생연분',
///   color: SajuColor.fire,
///   icon: Icons.favorite,
/// )
/// ```
class SajuBadge extends StatelessWidget {
  const SajuBadge({
    super.key,
    required this.label,
    this.color = SajuColor.primary,
    this.size = SajuSize.sm,
    this.icon,
  });

  final String label;
  final SajuColor color;
  final SajuSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color.resolve(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.padding.horizontal / 2,
        vertical: size.padding.vertical / 3,
      ),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size.iconSize * 0.7, color: resolvedColor),
            SizedBox(width: size.padding.horizontal / 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: size.fontSize * 0.85,
              fontWeight: FontWeight.w600,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }
}
