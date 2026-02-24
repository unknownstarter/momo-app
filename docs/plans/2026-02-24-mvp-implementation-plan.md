# Saju App MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 사주 기반 소개팅 앱 MVP — 온보딩 → 사주분석 → 매칭 → 궁합 → 좋아요/수락 → 채팅 풀 코어 루프 구현

**Architecture:** Feature-First Clean Architecture (domain/data/presentation). Riverpod 2.x 코드 생성, go_router 선언적 라우팅, Supabase (Auth + DB + Realtime + Edge Functions + Storage).

**Tech Stack:** Flutter 3.38+, Supabase, Claude API, RevenueCat, flutter_svg, freezed, go_router, flutter_riverpod

**Design Reference:** `docs/plans/2026-02-24-app-design.md` (전체 설계 문서)

**Existing Code Reference:**
- Theme: `lib/core/theme/app_theme.dart` (한지 팔레트 완전 구현)
- Constants: `lib/core/constants/app_constants.dart` (라우트, Supabase, 사주 상수)
- Errors: `lib/core/errors/failures.dart` (sealed Failure 계층)
- Network: `lib/core/network/supabase_client.dart` (SupabaseHelper)
- Utils: `lib/core/utils/validators.dart`
- Entities: `lib/features/auth/domain/entities/user_entity.dart`, `lib/features/saju/domain/entities/saju_entity.dart`
- Router: `lib/app/routes/app_router.dart` (전체 경로 정의, placeholder 페이지)
- Assets: `assets/images/characters/` (오행이 5종 + 서브 1종, SVG + PNG)

---

## Phase 2: 디자인 시스템 컴포넌트

### Task 1: SajuSize, SajuVariant, SajuColor enum 정의

**Files:**
- Create: `lib/core/widgets/saju_enums.dart`

**Step 1: Create the design system enums file**

```dart
// lib/core/widgets/saju_enums.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 모든 Saju 컴포넌트가 공유하는 사이즈 시스템 (HeroUI 참고)
enum SajuSize {
  xs(height: 28, fontSize: 12, iconSize: 14, padding: 6),
  sm(height: 36, fontSize: 13, iconSize: 16, padding: 8),
  md(height: 44, fontSize: 15, iconSize: 20, padding: 12),
  lg(height: 52, fontSize: 16, iconSize: 24, padding: 16),
  xl(height: 60, fontSize: 18, iconSize: 28, padding: 20);

  const SajuSize({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.padding,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final double padding;
}

/// 스타일 배리언트 (HeroUI 참고)
enum SajuVariant { filled, outlined, flat, elevated, ghost }

/// 오행 컬러 시맨틱 — 오행 컬러가 1급 시민
enum SajuColor {
  primary,
  secondary,
  wood,
  fire,
  earth,
  metal,
  water;

  Color resolve(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return switch (this) {
      SajuColor.primary => AppTheme.light.colorScheme.primary,
      SajuColor.secondary => const Color(0xFFF2D0D5),
      SajuColor.wood => AppTheme.woodColor,
      SajuColor.fire => AppTheme.fireColor,
      SajuColor.earth => AppTheme.earthColor,
      SajuColor.metal => AppTheme.metalColor,
      SajuColor.water => AppTheme.waterColor,
    };
  }

  Color resolvePastel(BuildContext context) {
    return switch (this) {
      SajuColor.primary => const Color(0xFFD4E4F4),
      SajuColor.secondary => const Color(0xFFF9ECEE),
      SajuColor.wood => AppTheme.woodPastel,
      SajuColor.fire => AppTheme.firePastel,
      SajuColor.earth => AppTheme.earthPastel,
      SajuColor.metal => AppTheme.metalPastel,
      SajuColor.water => AppTheme.waterPastel,
    };
  }
}
```

**Step 2: Verify it compiles**

Run: `cd /Users/noah/saju-app && flutter analyze lib/core/widgets/saju_enums.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/widgets/saju_enums.dart
git commit -m "feat: SajuSize, SajuVariant, SajuColor 디자인 시스템 enum 추가"
```

---

### Task 2: SajuButton 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_button.dart`
- Test: `test/core/widgets/saju_button_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_button.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuButton', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(buildApp(
        child: SajuButton(
          label: '좋아요',
          onPressed: () {},
        ),
      ));
      expect(find.text('좋아요'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildApp(
        child: SajuButton(
          label: '테스트',
          onPressed: () => pressed = true,
        ),
      ));
      await tester.tap(find.text('테스트'));
      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuButton(label: '비활성', onPressed: null),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: SajuButton(
          label: '프리미엄',
          onPressed: () {},
          leadingIcon: Icons.star,
        ),
      ));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('applies different sizes', (tester) async {
      await tester.pumpWidget(buildApp(
        child: SajuButton(
          label: 'SM',
          onPressed: () {},
          size: SajuSize.sm,
        ),
      ));
      // sm size = height 36
      final box = tester.getSize(find.byType(SajuButton));
      expect(box.height, greaterThanOrEqualTo(36));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_button_test.dart`
