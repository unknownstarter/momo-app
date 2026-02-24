import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// =============================================================================
// Saju 디자인 시스템 — 공통 Enum
//
// HeroUI의 Size/Variant/Color API 패턴을 Flutter에 맞게 적용한 디자인 토큰.
// 모든 Saju 컴포넌트(SajuButton, SajuChip, SajuAvatar 등)가 이 enum들을
// 공유하여 일관된 API를 제공한다.
// =============================================================================

/// 컴포넌트 크기 — xs ~ xl 5단계
///
/// 각 사이즈는 컴포넌트의 높이, 폰트 크기, 아이콘 크기, 패딩을 결정한다.
/// 예:
/// ```dart
/// SajuButton(size: SajuSize.md, ...)
/// SajuChip(size: SajuSize.sm, ...)
/// ```
enum SajuSize {
  /// 24px — 인라인 뱃지, 미니 태그
  xs(height: 24, fontSize: 11, iconSize: 14, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2)),

  /// 32px — 칩, 소형 버튼
  sm(height: 32, fontSize: 13, iconSize: 16, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),

  /// 40px — 기본 크기 (대부분의 컴포넌트)
  md(height: 40, fontSize: 14, iconSize: 18, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),

  /// 48px — 중요 CTA, 입력 필드
  lg(height: 48, fontSize: 16, iconSize: 20, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),

  /// 56px — 메인 CTA, 풀 너비 버튼
  xl(height: 56, fontSize: 18, iconSize: 24, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14));

  const SajuSize({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.padding,
  });

  /// 컴포넌트 높이 (dp)
  final double height;

  /// 텍스트 크기 (sp)
  final double fontSize;

  /// 아이콘 크기 (dp)
  final double iconSize;

  /// 내부 여백
  final EdgeInsets padding;
}

/// 컴포넌트 스타일 변형
///
/// Material Design과 HeroUI를 참고하되, 한지 디자인 시스템에 맞게 조정.
/// 예:
/// ```dart
/// SajuButton(variant: SajuVariant.filled, ...)
/// SajuChip(variant: SajuVariant.outlined, ...)
/// ```
enum SajuVariant {
  /// 배경색이 채워진 강조 스타일 (Primary CTA)
  filled,

  /// 외곽선만 있는 스타일 (Secondary action)
  outlined,

  /// 배경/외곽선 없이 텍스트만 (Tertiary action)
  flat,

  /// 그림자가 있는 카드형 스타일 (Elevated surface)
  elevated,

  /// 배경 없이 hover/press 시에만 반응하는 스타일 (Ghost action)
  ghost,
}

/// 컴포넌트 의미 색상 — 브랜드 + 오행(五行)
///
/// 테마(라이트/다크)에 따라 적절한 Color를 반환한다.
/// [resolve]로 메인 컬러, [resolvePastel]로 파스텔 컬러를 얻는다.
///
/// 예:
/// ```dart
/// final color = SajuColor.wood.resolve(context);
/// final bg = SajuColor.wood.resolvePastel(context);
/// ```
enum SajuColor {
  /// 한지 하늘색 — 앱의 메인 브랜드 컬러
  primary,

  /// 한지 연분홍 — 보조 브랜드 컬러
  secondary,

  /// 목(木) — 수묵 초록
  wood,

  /// 화(火) — 연지 핑크
  fire,

  /// 토(土) — 황토 한지
  earth,

  /// 금(金) — 먹탄 은회
  metal,

  /// 수(水) — 쪽빛 하늘
  water;

  /// 현재 테마에 맞는 메인 컬러를 반환한다.
  ///
  /// - primary/secondary: [ColorScheme]의 primary/secondary 사용
  /// - 오행 컬러: [AppTheme]의 정적 상수 사용 (테마 불변)
  Color resolve(BuildContext context) {
    return switch (this) {
      SajuColor.primary => Theme.of(context).colorScheme.primary,
      SajuColor.secondary => Theme.of(context).colorScheme.secondary,
      SajuColor.wood => AppTheme.woodColor,
      SajuColor.fire => AppTheme.fireColor,
      SajuColor.earth => AppTheme.earthColor,
      SajuColor.metal => AppTheme.metalColor,
      SajuColor.water => AppTheme.waterColor,
    };
  }

  /// 현재 테마에 맞는 파스텔 컬러를 반환한다.
  ///
  /// 배경, 뱃지, 칩 등 은은한 색상이 필요할 때 사용.
  /// - primary/secondary: 메인 컬러의 12% 투명도 버전 사용
  /// - 오행 컬러: [AppTheme]의 파스텔 상수 사용
  Color resolvePastel(BuildContext context) {
    return switch (this) {
      SajuColor.primary =>
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      SajuColor.secondary =>
        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
      SajuColor.wood => AppTheme.woodPastel,
      SajuColor.fire => AppTheme.firePastel,
      SajuColor.earth => AppTheme.earthPastel,
      SajuColor.metal => AppTheme.metalPastel,
      SajuColor.water => AppTheme.waterPastel,
    };
  }
}
