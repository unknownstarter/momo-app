import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 프로필 이미지 + 오행 뱃지를 표시하는 아바타 컴포넌트
///
/// 한지 디자인 시스템에 맞게 원형 아바타를 렌더링하며,
/// 오행 원소 색상 테두리, 원소 뱃지 도트, 알림 뱃지를 지원한다.
///
/// ```dart
/// SajuAvatar(
///   name: '김사주',
///   imageUrl: 'https://example.com/photo.jpg',
///   size: SajuSize.md,
///   elementColor: SajuColor.fire,
///   showBadge: false,
///   badgeCount: 3,
/// )
/// ```
class SajuAvatar extends StatelessWidget {
  const SajuAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.characterAsset,
    this.size = SajuSize.md,
    this.elementColor,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  /// 사용자 이름 — 이미지가 없을 때 첫 글자를 폴백으로 표시
  final String name;

  /// 네트워크 프로필 이미지 URL (optional)
  final String? imageUrl;

  /// 캐릭터 오버레이 에셋 경로 (optional)
  final String? characterAsset;

  /// 아바타 크기 (기본값: md, 40px)
  final SajuSize size;

  /// 오행 원소 색상 — 지정 시 색상 테두리 + 하단 우측 도트 뱃지 표시
  final SajuColor? elementColor;

  /// 알림 뱃지 표시 여부 (상단 우측)
  final bool showBadge;

  /// 알림 뱃지 숫자 — 0보다 크면 자동으로 뱃지 표시, 99 초과 시 "99+"
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final dimension = size.height;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 메인 원형 아바타
          _buildMainCircle(context, dimension),

          // 오행 원소 도트 뱃지 (하단 우측)
          if (elementColor != null)
            _buildElementDot(context, dimension, scaffoldBg),

          // 알림 뱃지 (상단 우측)
          if (showBadge || badgeCount > 0)
            _buildNotificationBadge(dimension),
        ],
      ),
    );
  }

  /// 메인 원형 아바타 — 이미지 또는 이니셜 폴백
  Widget _buildMainCircle(BuildContext context, double dimension) {
    final resolvedElementColor = elementColor?.resolve(context);

    // 오행 색상이 있을 때 테두리 추가 (2px, alpha 0.4)
    final border = resolvedElementColor != null
        ? Border.all(
            color: resolvedElementColor.withValues(alpha: 0.4),
            width: 2,
          )
        : null;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
        color: _fallbackBackgroundColor(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(context, dimension),
    );
  }

  /// 아바타 내부 콘텐츠 — 이미지 > 캐릭터 에셋 > 이니셜 폴백
  Widget _buildContent(BuildContext context, double dimension) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: dimension,
        height: dimension,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitials(context, dimension),
      );
    }

    if (characterAsset != null && characterAsset!.isNotEmpty) {
      return Image.asset(
        characterAsset!,
        width: dimension,
        height: dimension,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitials(context, dimension),
      );
    }

    return _buildInitials(context, dimension);
  }

  /// 이니셜 폴백 — 이름의 첫 글자를 원 안에 표시
  Widget _buildInitials(BuildContext context, double dimension) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final fontSize = dimension * 0.4;

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// 폴백 배경색 — 이미지가 없을 때의 원형 배경
  Color _fallbackBackgroundColor(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Colors.transparent;
    }

    // 오행 색상이 있으면 파스텔 배경 사용
    if (elementColor != null) {
      return elementColor!.resolvePastel(context);
    }

    // 기본: 테마 서피스 색상
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// 오행 원소 도트 뱃지 — 하단 우측 작은 원
  Widget _buildElementDot(
    BuildContext context,
    double dimension,
    Color scaffoldBg,
  ) {
    final dotSize = dimension * 0.35;
    final resolvedColor = elementColor!.resolve(context);

    return Positioned(
      right: -1,
      bottom: -1,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: resolvedColor,
          border: Border.all(
            color: scaffoldBg,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// 알림 뱃지 — 상단 우측
  Widget _buildNotificationBadge(double dimension) {
    final hasCount = badgeCount > 0;
    final badgeText = badgeCount > 99 ? '99+' : '$badgeCount';

    // 숫자가 없으면 작은 도트, 있으면 숫자 뱃지
    final badgeSize = hasCount ? dimension * 0.4 : dimension * 0.25;
    final minWidth = hasCount ? badgeSize : badgeSize;

    return Positioned(
      right: hasCount ? -4 : 0,
      top: hasCount ? -4 : 0,
      child: Container(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: badgeSize,
        ),
        padding: hasCount
            ? const EdgeInsets.symmetric(horizontal: 3)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: AppTheme.fireColor,
          borderRadius: BorderRadius.circular(badgeSize / 2),
        ),
        alignment: Alignment.center,
        child: hasCount
            ? Text(
                badgeText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dimension * 0.2,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              )
            : null,
      ),
    );
  }
}
