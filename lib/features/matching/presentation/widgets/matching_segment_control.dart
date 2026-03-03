import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Pill-style 3분할 세그먼트 컨트롤
///
/// ```
/// [ 추천 ]  [ 보낸 ]  [ 받은 ② ]
/// ```
///
/// 각 세그먼트에 선택적 뱃지 카운트를 표시할 수 있다.
class MatchingSegmentControl extends StatelessWidget {
  const MatchingSegmentControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.recommendationBadge,
    this.receivedBadge,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// 추천 탭 뱃지 (미조회 수)
  final int? recommendationBadge;

  /// 받은 탭 뱃지 (pending 수)
  final int? receivedBadge;

  static const _labels = ['추천', '보낸', '받은'];

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = selectedIndex == index;
          final badge = switch (index) {
            0 => recommendationBadge,
            2 => receivedBadge,
            _ => null,
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.bgElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _labels[index],
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                    ),
                    if (badge != null && badge > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.fireColor.withValues(alpha: 0.85),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
