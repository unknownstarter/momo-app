import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens/saju_animation.dart';
import '../theme/tokens/saju_spacing.dart';
import 'saju_enums.dart';

/// 오행 태그, 관심사, 성격 특성 등을 표시하는 칩 컴포넌트
///
/// 한지 디자인 시스템의 파스텔 톤을 기반으로 동작하며,
/// 선택/비선택 상태와 삭제 기능을 지원한다.
///
/// ```dart
/// SajuChip(
///   label: '목(木)',
///   color: SajuColor.wood,
///   size: SajuSize.sm,
///   leadingIcon: Icons.park,
///   isSelected: true,
///   onTap: () {},
/// )
/// ```
class SajuChip extends StatelessWidget {
  const SajuChip({
    super.key,
    required this.label,
    this.color,
    this.size = SajuSize.sm,
    this.leadingIcon,
    this.onTap,
    this.isSelected = false,
    this.onDeleted,
  });

  /// 칩에 표시할 텍스트
  final String label;

  /// 칩의 의미 색상 (미지정 시 primary)
  final SajuColor? color;

  /// 칩 크기 (기본값: sm)
  final SajuSize size;

  /// 라벨 왼쪽에 표시할 아이콘 (optional)
  final IconData? leadingIcon;

  /// 칩 탭 콜백 (optional)
  final VoidCallback? onTap;

  /// 선택 상태 여부 — true일 때 테두리와 배경이 강조됨
  final bool isSelected;

  /// 삭제 콜백 — 지정 시 오른쪽에 X 아이콘이 표시됨
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? SajuColor.primary;
    final resolvedColor = effectiveColor.resolve(context);
    final pastelColor = effectiveColor.resolvePastel(context);

    // 배경색: 일반 = pastel alpha 0.5, 선택 = resolved alpha 0.15
    final backgroundColor = isSelected
        ? resolvedColor.withValues(alpha: 0.15)
        : pastelColor.withValues(alpha: 0.5);

    // 테두리: 선택 시에만 표시
    final border = isSelected
        ? Border.all(color: resolvedColor, width: 1.5)
        : null;

    // 텍스트 스타일 — 밝은 오행 색상(earth 등)은 라이트 배경에서 안 보이므로
    // HSL 명도를 0.35 이하로 강제하여 가독성 확보
    Color chipTextColor;
    if (isSelected) {
      final hsl = HSLColor.fromColor(resolvedColor);
      chipTextColor = hsl.lightness > 0.45
          ? hsl.withLightness(0.35).withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0)).toColor()
          : resolvedColor;
    } else {
      chipTextColor = Theme.of(context).colorScheme.onSurface;
    }
    final textColor = chipTextColor;
    final textStyle = TextStyle(
      fontSize: size.fontSize,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: textColor,
    );

    // 아이콘 크기 — SajuSize의 iconSize 그대로 사용하면 너무 크므로
    // fontSize 기반으로 약간 키운 값 사용
    final chipIconSize = size.fontSize + 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SajuAnimation.normal,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: size.padding.horizontal / 2,
          vertical: size.padding.vertical / 2,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Leading icon
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: chipIconSize,
                color: isSelected ? resolvedColor : textColor,
              ),
              SajuSpacing.hGap4,
            ],

            // Label
            Text(label, style: textStyle),

            // Delete icon
            if (onDeleted != null) ...[
              SajuSpacing.hGap4,
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: chipIconSize,
                  color: isSelected ? resolvedColor : textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
