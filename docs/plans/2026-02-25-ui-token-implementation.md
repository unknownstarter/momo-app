# UI Token System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** production-ui-system.md의 디자인 토큰을 Flutter ThemeExtension으로 구현하여, 모든 위젯이 `context.sajuColors` / `context.sajuTypo` 등으로 테마 토큰에 접근하도록 한다.

**Architecture:** ThemeExtension 3개(SajuColors, SajuTypography, SajuElevation) + static 클래스 2개(SajuSpacing, SajuAnimation) + BuildContext extension. app_theme.dart의 light/dark ThemeData에 extensions로 등록. 기존 AppTheme static 값은 deprecated 마킹 후 유지.

**Tech Stack:** Flutter 3.38+, Dart ThemeExtension API

**Design doc:** `docs/plans/2026-02-25-ui-token-system-design.md`
**Token spec:** `docs/plans/2026-02-25-production-ui-system.md`

---

### Task 1: SajuColors ThemeExtension

**Files:**
- Create: `lib/core/theme/tokens/saju_colors.dart`

**Step 1: Create SajuColors class**

```dart
import 'package:flutter/material.dart';

/// 시멘틱 컬러 토큰 — 라이트/다크 자동 전환
///
/// production-ui-system.md §4 Color Token System 1:1 매핑.
/// 사용: `context.sajuColors.bgPrimary`
class SajuColors extends ThemeExtension<SajuColors> {
  const SajuColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.borderDefault,
    required this.borderFocus,
    required this.fillBrand,
    required this.fillAccent,
    required this.fillDisabled,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color borderDefault;
  final Color borderFocus;
  final Color fillBrand;
  final Color fillAccent;
  final Color fillDisabled;

  /// 라이트 모드 (한지 톤)
  static const light = SajuColors(
    bgPrimary: Color(0xFFF7F3EE),
    bgSecondary: Color(0xFFF0EDE8),
    bgElevated: Color(0xFFFEFCF9),
    textPrimary: Color(0xFF2D2D2D),
    textSecondary: Color(0xFF6B6B6B),
    textTertiary: Color(0xFFA0A0A0),
    textInverse: Color(0xFFFEFCF9),
    borderDefault: Color(0xFFE8E4DF),
    borderFocus: Color(0xFFA8C8E8),
    fillBrand: Color(0xFFA8C8E8),
    fillAccent: Color(0xFFF2D0D5),
    fillDisabled: Color(0xFFE8E4DF),
  );

  /// 다크 모드 (먹색 톤)
  static const dark = SajuColors(
    bgPrimary: Color(0xFF1D1E23),
    bgSecondary: Color(0xFF2A2B32),
    bgElevated: Color(0xFF35363F),
    textPrimary: Color(0xFFE8E4DF),
    textSecondary: Color(0xFFA09B94),
    textTertiary: Color(0xFF6B6B6B),
    textInverse: Color(0xFF2D2D2D),
    borderDefault: Color(0xFF35363F),
    borderFocus: Color(0x99A8C8E8), // #A8C8E8 @ 60%
    fillBrand: Color(0xFFA8C8E8),
    fillAccent: Color(0xFFF2D0D5),
    fillDisabled: Color(0xFF35363F),
  );

  @override
  SajuColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? borderDefault,
    Color? borderFocus,
    Color? fillBrand,
    Color? fillAccent,
    Color? fillDisabled,
  }) {
    return SajuColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocus: borderFocus ?? this.borderFocus,
      fillBrand: fillBrand ?? this.fillBrand,
      fillAccent: fillAccent ?? this.fillAccent,
      fillDisabled: fillDisabled ?? this.fillDisabled,
    );
  }

  @override
  SajuColors lerp(SajuColors? other, double t) {
    if (other is! SajuColors) return this;
    return SajuColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      fillBrand: Color.lerp(fillBrand, other.fillBrand, t)!,
      fillAccent: Color.lerp(fillAccent, other.fillAccent, t)!,
      fillDisabled: Color.lerp(fillDisabled, other.fillDisabled, t)!,
    );
  }
}
```

**Step 2: Verify file compiles**

Run: `cd /Users/noah/saju-app && dart analyze lib/core/theme/tokens/saju_colors.dart`
Expected: No errors

**Step 3: Commit**

