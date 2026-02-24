import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// SajuButton — 사주 디자인 시스템 버튼 컴포넌트
///
/// HeroUI의 일관된 API 패턴(size/variant/color)을 따르며,
/// 한지 팔레트 디자인 시스템에 맞춰 스타일링된다.
///
/// ```dart
/// SajuButton(
///   label: '좋아요 보내기',
///   onPressed: () {},
///   variant: SajuVariant.filled,
///   color: SajuColor.fire,
///   size: SajuSize.lg,
///   leadingIcon: Icons.favorite,
///   isLoading: false,
///   expand: true,
/// )
/// ```
class SajuButton extends StatelessWidget {
  const SajuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SajuVariant.filled,
    this.color = SajuColor.primary,
    this.size = SajuSize.md,
    this.leadingIcon,
    this.isLoading = false,
    this.expand = true,
  });

  /// 버튼에 표시할 텍스트
  final String label;

  /// 탭 콜백. null이면 버튼이 비활성 상태가 된다.
  final VoidCallback? onPressed;

  /// 버튼 스타일 변형 (filled, outlined, flat, elevated, ghost)
  final SajuVariant variant;

  /// 버튼 의미 색상 (primary, secondary, 오행 컬러)
  final SajuColor color;

  /// 버튼 크기 (xs ~ xl)
  final SajuSize size;

  /// 라벨 앞에 표시할 아이콘 (선택)
  final IconData? leadingIcon;

  /// 로딩 상태. true이면 스피너를 표시하고 탭을 비활성화한다.
  final bool isLoading;

  /// true이면 가로 전체 너비, false이면 shrink-wrap
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color.resolve(context);
    final effectiveOnPressed = (isLoading || onPressed == null) ? null : onPressed;

    final child = _buildChild(context, resolvedColor);

    final buttonStyle = _buildButtonStyle(context, resolvedColor);

    Widget button;

    switch (variant) {
      case SajuVariant.filled:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
      case SajuVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
      case SajuVariant.flat:
      case SajuVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
      case SajuVariant.elevated:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
    }

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: size.height,
        child: button,
      );
    }

    return SizedBox(
      height: size.height,
      child: button,
    );
  }

  /// 버튼 내부 콘텐츠 (아이콘 + 라벨 or 로딩 스피너)
  Widget _buildChild(BuildContext context, Color resolvedColor) {
    final textStyle = TextStyle(
      fontSize: size.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );

    if (isLoading) {
      final spinnerColor = _foregroundColor(context, resolvedColor);
      return SizedBox(
        width: size.iconSize,
        height: size.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    }

    if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: size.iconSize),
          SizedBox(width: size.fontSize * 0.5),
          Text(label, style: textStyle),
        ],
      );
    }

    return Text(label, style: textStyle);
  }

  /// variant에 따른 전경색(텍스트/아이콘 컬러) 결정
  Color _foregroundColor(BuildContext context, Color resolvedColor) {
    return switch (variant) {
      SajuVariant.filled => Colors.white,
      SajuVariant.outlined => resolvedColor,
      SajuVariant.flat => resolvedColor,
      SajuVariant.elevated => resolvedColor,
      SajuVariant.ghost => resolvedColor,
    };
  }

  /// variant에 따른 ButtonStyle 생성
  ButtonStyle _buildButtonStyle(BuildContext context, Color resolvedColor) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusMd);
    final foreground = _foregroundColor(context, resolvedColor);
    final textStyle = TextStyle(
      fontSize: size.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );

    final minimumSize = expand
        ? Size(double.infinity, size.height)
        : Size(0, size.height);

    final shape = RoundedRectangleBorder(borderRadius: borderRadius);

    switch (variant) {
      case SajuVariant.filled:
        return ElevatedButton.styleFrom(
          backgroundColor: resolvedColor,
          foregroundColor: foreground,
          minimumSize: minimumSize,
          padding: size.padding,
          shape: shape,
          textStyle: textStyle,
          elevation: 0,
        );

      case SajuVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: minimumSize,
          padding: size.padding,
          shape: shape.copyWith(
            side: BorderSide(color: resolvedColor, width: 1.5),
          ),
          side: BorderSide(color: resolvedColor, width: 1.5),
          textStyle: textStyle,
        );

      case SajuVariant.flat:
        return TextButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: minimumSize,
          padding: size.padding,
          shape: shape,
          textStyle: textStyle,
        );

      case SajuVariant.elevated:
        final surfaceColor = Theme.of(context).colorScheme.surface;
        return ElevatedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: foreground,
          minimumSize: minimumSize,
          padding: size.padding,
          shape: shape,
          textStyle: textStyle,
          elevation: 2,
          shadowColor: resolvedColor.withValues(alpha: 0.3),
        );

      case SajuVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: minimumSize,
          padding: size.padding,
          shape: shape,
          textStyle: textStyle,
          backgroundColor: Colors.transparent,
        );
    }
  }
}
