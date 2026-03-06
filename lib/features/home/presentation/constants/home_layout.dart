import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/saju_spacing.dart';

/// 홈 스크린 레이아웃 상수
///
/// 모든 매직 넘버를 이곳에 집중. 4px 그리드 기반.
/// [SajuSpacing] 토큰을 재사용하되, 홈 전용 값은 여기서 정의.
abstract final class HomeLayout {
  // ── Screen ──
  static const screenPadding = SajuSpacing.page; // 좌우 20px
  static const screenTopInset = SajuSpacing.space20; // SafeArea 아래 여백

  // ── Section gaps (섹션 간 간격) ──
  static const sectionGap = SajuSpacing.space32; // 모든 섹션 간 동일 32px

  // ── Section internals (헤더 → 콘텐츠) ──
  static const headerContentGap = 14.0; // 섹션 헤더 → 콘텐츠 간격

  // ── Grid ──
  static const gridCrossAxisCount = 2;
  static const gridSpacing = 14.0; // cross + main axis spacing
  static const gridChildAspectRatio = 0.72;
  static const gridMaxItems = 6; // 2열 × 3행

  // ── Section-specific max items ──
  static const destinyMaxItems = 5;
  static const compatMaxItems = 6; // 2열 × 3행
  static const gwansangMaxItems = 4;
  static const newUsersMaxItems = 4;

  // ── Animation stagger ──
  static const sectionStaggerMs = 100; // 섹션 간 등장 딜레이

  // ── Bottom safe area ──
  /// 플로팅 네비바 높이 + 하단 안전 영역
  static double bottomInset(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + 88;

  // ── SizedBox presets ──
  static const gapSection = SizedBox(height: sectionGap);
  static const gapHeaderContent = SizedBox(height: headerContentGap);
}