```bash
git add lib/core/theme/tokens/saju_colors.dart
git commit -m "feat: SajuColors ThemeExtension 추가 (라이트/다크 시멘틱 컬러 토큰)"
```

---

### Task 2: SajuTypography ThemeExtension

**Files:**
- Create: `lib/core/theme/tokens/saju_typography.dart`

**Step 1: Create SajuTypography class**

```dart
import 'package:flutter/material.dart';

/// 시멘틱 타이포그래피 토큰 — Pretendard 기반
///
/// production-ui-system.md §3 Typography Scale 1:1 매핑.
/// 사용: `context.sajuTypo.heading1`
class SajuTypography extends ThemeExtension<SajuTypography> {
  const SajuTypography({
    required this.hero,
    required this.display1,
    required this.display2,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.body1,
    required this.body2,
    required this.caption1,
    required this.caption2,
    required this.overline,
  });

  final TextStyle hero;
  final TextStyle display1;
  final TextStyle display2;
  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle heading3;
  final TextStyle body1;
  final TextStyle body2;
  final TextStyle caption1;
  final TextStyle caption2;
  final TextStyle overline;

  static const _font = 'Pretendard';

  /// 라이트 모드
  static const light = SajuTypography(
    hero: TextStyle(fontFamily: _font, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1.5, color: Color(0xFF2D2D2D)),
    display1: TextStyle(fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.8, color: Color(0xFF2D2D2D)),
    display2: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.4, color: Color(0xFF2D2D2D)),
    heading1: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: -0.3, color: Color(0xFF2D2D2D)),
    heading2: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.2, color: Color(0xFF2D2D2D)),
    heading3: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.1, color: Color(0xFF2D2D2D)),
    body1: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400, height: 1.55, letterSpacing: 0, color: Color(0xFF2D2D2D)),
    body2: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0, color: Color(0xFF2D2D2D)),
    caption1: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0, color: Color(0xFF6B6B6B)),
    caption2: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35, letterSpacing: 0, color: Color(0xFF6B6B6B)),
    overline: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.2, color: Color(0xFF6B6B6B)),
  );

  /// 다크 모드
  static const dark = SajuTypography(
    hero: TextStyle(fontFamily: _font, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1.5, color: Color(0xFFE8E4DF)),
    display1: TextStyle(fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.8, color: Color(0xFFE8E4DF)),
    display2: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.4, color: Color(0xFFE8E4DF)),
    heading1: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: -0.3, color: Color(0xFFE8E4DF)),
    heading2: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.2, color: Color(0xFFE8E4DF)),
    heading3: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.1, color: Color(0xFFE8E4DF)),
    body1: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400, height: 1.55, letterSpacing: 0, color: Color(0xFFE8E4DF)),
    body2: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0, color: Color(0xFFE8E4DF)),
    caption1: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0, color: Color(0xFFA09B94)),
    caption2: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35, letterSpacing: 0, color: Color(0xFFA09B94)),
    overline: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.2, color: Color(0xFFA09B94)),
  );

  @override
  SajuTypography copyWith({
    TextStyle? hero,
    TextStyle? display1,
    TextStyle? display2,
    TextStyle? heading1,
    TextStyle? heading2,
    TextStyle? heading3,
    TextStyle? body1,
    TextStyle? body2,
    TextStyle? caption1,
    TextStyle? caption2,
    TextStyle? overline,
  }) {
    return SajuTypography(
      hero: hero ?? this.hero,
      display1: display1 ?? this.display1,
      display2: display2 ?? this.display2,
      heading1: heading1 ?? this.heading1,
      heading2: heading2 ?? this.heading2,
      heading3: heading3 ?? this.heading3,
      body1: body1 ?? this.body1,
      body2: body2 ?? this.body2,
      caption1: caption1 ?? this.caption1,
      caption2: caption2 ?? this.caption2,
      overline: overline ?? this.overline,
    );
  }

  @override
  SajuTypography lerp(SajuTypography? other, double t) {
    if (other is! SajuTypography) return this;
    return SajuTypography(
      hero: TextStyle.lerp(hero, other.hero, t)!,
      display1: TextStyle.lerp(display1, other.display1, t)!,
      display2: TextStyle.lerp(display2, other.display2, t)!,
      heading1: TextStyle.lerp(heading1, other.heading1, t)!,
      heading2: TextStyle.lerp(heading2, other.heading2, t)!,
      heading3: TextStyle.lerp(heading3, other.heading3, t)!,
      body1: TextStyle.lerp(body1, other.body1, t)!,
      body2: TextStyle.lerp(body2, other.body2, t)!,
      caption1: TextStyle.lerp(caption1, other.caption1, t)!,
      caption2: TextStyle.lerp(caption2, other.caption2, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
    );
  }
}
```