Expected: FAIL — SajuButton not found

**Step 3: Implement SajuButton**

```dart
// lib/core/widgets/saju_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// HeroUI 스타일 버튼 — 사이즈/배리언트/오행 컬러 일관된 API
///
/// ```dart
/// SajuButton(
///   label: '좋아요 보내기',
///   onPressed: () {},
///   variant: SajuVariant.filled,
///   color: SajuColor.fire,
///   size: SajuSize.lg,
///   leadingIcon: Icons.favorite,
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

  final String label;
  final VoidCallback? onPressed;
  final SajuVariant variant;
  final SajuColor color;
  final SajuSize size;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color.resolve(context);
    final radius = BorderRadius.circular(AppTheme.radiusMd + 2);

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: size.iconSize,
            height: size.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == SajuVariant.filled ? Colors.white : resolvedColor,
            ),
          ),
          SizedBox(width: size.padding / 2),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: size.iconSize),
          SizedBox(width: size.padding / 2),
        ],
        Text(label),
      ],
    );

    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      height: size.height,
      width: expand ? double.infinity : null,
      child: switch (variant) {
        SajuVariant.filled => ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: resolvedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: size.padding),
            ),
            child: child,
          ),
        SajuVariant.outlined => OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: resolvedColor,
              side: BorderSide(color: resolvedColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: size.padding),
            ),
            child: child,
          ),
        SajuVariant.flat || SajuVariant.ghost => TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: resolvedColor,
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: size.padding),
            ),
            child: child,
          ),
        SajuVariant.elevated => ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: resolvedColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: size.padding),
            ),
            child: child,
          ),
      },
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_button_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_button.dart test/core/widgets/saju_button_test.dart
git commit -m "feat: SajuButton 컴포넌트 구현 (size/variant/color 시스템)"
```

---

### Task 3: SajuChip 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_chip.dart`
- Test: `test/core/widgets/saju_chip_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_chip.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuChip(label: '목(木)'),
      ));
      expect(find.text('목(木)'), findsOneWidget);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuChip(label: '음악', leadingIcon: Icons.music_note),
      ));
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('handles onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(
        child: SajuChip(label: '탭', onTap: () => tapped = true),
      ));
      await tester.tap(find.text('탭'));
      expect(tapped, isTrue);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuChip(label: '선택됨', isSelected: true),
      ));
      expect(find.text('선택됨'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_chip_test.dart`
Expected: FAIL

**Step 3: Implement SajuChip**

```dart
// lib/core/widgets/saju_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 오행 태그, 관심사, 성향 등에 사용되는 칩 컴포넌트
class SajuChip extends StatelessWidget {
  const SajuChip({
    super.key,
    required this.label,
    this.color = SajuColor.primary,
    this.size = SajuSize.sm,
    this.leadingIcon,
    this.onTap,
    this.isSelected = false,
    this.onDeleted,
  });

  final String label;
  final SajuColor color;
  final SajuSize size;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color.resolve(context);
    final pastelColor = color.resolvePastel(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: size.padding,
          vertical: size.padding / 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? resolvedColor.withValues(alpha: 0.15) : pastelColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? resolvedColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: size.iconSize * 0.8,
                color: isSelected ? resolvedColor : resolvedColor.withValues(alpha: 0.7),
              ),
              SizedBox(width: size.padding / 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: size.fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? resolvedColor : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (onDeleted != null) ...[
              SizedBox(width: size.padding / 3),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: size.iconSize * 0.7,
                  color: resolvedColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Run tests**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_chip_test.dart`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_chip.dart test/core/widgets/saju_chip_test.dart
git commit -m "feat: SajuChip 컴포넌트 구현 (오행 태그, 관심사 칩)"
```

---

### Task 4: SajuAvatar 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_avatar.dart`
- Test: `test/core/widgets/saju_avatar_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_avatar.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuAvatar', () {
    testWidgets('renders fallback initials when no image', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuAvatar(name: '김사주'),
      ));
      expect(find.text('김'), findsOneWidget);
    });

    testWidgets('renders with element badge', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuAvatar(
          name: '박오행',
          elementColor: SajuColor.fire,
        ),
      ));
      expect(find.text('박'), findsOneWidget);
    });

    testWidgets('applies different sizes', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuAvatar(name: '이', size: SajuSize.xl),
      ));
      final box = tester.getSize(find.byType(SajuAvatar));
      expect(box.width, equals(SajuSize.xl.height));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_avatar_test.dart`
Expected: FAIL

**Step 3: Implement SajuAvatar**

