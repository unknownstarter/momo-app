import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// SajuCard — 사주 디자인 시스템 카드 컴포넌트
///
/// HeroUI의 Header/Content/Footer 패턴을 따르며,
/// 한지 팔레트 디자인 시스템에 맞춰 스타일링된다.
///
/// ```dart
/// SajuCard(
///   header: Text('헤더'),
///   content: Text('본문'),
///   footer: Text('푸터'),
///   variant: SajuVariant.elevated,
///   onTap: () {},
///   padding: EdgeInsets.all(16),
///   borderColor: Colors.red,
/// )
/// ```
class SajuCard extends StatelessWidget {
  const SajuCard({
    super.key,
    this.header,
    required this.content,
    this.footer,
    this.variant = SajuVariant.elevated,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  /// 카드 상단 위젯 (선택)
  final Widget? header;

  /// 카드 본문 위젯 (필수)
  final Widget content;

  /// 카드 하단 위젯 (선택)
  final Widget? footer;

  /// 카드 스타일 변형 (filled, outlined, flat, elevated, ghost)
  final SajuVariant variant;

  /// 탭 콜백 (선택). null이면 탭 이벤트를 처리하지 않는다.
  final VoidCallback? onTap;

  /// 내부 여백. 기본값: `EdgeInsets.all(16)`
  final EdgeInsets padding;

  /// 외곽선 색상 (선택). 지정 시 해당 색상의 border가 추가된다.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: padding,
        decoration: _buildDecoration(isDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: AppTheme.spacingSm),
            ],
            content,
            if (footer != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  /// variant와 테마에 따른 BoxDecoration 생성
  BoxDecoration _buildDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusLg);

    switch (variant) {
      case SajuVariant.filled:
        return BoxDecoration(
          color: isDark ? const Color(0xFF35363F) : Colors.white,
          borderRadius: borderRadius,
          border: _resolveBorder(isDark),
        );

      case SajuVariant.outlined:
        final defaultBorderColor = isDark
            ? const Color(0xFF45464F)
            : const Color(0xFFE8E4DF);
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1)
              : Border.all(color: defaultBorderColor, width: 1),
        );

      case SajuVariant.elevated:
        return BoxDecoration(
          color: isDark ? const Color(0xFF35363F) : Colors.white,
          borderRadius: borderRadius,
          border: _resolveBorder(isDark),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case SajuVariant.flat:
      case SajuVariant.ghost:
        return BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: borderRadius,
          border: _resolveBorder(isDark),
        );
    }
  }

  /// borderColor가 지정된 경우 해당 색상의 border를 반환,
  /// 그렇지 않으면 null (outlined 제외)
  Border? _resolveBorder(bool isDark) {
    if (borderColor != null) {
      return Border.all(color: borderColor!, width: 1);
    }
    return null;
  }
}