**Step 2: Verify file compiles**

Run: `cd /Users/noah/saju-app && dart analyze lib/core/theme/tokens/saju_typography.dart`
Expected: No errors

**Step 3: Commit**

```bash
git add lib/core/theme/tokens/saju_typography.dart
git commit -m "feat: SajuTypography ThemeExtension 추가 (Pretendard 시멘틱 타이포 토큰)"
```

---

### Task 3: SajuElevation ThemeExtension

**Files:**
- Create: `lib/core/theme/tokens/saju_elevation.dart`

**Step 1: Create SajuElevation class**

```dart
import 'package:flutter/material.dart';

/// 엘리베이션 토큰 — 라이트는 섀도, 다크는 보더+글로우
///
/// production-ui-system.md §5 Elevation System 매핑.
/// 사용: `context.sajuElevation.medium`
class SajuElevation extends ThemeExtension<SajuElevation> {
  const SajuElevation({
    required this.lowShadow,
    required this.mediumShadow,
    required this.highShadow,
    required this.mysticShadow,
    required this.cardBorder,
  });

  /// 리스트 아이템, 칩
  final List<BoxShadow> lowShadow;

  /// 카드, 다이얼로그
  final List<BoxShadow> mediumShadow;

  /// 바텀시트, FAB
  final List<BoxShadow> highShadow;

  /// 궁합/사주 리빌 (다크 전용 골드 글로우)
  final List<BoxShadow> mysticShadow;

  /// 다크 모드 카드 보더 (라이트에서는 null)
  final BorderSide? cardBorder;

  static const light = SajuElevation(
    lowShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
    mediumShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
    highShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
    mysticShadow: [],
    cardBorder: null,
  );

  static const dark = SajuElevation(
    lowShadow: [],
    mediumShadow: [],
    highShadow: [],
    mysticShadow: [BoxShadow(color: Color(0x26C8B68E), blurRadius: 20, spreadRadius: 2)],
    cardBorder: BorderSide(color: Color(0xFF35363F), width: 1),
  );

  @override
  SajuElevation copyWith({
    List<BoxShadow>? lowShadow,
    List<BoxShadow>? mediumShadow,
    List<BoxShadow>? highShadow,
    List<BoxShadow>? mysticShadow,
    BorderSide? cardBorder,
  }) {
    return SajuElevation(
      lowShadow: lowShadow ?? this.lowShadow,
      mediumShadow: mediumShadow ?? this.mediumShadow,
      highShadow: highShadow ?? this.highShadow,
      mysticShadow: mysticShadow ?? this.mysticShadow,
      cardBorder: cardBorder ?? this.cardBorder,
    );
  }

  @override
  SajuElevation lerp(SajuElevation? other, double t) {
    if (other is! SajuElevation) return this;
    // BoxShadow/BorderSide lerp는 t > 0.5 기준 snap
    return t < 0.5 ? this : other;
  }
}
```

**Step 2: Verify & Commit**

Run: `dart analyze lib/core/theme/tokens/saju_elevation.dart`

```bash
git add lib/core/theme/tokens/saju_elevation.dart
git commit -m "feat: SajuElevation ThemeExtension 추가 (라이트=섀도, 다크=보더+글로우)"
```

---

### Task 4: SajuSpacing + SajuAnimation static 클래스

**Files:**
- Create: `lib/core/theme/tokens/saju_spacing.dart`
- Create: `lib/core/theme/tokens/saju_animation.dart`

**Step 1: Create SajuSpacing**