```dart
// lib/core/widgets/saju_avatar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 프로필 아바타 — 실사 이미지 + 오행 캐릭터 오버레이
class SajuAvatar extends StatelessWidget {
  const SajuAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.characterAsset,
    this.size = SajuSize.md,
    this.elementColor,
    this.showBadge = false,
    this.badgeCount,
  });

  final String name;
  final String? imageUrl;
  final String? characterAsset;
  final SajuSize size;
  final SajuColor? elementColor;
  final bool showBadge;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final dimension = size.height;
    final badgeSize = dimension * 0.35;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main avatar circle
          Container(
            width: dimension,
            height: dimension,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: elementColor?.resolvePastel(context) ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: elementColor != null
                  ? Border.all(
                      color: elementColor!.resolve(context).withValues(alpha: 0.4),
                      width: 2,
                    )
                  : null,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name.characters.first : '?',
                      style: TextStyle(
                        fontSize: size.fontSize * 1.2,
                        fontWeight: FontWeight.w600,
                        color: elementColor?.resolve(context) ??
                            Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  )
                : null,
          ),

          // Element color badge (bottom-right)
          if (elementColor != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: elementColor!.resolve(context),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),

          // Notification badge (top-right)
          if (showBadge || (badgeCount != null && badgeCount! > 0))
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.fireColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: badgeCount != null
                    ? Center(
                        child: Text(
                          badgeCount! > 99 ? '99+' : '$badgeCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.fontSize * 0.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
```

**Step 4: Run tests**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_avatar_test.dart`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_avatar.dart test/core/widgets/saju_avatar_test.dart
git commit -m "feat: SajuAvatar 컴포넌트 구현 (프로필 + 오행 뱃지)"
```

---

### Task 5: SajuCard 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_card.dart`
- Test: `test/core/widgets/saju_card_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_card.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuCard', () {
    testWidgets('renders header, content, footer', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuCard(
          header: Text('헤더'),
          content: Text('본문'),
          footer: Text('푸터'),
        ),
      ));
      expect(find.text('헤더'), findsOneWidget);
      expect(find.text('본문'), findsOneWidget);
      expect(find.text('푸터'), findsOneWidget);
    });

    testWidgets('renders content only', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuCard(content: Text('내용만')),
      ));
      expect(find.text('내용만'), findsOneWidget);
    });

    testWidgets('handles onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(
        child: SajuCard(
          content: const Text('탭'),
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('탭'));
      expect(tapped, isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_card_test.dart`
Expected: FAIL

**Step 3: Implement SajuCard**

```dart
// lib/core/widgets/saju_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// HeroUI Card 패턴 — Header / Content / Footer 구조
class SajuCard extends StatelessWidget {
  const SajuCard({
    super.key,
    this.header,
    required this.content,
    this.footer,
    this.variant = SajuVariant.elevated,
    this.onTap,
    this.padding,
    this.borderColor,
  });

  final Widget? header;
  final Widget content;
  final Widget? footer;
  final SajuVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPadding = const EdgeInsets.all(AppTheme.spacingMd);

    final decoration = switch (variant) {
      SajuVariant.filled => BoxDecoration(
          color: isDark ? const Color(0xFF35363F) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
      SajuVariant.outlined => BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: borderColor ??
                (isDark ? const Color(0xFF45464F) : const Color(0xFFE8E4DF)),
            width: 1,
          ),
        ),
      SajuVariant.elevated => BoxDecoration(
          color: isDark ? const Color(0xFF35363F) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      SajuVariant.flat || SajuVariant.ghost => BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: decoration,
        child: Padding(
          padding: padding ?? defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
```

**Step 4: Run tests**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_card_test.dart`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_card.dart test/core/widgets/saju_card_test.dart
git commit -m "feat: SajuCard 컴포넌트 구현 (Header/Content/Footer 패턴)"
```

---

### Task 6: SajuCharacterBubble 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_character_bubble.dart`
- Test: `test/core/widgets/saju_character_bubble_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_character_bubble_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_character_bubble.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuCharacterBubble', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuCharacterBubble(
          characterName: '나무리',
          message: '안녕! 네 사주를 봐줄게~',
          elementColor: SajuColor.wood,
        ),
      ));
      expect(find.text('안녕! 네 사주를 봐줄게~'), findsOneWidget);
      expect(find.text('나무리'), findsOneWidget);
    });

    testWidgets('renders with different element colors', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuCharacterBubble(
          characterName: '불꼬리',
          message: '열정적으로 가자!',
          elementColor: SajuColor.fire,
        ),
      ));
      expect(find.text('불꼬리'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_character_bubble_test.dart`
Expected: FAIL

**Step 3: Implement SajuCharacterBubble**

