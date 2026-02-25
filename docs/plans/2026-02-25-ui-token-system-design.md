# UI Token System Design — ThemeExtension 기반

> **작성일**: 2026-02-25
> **목적**: production-ui-system.md에 정의된 디자인 토큰을 Flutter ThemeExtension으로 체계적 구현
> **참조**: `docs/plans/2026-02-25-production-ui-system.md`

---

## 1. 파일 구조

```
lib/core/theme/
├── app_theme.dart              ← 기존 (ThemeExtension 등록 추가)
├── tokens/
│   ├── saju_colors.dart        ← ThemeExtension<SajuColors>
│   ├── saju_typography.dart    ← ThemeExtension<SajuTypography>
│   ├── saju_elevation.dart     ← ThemeExtension<SajuElevation>
│   ├── saju_spacing.dart       ← static const (테마 불변)
│   └── saju_animation.dart     ← static const (테마 불변)
└── theme_extensions.dart       ← BuildContext extension
```

## 2. ThemeExtension 여부

| 항목 | ThemeExtension | 이유 |
|------|:-:|------|
| Colors | O | 라이트/다크 값이 다름 |
| Typography | O | 텍스트 색상이 테마에 따라 다름 |
| Elevation | O | 라이트=섀도, 다크=보더+글로우 |
| Spacing | X (static) | 테마 무관 |
| Animation | X (static) | 테마 무관 |

## 3. SajuColors

production-ui-system.md §4 Color Token System 1:1 매핑.

```dart
class SajuColors extends ThemeExtension<SajuColors> {
  // Backgrounds
  final Color bgPrimary;      // Light: #F7F3EE ↔ Dark: #1D1E23
  final Color bgSecondary;    // Light: #F0EDE8 ↔ Dark: #2A2B32
  final Color bgElevated;     // Light: #FEFCF9 ↔ Dark: #35363F

  // Text
  final Color textPrimary;    // Light: #2D2D2D ↔ Dark: #E8E4DF
  final Color textSecondary;  // Light: #6B6B6B ↔ Dark: #A09B94
  final Color textTertiary;   // Light: #A0A0A0 ↔ Dark: #6B6B6B
  final Color textInverse;    // Light: #FEFCF9 ↔ Dark: #2D2D2D

  // Border
  final Color borderDefault;  // Light: #E8E4DF ↔ Dark: #35363F
  final Color borderFocus;    // Light: #A8C8E8 ↔ Dark: #A8C8E8@60%

  // Fill
  final Color fillBrand;      // #A8C8E8 (both)
  final Color fillAccent;     // #F2D0D5 (both)
  final Color fillDisabled;   // Light: #E8E4DF ↔ Dark: #35363F

  // Fixed (same both modes) — 기존 AppTheme static 유지
  // element.wood/fire/earth/metal/water
  // compat.excellent/good/normal/low
  // mystic.glow/accent
  // status.success/error/warning
}
```

## 4. SajuTypography

production-ui-system.md §3 Typography Scale 1:1 매핑.
Pretendard, 색상은 테마에 따라 자동 전환.

```dart
class SajuTypography extends ThemeExtension<SajuTypography> {
  final TextStyle hero;       // 48px Bold, h1.1, ls-1.5 — 궁합 점수
  final TextStyle display1;   // 32px Bold, h1.2, ls-0.8 — 페이지 타이틀
  final TextStyle display2;   // 24px SemiBold, h1.25, ls-0.4 — 사주 결과
  final TextStyle heading1;   // 20px SemiBold, h1.35, ls-0.3 — 섹션 제목
  final TextStyle heading2;   // 17px SemiBold, h1.4, ls-0.2 — 카드 제목
  final TextStyle heading3;   // 15px SemiBold, h1.4, ls-0.1 — 서브섹션
  final TextStyle body1;      // 16px Regular, h1.55, ls0 — 본문
  final TextStyle body2;      // 14px Regular, h1.5, ls0 — 보조 본문
  final TextStyle caption1;   // 13px Medium, h1.4, ls0 — 라벨
  final TextStyle caption2;   // 12px Medium, h1.35, ls0 — 메타데이터
  final TextStyle overline;   // 11px Medium, h1.3, ls0.2 — 뱃지
}
```

## 5. SajuElevation

production-ui-system.md §5 1:1 매핑.

```dart
class SajuElevation extends ThemeExtension<SajuElevation> {
  final BoxDecoration flat;
  final BoxDecoration low;      // Light: shadow ↔ Dark: border
  final BoxDecoration medium;   // Light: shadow ↔ Dark: border
  final BoxDecoration high;     // Light: shadow ↔ Dark: border + glow
  final BoxDecoration mystic;   // Dark only: warm gold glow
}
```

## 6. SajuSpacing (static)

기존 AppTheme.space* 토큰을 전용 클래스로 이동. 추가로 EdgeInsets 프리셋.

```dart
abstract final class SajuSpacing {
  static const space2 = 2.0;
  // ... space4~space64

  // EdgeInsets presets
  static const page = EdgeInsets.symmetric(horizontal: 20);
  static const cardInner = EdgeInsets.all(16);
  static const sectionGap = SizedBox(height: 24);
}
```

## 7. SajuAnimation (static)

production-ui-system.md §7 Interaction Feedback 기반.

```dart
abstract final class SajuAnimation {
  static const fast = Duration(milliseconds: 100);     // tap feedback
  static const normal = Duration(milliseconds: 200);   // tab switch
  static const slow = Duration(milliseconds: 300);     // page transition
  static const reveal = Duration(milliseconds: 1800);  // score reveal

  static const entrance = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const bounce = Curves.elasticOut;
}
```

## 8. BuildContext Extension

```dart
extension SajuThemeX on BuildContext {
  SajuColors get sajuColors => Theme.of(this).extension<SajuColors>()!;
  SajuTypography get sajuTypo => Theme.of(this).extension<SajuTypography>()!;
  SajuElevation get sajuElevation => Theme.of(this).extension<SajuElevation>()!;
}
```

## 9. 마이그레이션 전략

- 기존 AppTheme static 컬러/타이포 → `@Deprecated` 마킹, 당분간 유지
- 새 코드는 반드시 context.sajuColors / context.sajuTypo 사용
- 기존 위젯 하드코딩 값 → 토큰으로 순차 교체
- Five element / compatibility / status 컬러는 테마 불변이므로 AppTheme static 유지