```dart
import 'package:flutter/material.dart';

/// 스페이싱 토큰 — 4px 그리드, 테마 불변
///
/// production-ui-system.md §2 Spacing System 매핑.
/// 사용: `SajuSpacing.space16` 또는 `SajuSpacing.page`
abstract final class SajuSpacing {
  // 4px grid
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;
  static const space48 = 48.0;
  static const space64 = 64.0;

  // EdgeInsets presets — production-ui-system.md §2 Page layout
  static const page = EdgeInsets.symmetric(horizontal: 20);
  static const cardInner = EdgeInsets.all(16);
  static const cardInnerCompact = EdgeInsets.all(12);

  // SizedBox presets for common gaps
  static const gap4 = SizedBox(height: 4);
  static const gap8 = SizedBox(height: 8);
  static const gap12 = SizedBox(height: 12);
  static const gap16 = SizedBox(height: 16);
  static const gap24 = SizedBox(height: 24);
  static const gap32 = SizedBox(height: 32);
  static const hGap4 = SizedBox(width: 4);
  static const hGap8 = SizedBox(width: 8);
  static const hGap12 = SizedBox(width: 12);
  static const hGap16 = SizedBox(width: 16);
}
```

**Step 2: Create SajuAnimation**

```dart
import 'package:flutter/material.dart';

/// 애니메이션 토큰 — Duration, Curve
///
/// production-ui-system.md §7 Interaction Feedback System 매핑.
/// 사용: `SajuAnimation.fast` / `SajuAnimation.entrance`
abstract final class SajuAnimation {
  // Durations
  static const fast = Duration(milliseconds: 100);      // tap feedback
  static const normal = Duration(milliseconds: 200);     // tab switch, card press
  static const slow = Duration(milliseconds: 300);       // page transition, success
  static const sheet = Duration(milliseconds: 400);      // bottom sheet spring
  static const like = Duration(milliseconds: 500);       // like sent
  static const match = Duration(milliseconds: 600);      // match reveal
  static const reveal = Duration(milliseconds: 1800);    // score gauge fill

  // Curves
  static const entrance = Curves.easeOutCubic;           // fast start, slow end
  static const exit = Curves.easeInCubic;                // slow start, fast end
  static const bounce = Curves.elasticOut;               // score reveal only

  // Interaction feedback values
  static const pressedOpacity = 0.7;
  static const pressedScale = 0.97;
  static const disabledOpacity = 0.4;
}
```

**Step 3: Verify & Commit**

Run: `dart analyze lib/core/theme/tokens/saju_spacing.dart lib/core/theme/tokens/saju_animation.dart`

```bash
git add lib/core/theme/tokens/saju_spacing.dart lib/core/theme/tokens/saju_animation.dart
git commit -m "feat: SajuSpacing + SajuAnimation static 토큰 추가"
```

---

### Task 5: BuildContext Extension + Barrel Export

**Files:**
- Create: `lib/core/theme/theme_extensions.dart`
- Create: `lib/core/theme/tokens/tokens.dart` (barrel)

**Step 1: Create BuildContext extension**

```dart
import 'package:flutter/material.dart';

import 'tokens/saju_colors.dart';
import 'tokens/saju_typography.dart';
import 'tokens/saju_elevation.dart';

/// BuildContext에서 Saju 토큰에 편리하게 접근하기 위한 extension.
///
/// ```dart
/// final colors = context.sajuColors;
/// final typo = context.sajuTypo;
/// final elevation = context.sajuElevation;
/// ```
extension SajuThemeX on BuildContext {
  SajuColors get sajuColors => Theme.of(this).extension<SajuColors>()!;
  SajuTypography get sajuTypo => Theme.of(this).extension<SajuTypography>()!;
  SajuElevation get sajuElevation => Theme.of(this).extension<SajuElevation>()!;