```dart
// lib/core/widgets/saju_character_bubble.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 캐릭터 말풍선 — 가이드/해석/빈 상태에서 캐릭터가 메시지 전달
class SajuCharacterBubble extends StatelessWidget {
  const SajuCharacterBubble({
    super.key,
    required this.characterName,
    required this.message,
    required this.elementColor,
    this.characterAssetPath,
    this.size = SajuSize.md,
  });

  final String characterName;
  final String message;
  final SajuColor elementColor;
  final String? characterAssetPath;
  final SajuSize size;

  @override
  Widget build(BuildContext context) {
    final color = elementColor.resolve(context);
    final pastel = elementColor.resolvePastel(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character avatar circle
        Container(
          width: size.height,
          height: size.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pastel,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(
            child: Text(
              characterName.characters.first,
              style: TextStyle(
                fontSize: size.fontSize * 1.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        // Speech bubble
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                characterName,
                style: TextStyle(
                  fontSize: size.fontSize * 0.8,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(size.padding),
                decoration: BoxDecoration(
                  color: isDark
                      ? color.withValues(alpha: 0.1)
                      : pastel.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(AppTheme.radiusLg),
                    bottomLeft: Radius.circular(AppTheme.radiusLg),
                    bottomRight: Radius.circular(AppTheme.radiusLg),
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: size.fontSize,
                    height: 1.5,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

**Step 4: Run tests**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_character_bubble_test.dart`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_character_bubble.dart test/core/widgets/saju_character_bubble_test.dart
git commit -m "feat: SajuCharacterBubble 컴포넌트 구현 (캐릭터 말풍선 가이드)"
```

---

### Task 7: SajuInput 컴포넌트

**Files:**
- Create: `lib/core/widgets/saju_input.dart`
- Test: `test/core/widgets/saju_input_test.dart`

**Step 1: Write the widget test**

```dart
// test/core/widgets/saju_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_input.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuInput', () {
    testWidgets('renders with label and hint', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuInput(label: '이름', hint: '이름을 입력해주세요'),
      ));
      expect(find.text('이름'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildApp(
        child: SajuInput(
          label: '이름',
          controller: controller,
        ),
      ));
      await tester.enterText(find.byType(TextField), '김사주');
      expect(controller.text, '김사주');
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuInput(
          label: '이름',
          errorText: '이름을 입력해주세요',
        ),
      ));
      expect(find.text('이름을 입력해주세요'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_input_test.dart`
Expected: FAIL

**Step 3: Implement SajuInput**

```dart
// lib/core/widgets/saju_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 한지 스타일 텍스트 입력 필드
class SajuInput extends StatelessWidget {
  const SajuInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.size = SajuSize.md,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final SajuSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size.fontSize * 0.9,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          enabled: enabled,
          autofocus: autofocus,
          style: TextStyle(fontSize: size.fontSize),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
```

**Step 4: Run tests**

Run: `cd /Users/noah/saju-app && flutter test test/core/widgets/saju_input_test.dart`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/core/widgets/saju_input.dart test/core/widgets/saju_input_test.dart
git commit -m "feat: SajuInput 컴포넌트 구현 (한지 스타일 입력 필드)"
```

---

### Task 8: Export barrel file + SajuBadge

**Files:**
- Create: `lib/core/widgets/saju_badge.dart`
- Create: `lib/core/widgets/widgets.dart` (barrel export)

**Step 1: Implement SajuBadge**

```dart
// lib/core/widgets/saju_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// 알림/상태 뱃지 — 궁합 등급, 새 메시지, 프리미엄 표시
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
        horizontal: size.padding,
        vertical: size.padding / 3,
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
            SizedBox(width: size.padding / 4),
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
```

**Step 2: Create barrel export**

```dart
// lib/core/widgets/widgets.dart
export 'saju_enums.dart';
export 'saju_button.dart';
export 'saju_chip.dart';
export 'saju_avatar.dart';
export 'saju_card.dart';
export 'saju_character_bubble.dart';
export 'saju_input.dart';
export 'saju_badge.dart';
```

**Step 3: Run full test suite**

Run: `cd /Users/noah/saju-app && flutter test`
Expected: All pass

**Step 4: Commit**

```bash
git add lib/core/widgets/saju_badge.dart lib/core/widgets/widgets.dart
git commit -m "feat: SajuBadge 컴포넌트 + 디자인 시스템 barrel export"
```

---

## Phase 3: Supabase 백엔드 기반

### Task 9: app_constants.dart에 포인트/좋아요 관련 상수 추가

**Files:**
- Modify: `lib/core/constants/app_constants.dart`

**Step 1: Add new constants**

기존 `AppLimits` 클래스에 추가:

```dart
// 기존 AppLimits 하단에 추가:

  // --- 좋아요/수락 ---
  static const dailyFreeLikeLimit = 3;
  static const dailyFreeAcceptLimit = 3;

  // --- 포인트 ---
  static const likeCost = 100;          // 일반 좋아요 (무료 소진 후)
  static const premiumLikeCost = 300;   // 프리미엄 좋아요
  static const acceptCost = 100;        // 수락 (무료 소진 후)
  static const compatibilityReportCost = 500;
  static const sajuDetailedReportCost = 500;
  static const icebreakerCost = 100;
```

기존 `SupabaseTables`에 추가:

```dart
  static const userPoints = 'user_points';
  static const pointTransactions = 'point_transactions';
  static const dailyUsage = 'daily_usage';
  static const characterItems = 'character_items';
  static const purchases = 'purchases';
```

기존 `SupabaseFunctions`에 추가:

```dart
  static const sendLike = 'send-like';
  static const acceptLike = 'accept-like';
  static const purchasePoints = 'purchase-points';
  static const getDailyMatches = 'get-daily-matches';
  static const resetDailyUsage = 'reset-daily-usage';
```

**Step 2: Verify compile**

Run: `cd /Users/noah/saju-app && flutter analyze lib/core/constants/app_constants.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "feat: 포인트/좋아요/수락 관련 상수 추가"
```

---

### Task 10: Supabase DB 마이그레이션 작성

**Files:**
- Create: `supabase/migrations/20260224000001_initial_schema.sql`

**Step 1: Write the migration**

```sql
-- ============================================================
-- Saju App Initial Schema
-- ============================================================

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES (유저 기본 정보)
-- ============================================================
create table public.profiles (
  id uuid primary key default uuid_generate_v4(),
  auth_id uuid unique not null references auth.users(id) on delete cascade,
  name text not null,
  birth_date date not null,
  birth_time time,
  gender text not null check (gender in ('male', 'female')),
  profile_images text[] default '{}',
  bio text,
  interests text[] default '{}',
  height int,
  location text,
  occupation text,
  dominant_element text check (dominant_element in ('wood', 'fire', 'earth', 'metal', 'water')),
  character_type text check (character_type in ('namuri', 'bulkkori', 'heuksuni', 'soedongi', 'mulgyeori')),
  point_balance int not null default 0,
  is_premium boolean not null default false,
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_profiles_auth_id on public.profiles(auth_id);
create index idx_profiles_dominant_element on public.profiles(dominant_element);
create index idx_profiles_last_active on public.profiles(last_active_at desc);

-- ============================================================
-- SAJU PROFILES (사주 분석 결과)
-- ============================================================
create table public.saju_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  year_pillar jsonb not null,   -- {stem: "갑", branch: "자"}
  month_pillar jsonb not null,
  day_pillar jsonb not null,
  hour_pillar jsonb,            -- 선택 (시간 모를 수 있음)
  five_elements jsonb not null, -- {wood: 2, fire: 1, earth: 2, metal: 1, water: 2}
  dominant_element text not null,
  personality_traits text[] default '{}',
  ai_interpretation text,
  is_lunar_calendar boolean not null default false,
  calculated_at timestamptz not null default now()
);

-- ============================================================
-- SAJU COMPATIBILITY (궁합 결과 — 캐시)
-- ============================================================
create table public.saju_compatibility (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  partner_id uuid not null references public.profiles(id),
  total_score int not null check (total_score between 0 and 100),
  five_element_score int,
  day_pillar_score int,
  overall_analysis text,
  strengths text[] default '{}',
  challenges text[] default '{}',
  advice text,
  ai_story text,
  is_detailed boolean not null default false,
  calculated_at timestamptz not null default now(),
  unique(user_id, partner_id)
);

create index idx_compatibility_user on public.saju_compatibility(user_id);
create index idx_compatibility_partner on public.saju_compatibility(partner_id);

-- ============================================================
-- DAILY MATCHES (매일 추천)
-- ============================================================
create table public.daily_matches (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  recommended_id uuid not null references public.profiles(id),
  compatibility_id uuid references public.saju_compatibility(id),
  match_date date not null default current_date,
  is_viewed boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id, recommended_id, match_date)
);

create index idx_daily_matches_user_date on public.daily_matches(user_id, match_date desc);

-- ============================================================
-- LIKES (좋아요)
-- ============================================================
create table public.likes (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid not null references public.profiles(id),
  receiver_id uuid not null references public.profiles(id),
  is_premium boolean not null default false,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'expired')),
  sent_at timestamptz not null default now(),
  responded_at timestamptz,
  unique(sender_id, receiver_id)
);

create index idx_likes_receiver_status on public.likes(receiver_id, status);
create index idx_likes_sender on public.likes(sender_id);

-- ============================================================
-- MATCHES (매칭 성사)
-- ============================================================
create table public.matches (
  id uuid primary key default uuid_generate_v4(),
  user1_id uuid not null references public.profiles(id),
  user2_id uuid not null references public.profiles(id),
  like_id uuid references public.likes(id),
  compatibility_id uuid references public.saju_compatibility(id),
  matched_at timestamptz not null default now(),
  unmatched_at timestamptz
);

create index idx_matches_users on public.matches(user1_id, user2_id);

-- ============================================================
-- CHAT ROOMS (채팅방)
-- ============================================================
create table public.chat_rooms (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid unique not null references public.matches(id),
  user1_id uuid not null references public.profiles(id),
  user2_id uuid not null references public.profiles(id),
  last_message_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_chat_rooms_users on public.chat_rooms using gin(array[user1_id, user2_id]);

-- ============================================================
-- CHAT MESSAGES (채팅 메시지)
-- ============================================================
create table public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text not null,
  message_type text not null default 'text' check (message_type in ('text', 'image', 'icebreaker', 'system')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_messages_room_created on public.chat_messages(room_id, created_at desc);

-- ============================================================
-- USER POINTS (포인트 잔액)
-- ============================================================
create table public.user_points (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  balance int not null default 0 check (balance >= 0),
  total_earned int not null default 0,
  total_spent int not null default 0,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- POINT TRANSACTIONS (포인트 거래 내역)
-- ============================================================
create table public.point_transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  type text not null check (type in (
    'purchase', 'like_sent', 'premium_like_sent', 'accept',
    'compatibility_report', 'character_skin', 'saju_report',
    'icebreaker', 'daily_reset_bonus', 'refund'
  )),
  amount int not null,   -- + for earn, - for spend
  target_id uuid,        -- related like/match/item ID
  description text,
  created_at timestamptz not null default now()
);

create index idx_point_tx_user on public.point_transactions(user_id, created_at desc);

-- ============================================================
-- DAILY USAGE (일일 무료 사용량)
-- ============================================================
create table public.daily_usage (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  usage_date date not null default current_date,
  free_likes_used int not null default 0 check (free_likes_used between 0 and 3),
  free_accepts_used int not null default 0 check (free_accepts_used between 0 and 3),
  unique(user_id, usage_date)
);

-- ============================================================
-- BLOCKS (차단)
-- ============================================================
create table public.blocks (
  id uuid primary key default uuid_generate_v4(),
  blocker_id uuid not null references public.profiles(id),
  blocked_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(blocker_id, blocked_id)
);

-- ============================================================
-- REPORTS (신고)
-- ============================================================
create table public.reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.profiles(id),
  reported_id uuid not null references public.profiles(id),
  reason text not null,
  description text,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'resolved')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- PURCHASES (IAP 구매 내역)
-- ============================================================
create table public.purchases (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  product_type text not null check (product_type in (
    'point_package', 'detailed_compatibility', 'character_skin',
    'saju_report', 'subscription'
  )),
  product_id text not null,
  amount int,
  currency text default 'KRW',
  receipt_data text,
  purchased_at timestamptz not null default now(),
  expires_at timestamptz
);

create index idx_purchases_user on public.purchases(user_id, purchased_at desc);

-- ============================================================
-- CHARACTER ITEMS (캐릭터 커스터마이징)
-- ============================================================
create table public.character_items (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  item_type text not null check (item_type in ('outfit', 'accessory', 'background')),
  item_id text not null,
  is_equipped boolean not null default false,
  purchased_at timestamptz not null default now(),
  unique(user_id, item_id)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.saju_profiles enable row level security;
alter table public.saju_compatibility enable row level security;
alter table public.daily_matches enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
alter table public.user_points enable row level security;
alter table public.point_transactions enable row level security;
alter table public.daily_usage enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.purchases enable row level security;
alter table public.character_items enable row level security;

-- Helper: get current user's profile id
create or replace function public.current_profile_id()
returns uuid as $$
  select id from public.profiles where auth_id = auth.uid()
$$ language sql security definer stable;

-- PROFILES: 자기 것만 수정, 추천 상대 프로필은 읽기 가능
create policy "profiles_select_own" on public.profiles for select using (auth_id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (auth_id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (auth_id = auth.uid());

-- SAJU PROFILES: 자기 것만
create policy "saju_select_own" on public.saju_profiles for select using (user_id = public.current_profile_id());
create policy "saju_insert_own" on public.saju_profiles for insert with check (user_id = public.current_profile_id());
create policy "saju_update_own" on public.saju_profiles for update using (user_id = public.current_profile_id());

-- COMPATIBILITY: 당사자만
create policy "compat_select" on public.saju_compatibility for select
  using (user_id = public.current_profile_id() or partner_id = public.current_profile_id());

-- LIKES: sender/receiver만
create policy "likes_select" on public.likes for select
  using (sender_id = public.current_profile_id() or receiver_id = public.current_profile_id());
create policy "likes_insert" on public.likes for insert
  with check (sender_id = public.current_profile_id());
create policy "likes_update" on public.likes for update
  using (receiver_id = public.current_profile_id());

-- MATCHES: 참여자만
create policy "matches_select" on public.matches for select
  using (user1_id = public.current_profile_id() or user2_id = public.current_profile_id());

-- CHAT ROOMS: 참여자만
create policy "rooms_select" on public.chat_rooms for select
  using (user1_id = public.current_profile_id() or user2_id = public.current_profile_id());

-- CHAT MESSAGES: 해당 채팅방 참여자만
create policy "messages_select" on public.chat_messages for select
  using (
    room_id in (
      select id from public.chat_rooms
      where user1_id = public.current_profile_id() or user2_id = public.current_profile_id()
    )
  );
create policy "messages_insert" on public.chat_messages for insert
  with check (sender_id = public.current_profile_id());

-- POINTS: 본인만
create policy "points_select" on public.user_points for select using (user_id = public.current_profile_id());
create policy "point_tx_select" on public.point_transactions for select using (user_id = public.current_profile_id());

-- DAILY USAGE: 본인만
create policy "daily_usage_select" on public.daily_usage for select using (user_id = public.current_profile_id());

-- PURCHASES: 본인만
create policy "purchases_select" on public.purchases for select using (user_id = public.current_profile_id());

-- CHARACTER ITEMS: 본인만
create policy "char_items_select" on public.character_items for select using (user_id = public.current_profile_id());
create policy "char_items_update" on public.character_items for update using (user_id = public.current_profile_id());

-- DAILY MATCHES: 본인 추천만
create policy "daily_matches_select" on public.daily_matches for select using (user_id = public.current_profile_id());

-- BLOCKS/REPORTS: 본인 것만
create policy "blocks_select" on public.blocks for select using (blocker_id = public.current_profile_id());
create policy "blocks_insert" on public.blocks for insert with check (blocker_id = public.current_profile_id());
create policy "reports_insert" on public.reports for insert with check (reporter_id = public.current_profile_id());

-- ============================================================
-- REALTIME: 채팅 메시지 구독 활성화
-- ============================================================
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.likes;
```

**Step 2: Verify SQL syntax (dry run)**

Run: `cd /Users/noah/saju-app && cat supabase/migrations/20260224000001_initial_schema.sql | head -5`
Expected: SQL file exists

**Step 3: Commit**

```bash
git add supabase/migrations/20260224000001_initial_schema.sql
git commit -m "feat: Supabase 초기 DB 스키마 마이그레이션 (전체 테이블 + RLS)"
```

---

## Phase 3 (continued): 도메인 엔티티 보강

### Task 11: Point/Like/Match 도메인 엔티티 추가

**Files:**
- Create: `lib/features/points/domain/entities/point_entity.dart`
- Create: `lib/features/matching/domain/entities/like_entity.dart`
- Create: `lib/features/matching/domain/entities/match_entity.dart`

**Step 1: Implement Point entities**

```dart
// lib/features/points/domain/entities/point_entity.dart

/// 포인트 잔액
class UserPoints {
  const UserPoints({
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
  });

  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;

  bool canAfford(int cost) => balance >= cost;

  UserPoints copyWith({int? balance, int? totalEarned, int? totalSpent}) {
    return UserPoints(
      userId: userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}

/// 포인트 거래 타입
enum PointTransactionType {
  purchase,
  likeSent,
  premiumLikeSent,
  accept,
  compatibilityReport,
  characterSkin,
  sajuReport,
  icebreaker,
  dailyResetBonus,
  refund,
}

/// 포인트 거래 내역
class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.targetId,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final PointTransactionType type;
  final int amount; // + earn, - spend
  final String? targetId;
  final String? description;
  final DateTime createdAt;

  bool get isEarning => amount > 0;
  bool get isSpending => amount < 0;
}

/// 일일 무료 사용량
class DailyUsage {
  const DailyUsage({
    required this.userId,
    required this.date,
    required this.freeLikesUsed,
    required this.freeAcceptsUsed,
  });

  final String userId;
  final DateTime date;
  final int freeLikesUsed;
  final int freeAcceptsUsed;

  bool get hasFreeLikes => freeLikesUsed < 3;
  bool get hasFreeAccepts => freeAcceptsUsed < 3;
  int get remainingFreeLikes => 3 - freeLikesUsed;
  int get remainingFreeAccepts => 3 - freeAcceptsUsed;
}
```

**Step 2: Implement Like entity**

```dart
// lib/features/matching/domain/entities/like_entity.dart

enum LikeStatus { pending, accepted, rejected, expired }

/// 좋아요
class Like {
  const Like({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.isPremium,
    required this.status,
    required this.sentAt,
    this.respondedAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final bool isPremium;
  final LikeStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  bool get isPending => status == LikeStatus.pending;
  bool get isAccepted => status == LikeStatus.accepted;

  /// 프리미엄 좋아요를 받으면 무료로 수락 가능
  bool get canAcceptFree => isPremium;
}
```

**Step 3: Implement Match entity**

```dart
// lib/features/matching/domain/entities/match_entity.dart

/// 매칭 성사
class Match {
  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.likeId,
    this.compatibilityId,
    required this.matchedAt,
    this.unmatchedAt,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final String? likeId;
  final String? compatibilityId;
  final DateTime matchedAt;
  final DateTime? unmatchedAt;

  bool get isActive => unmatchedAt == null;

  /// 상대방 ID 반환
  String partnerId(String myId) => myId == user1Id ? user2Id : user1Id;
}
```

**Step 4: Run analyze**

Run: `cd /Users/noah/saju-app && flutter analyze`
Expected: No issues

**Step 5: Commit**

```bash
git add lib/features/points/domain/entities/point_entity.dart lib/features/matching/domain/entities/like_entity.dart lib/features/matching/domain/entities/match_entity.dart
git commit -m "feat: Point/Like/Match 도메인 엔티티 추가"
```

---

## Phase 4-7: 이후 태스크 개요

> 아래는 Phase 4 이후의 태스크 개요입니다. 각 Phase를 시작할 때 상세 Step으로 확장합니다.

### Phase 4: Auth + 온보딩 (Tasks 12-18)

- **Task 12**: Auth repository interface + Supabase implementation (소셜 로그인)
- **Task 13**: Auth providers (Riverpod — login/logout state)
- **Task 14**: 로그인 페이지 UI (Apple, Google 소셜 로그인 버튼)
- **Task 15**: 온보딩 인트로 3슬라이드 (캐릭터 비주얼, PageView)
- **Task 16**: 온보딩 정보 입력 4단계 (캐릭터 가이드 + SajuInput 활용)
- **Task 17**: 프로필 생성 → Supabase 저장 플로우
- **Task 18**: 온보딩 → 사주 분석 전환 연결

### Phase 5: 사주 분석 (Tasks 19-24)

- **Task 19**: Saju 계산 Edge Function (manseryeok-js 기반)
- **Task 20**: AI 해석 Edge Function (Claude API)
- **Task 21**: Saju repository interface + implementation
- **Task 22**: Saju providers (계산 요청 → 결과 상태)
- **Task 23**: 사주 분석 로딩 화면 (5캐릭터 애니메이션)
- **Task 24**: 사주 결과 화면 (오행 차트 + 캐릭터 배정 + AI 해석)

### Phase 6: 홈 + 매칭 + 궁합 (Tasks 25-34)

- **Task 25**: 홈 화면 (추천 리스트 + 캐릭터 인사 + 일일 포춘)
- **Task 26**: get-daily-matches Edge Function
- **Task 27**: 매칭 카드 UI (SajuMatchCard — 사진+캐릭터+궁합)
- **Task 28**: 궁합 프리뷰 화면 (간단 점수 + 등급)
- **Task 29**: 궁합 상세 리포트 (💰 과금 → AI 스토리)
- **Task 30**: 좋아요 보내기 (무료 3회 + 포인트 차감 로직)
- **Task 31**: 프리미엄 좋아요 (항상 포인트 과금)
- **Task 32**: 좋아요 수신 알림 + 수락/거절 UI
- **Task 33**: 수락 로직 (프리미엄=무료, 일반=3회+포인트)
- **Task 34**: 매칭 성사 화면 (커플 캐릭터 축하 애니메이션)

### Phase 7: 채팅 (Tasks 35-38)

- **Task 35**: Supabase Realtime 채팅 인프라
- **Task 36**: 채팅방 목록 화면
- **Task 37**: 채팅방 UI (메시지 + 캐릭터 아바타)
- **Task 38**: 아이스브레이커 기능 (💰 과금)

### Phase 8: 포인트 + 결제 (Tasks 39-42)

- **Task 39**: 포인트 잔액/내역 화면
- **Task 40**: 포인트 충전 (RevenueCat IAP 연동)
- **Task 41**: 일일 무료 사용량 초기화 (cron Edge Function)
- **Task 42**: 프로필 화면 + 캐릭터 커스터마이징 상점

---

## Summary

| Phase | Tasks | 핵심 산출물 |
|-------|-------|------------|
| 2: 디자인 시스템 | 1-8 | SajuButton/Chip/Avatar/Card/Input/Badge/CharacterBubble |
| 3: 백엔드 기반 | 9-11 | DB 스키마, 상수, 도메인 엔티티 |
| 4: Auth+온보딩 | 12-18 | 소셜 로그인, 인트로 슬라이드, 캐릭터 가이드 입력 |
| 5: 사주 분석 | 19-24 | 만세력 계산, AI 해석, 결과 화면 |
| 6: 매칭+궁합 | 25-34 | 홈, 추천, 궁합, 좋아요/수락, 매칭 성사 |
| 7: 채팅 | 35-38 | Realtime 채팅, 아이스브레이커 |
| 8: 결제 | 39-42 | 포인트 충전, 캐릭터 상점 |