  /// 현재 다크 모드인지 여부
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
```

**Step 2: Create barrel export**

```dart
/// Saju 디자인 토큰 — barrel export
///
/// ```dart
/// import 'package:saju_app/core/theme/tokens/tokens.dart';
/// ```
library;

export 'saju_colors.dart';
export 'saju_typography.dart';
export 'saju_elevation.dart';
export 'saju_spacing.dart';
export 'saju_animation.dart';
```

**Step 3: Verify & Commit**

Run: `dart analyze lib/core/theme/theme_extensions.dart lib/core/theme/tokens/tokens.dart`

```bash
git add lib/core/theme/theme_extensions.dart lib/core/theme/tokens/tokens.dart
git commit -m "feat: BuildContext extension + 토큰 barrel export 추가"
```

---

### Task 6: ThemeExtension 등록 (app_theme.dart)

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

**Step 1: Import 추가 및 extensions 등록**

`app_theme.dart`의 `static final light` ThemeData에 extensions 추가:

```dart
// import 추가 (파일 상단)
import 'tokens/saju_colors.dart';
import 'tokens/saju_typography.dart';
import 'tokens/saju_elevation.dart';
```

light ThemeData 내부 (dividerTheme 아래):
```dart
    // --- Saju Design Tokens ---
    extensions: const [
      SajuColors.light,
      SajuTypography.light,
      SajuElevation.light,
    ],
```

dark ThemeData 내부 (dividerTheme 아래):
```dart
    // --- Saju Design Tokens ---
    extensions: const [
      SajuColors.dark,
      SajuTypography.dark,
      SajuElevation.dark,
    ],
```

**Step 2: 기존 시멘틱 컬러에 @Deprecated 마킹**

기존 `hanjiBg`, `hanjiSurface`, `textDark`, `textLight` 등의 직접 사용을 deprecated 처리:

```dart
  // Light backgrounds
  @Deprecated('Use context.sajuColors.bgPrimary instead')
  static const hanjiBg = Color(0xFFF7F3EE);
  @Deprecated('Use context.sajuColors.bgElevated instead')
  static const hanjiSurface = Color(0xFFFEFCF9);
  @Deprecated('Use context.sajuColors.bgSecondary instead')
  static const hanjiElevated = Color(0xFFF0EDE8);

  // Dark backgrounds
  @Deprecated('Use context.sajuColors.bgPrimary instead')
  static const inkBlack = Color(0xFF1D1E23);
  @Deprecated('Use context.sajuColors.bgSecondary instead')
  static const inkSurface = Color(0xFF2A2B32);
  @Deprecated('Use context.sajuColors.bgElevated instead')
  static const inkCard = Color(0xFF35363F);

  // Text
  @Deprecated('Use context.sajuColors.textPrimary instead')
  static const textDark = Color(0xFF2D2D2D);
  @Deprecated('Use context.sajuColors.textPrimary instead')
  static const textLight = Color(0xFFE8E4DF);
  @Deprecated('Use context.sajuColors.textSecondary instead')
  static const textSecondaryDark = Color(0xFF6B6B6B);
  @Deprecated('Use context.sajuColors.textSecondary instead')
  static const textSecondaryLight = Color(0xFFA09B94);
  @Deprecated('Use context.sajuColors.textTertiary instead')
  static const textHint = Color(0xFFA0A0A0);

  // Borders
  @Deprecated('Use context.sajuColors.borderDefault instead')
  static const dividerLight = Color(0xFFE8E4DF);
  @Deprecated('Use context.sajuColors.borderDefault instead')
  static const dividerDark = Color(0xFF35363F);
```

스페이싱 legacy aliases도 deprecated:
```dart
  @Deprecated('Use SajuSpacing.space4 instead')
  static const spacingXs = space4;
  @Deprecated('Use SajuSpacing.space8 instead')
  static const spacingSm = space8;
  @Deprecated('Use SajuSpacing.space16 instead')
  static const spacingMd = space16;
  @Deprecated('Use SajuSpacing.space24 instead')
  static const spacingLg = space24;
  @Deprecated('Use SajuSpacing.space32 instead')
  static const spacingXl = space32;
  @Deprecated('Use SajuSpacing.space48 instead')
  static const spacingXxl = space48;
```

**Step 3: Verify full app compiles**

Run: `cd /Users/noah/saju-app && flutter analyze`
Expected: Warnings about deprecated usage (expected), no errors

**Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: ThemeExtension 등록 + 기존 시멘틱 토큰 deprecated 마킹"
```

---

### Task 7: Core 위젯 마이그레이션 — saju_card.dart + saju_button.dart

**Files:**
- Modify: `lib/core/widgets/saju_card.dart`
- Modify: `lib/core/widgets/saju_button.dart`

**Step 1: saju_card.dart 마이그레이션**

import 추가:
```dart
import '../theme/theme_extensions.dart';
import '../theme/tokens/saju_spacing.dart';
import '../theme/tokens/saju_animation.dart';
```

주요 교체:
- `Duration(milliseconds: 200)` → `SajuAnimation.normal`
- `const Color(0xFF35363F)` / `Colors.white` → `context.sajuColors.bgElevated`
- `const Color(0xFF45464F)` / `const Color(0xFFE8E4DF)` → `context.sajuColors.borderDefault`
- `alpha: 0.3`, `0.06`, `0.05`, `0.02` → `SajuAnimation.pressedOpacity` 또는 직접 값 유지 (섀도 alpha는 elevation 토큰이 처리)
- `AppTheme.spacingSm` → `SajuSpacing.space8`

**Step 2: saju_button.dart 마이그레이션**

주요 교체:
- `letterSpacing: -0.2` → 토큰 TextStyle에서 자동 적용 (필요시 유지)
- `elevation: 2` → 상수 유지 (Material elevation은 별도)
- `alpha: 0.3` → context.sajuColors 활용 가능 시 교체

**Step 3: Verify & Commit**

Run: `flutter analyze`

```bash
git add lib/core/widgets/saju_card.dart lib/core/widgets/saju_button.dart
git commit -m "refactor: saju_card + saju_button 토큰 마이그레이션"
```

---

### Task 8: Core 위젯 마이그레이션 — match_card + character_bubble

**Files:**
- Modify: `lib/core/widgets/saju_match_card.dart`
- Modify: `lib/core/widgets/saju_character_bubble.dart`

**Step 1: saju_match_card.dart 마이그레이션**

주요 교체:
- `fontSize: 10` → `context.sajuTypo.overline.fontSize`
- `fontSize: 11` → `context.sajuTypo.overline` 직접 사용
- `const EdgeInsets.symmetric(horizontal: 8, vertical: 3)` → `EdgeInsets.symmetric(horizontal: SajuSpacing.space8, vertical: SajuSpacing.space4)`
- `const EdgeInsets.fromLTRB(14, 12, 14, 14)` → `EdgeInsets.fromLTRB(SajuSpacing.space16, SajuSpacing.space12, SajuSpacing.space16, SajuSpacing.space16)` (가장 가까운 그리드로 스냅)
- `const SizedBox(height: 4)` → `SajuSpacing.gap4`
- `const Color(0x0F000000)` → 인라인 유지 (gradient overlay, 토큰화 불필요)

**Step 2: saju_character_bubble.dart 마이그레이션**

주요 교체:
- `width: 6, height: 6` → `SajuSpacing.space6` 사용
- `padding: const EdgeInsets.symmetric(horizontal: 2)` → `EdgeInsets.symmetric(horizontal: SajuSpacing.space2)`
- `alpha: 0.6` → 인라인 유지 (애니메이션 도트 alpha, 토큰화 불필요)

**Step 3: Verify & Commit**

Run: `flutter analyze`

```bash
git add lib/core/widgets/saju_match_card.dart lib/core/widgets/saju_character_bubble.dart
git commit -m "refactor: match_card + character_bubble 토큰 마이그레이션"
```

---

### Task 9: Core 위젯 마이그레이션 — like_button + premium_like_button + compatibility_card

**Files:**
- Modify: `lib/core/widgets/like_button.dart`
- Modify: `lib/core/widgets/premium_like_button.dart`
- Modify: `lib/core/widgets/compatibility_card.dart`

**Step 1: like_button.dart 마이그레이션**

주요 교체:
- `const SizedBox(width: 8)` → `SajuSpacing.hGap8`
- `fontSize: 15` → `context.sajuTypo.heading3.fontSize` 또는 직접 스타일 적용
- `fontSize: 10` → `context.sajuTypo.overline.fontSize`
- `padding: const EdgeInsets.only(top: 2)` → `EdgeInsets.only(top: SajuSpacing.space2)`

**Step 2: premium_like_button.dart 마이그레이션**

주요 교체:
- `const EdgeInsets.symmetric(horizontal: 20)` → `SajuSpacing.page`
- `const SizedBox(width: 8)` → `SajuSpacing.hGap8`
- `fontSize: 15` → `context.sajuTypo.heading3.fontSize`
- `fontSize: 11` → `context.sajuTypo.overline.fontSize`
- `fontSize: 12` → `context.sajuTypo.caption2.fontSize`
- `const EdgeInsets.symmetric(horizontal: 8, vertical: 4)` → `EdgeInsets.symmetric(horizontal: SajuSpacing.space8, vertical: SajuSpacing.space4)`

**Step 3: compatibility_card.dart 마이그레이션**

주요 교체:
- `const SizedBox(height: 2)` → `SajuSpacing.gap4` (가장 가까운 그리드로 스냅) 또는 `SizedBox(height: SajuSpacing.space2)`
- `spacing: 6` / `runSpacing: 6` → `SajuSpacing.space6`
- `fontSize: 12` → `context.sajuTypo.caption2`
- `fontSize: 13` → `context.sajuTypo.caption1`
- `fontSize: 18` → `context.sajuTypo.heading2.fontSize` (가장 가까운 토큰: 17px heading2)

**Step 4: Verify & Commit**

Run: `flutter analyze`

```bash
git add lib/core/widgets/like_button.dart lib/core/widgets/premium_like_button.dart lib/core/widgets/compatibility_card.dart
git commit -m "refactor: like_button + premium_like_button + compatibility_card 토큰 마이그레이션"
```

---

### Task 10: 나머지 위젯 + chips/badge/gauge 마이그레이션

**Files:**
- Modify: `lib/core/widgets/saju_chip.dart`
- Modify: `lib/core/widgets/saju_badge.dart`
- Modify: `lib/core/widgets/compatibility_gauge.dart`

**Step 1: saju_chip.dart**

- `Duration(milliseconds: 200)` → `SajuAnimation.normal`
- `AppTheme.spacingXs` → `SajuSpacing.space4`

**Step 2: saju_badge.dart**

- `alpha: 0.12` → 인라인 유지 (pastel 컬러 로직과 결합)
- 동적 스케일링 (`size.iconSize * 0.7` 등) → 유지 (enum 기반 계산)

**Step 3: compatibility_gauge.dart**

- `alpha: 0.08`, `0.06` → 인라인 유지 (gauge 그라디언트 전용)
- `const SizedBox(height: 2)` → `SizedBox(height: SajuSpacing.space2)`
- `height: 1.1` → 인라인 유지 (gauge number 전용)

**Step 4: Verify & Commit**

Run: `flutter analyze`

```bash
git add lib/core/widgets/saju_chip.dart lib/core/widgets/saju_badge.dart lib/core/widgets/compatibility_gauge.dart
git commit -m "refactor: chip + badge + gauge 토큰 마이그레이션"
```

---

### Task 11: widgets.dart barrel에 토큰 re-export 추가 + 최종 검증

**Files:**
- Modify: `lib/core/widgets/widgets.dart` — 상단에 theme re-export 추가 (선택)

**Step 1: 최종 flutter analyze**

Run: `cd /Users/noah/saju-app && flutter analyze`
Expected: No errors (deprecated warnings는 정상)

**Step 2: 최종 커밋**

```bash
git add -A
git commit -m "feat: UI 토큰 시스템 완성 — ThemeExtension 기반 시멘틱 토큰 + 전체 위젯 마이그레이션"
```

---

## 마이그레이션 규칙 요약

| 패턴 | Before | After |
|------|--------|-------|
| 배경색 | `AppTheme.hanjiBg` | `context.sajuColors.bgPrimary` |
| 텍스트색 | `AppTheme.textDark` | `context.sajuColors.textPrimary` |
| 텍스트 스타일 | `TextStyle(fontSize: 20, fontWeight: w600)` | `context.sajuTypo.heading1` |
| 스페이싱 | `SizedBox(height: 8)` | `SajuSpacing.gap8` |
| 패딩 | `EdgeInsets.all(16)` | `SajuSpacing.cardInner` |
| 섀도 | `AppTheme.elevationMedium(brightness)` | `context.sajuElevation.mediumShadow` |
| 애니메이션 | `Duration(milliseconds: 200)` | `SajuAnimation.normal` |
| 보더 | `BorderSide(color: Color(0xFF35363F))` | `context.sajuElevation.cardBorder` |

## 토큰화하지 않는 것

- Five element 컬러 (`AppTheme.woodColor` 등) — 테마 불변, 기존 유지
- Compatibility 컬러 (`AppTheme.compatibilityExcellent` 등) — 테마 불변
- Gauge/overlay 전용 alpha 값 — 컴포넌트 로컬 상수
- 동적 계산 (`size.fontSize * 0.5` 등) — enum 기반, 토큰화 불필요
