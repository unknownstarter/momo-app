import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/theme/app_theme.dart';
import 'package:saju_app/core/widgets/saju_card.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

/// SajuCard 위젯 테스트
///
/// TDD 방식으로 테스트를 먼저 작성하고, 이후 구현체를 작성한다.
void main() {
  /// 테스트용 MaterialApp wrapper (라이트 모드)
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  /// 테스트용 MaterialApp wrapper (다크 모드)
  Widget buildDarkTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(body: child),
    );
  }

  group('SajuCard', () {
    testWidgets('renders header, content, and footer', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            header: const Text('헤더 텍스트'),
            content: const Text('본문 텍스트'),
            footer: const Text('푸터 텍스트'),
          ),
        ),
      );

      expect(find.text('헤더 텍스트'), findsOneWidget);
      expect(find.text('본문 텍스트'), findsOneWidget);
      expect(find.text('푸터 텍스트'), findsOneWidget);
    });

    testWidgets('renders content only (no header/footer)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('본문만'),
          ),
        ),
      );

      expect(find.text('본문만'), findsOneWidget);
      // header/footer가 없으면 spacer도 렌더링되지 않아야 함
      // SizedBox로 spacing을 구현하므로, header/footer 없이는 spacing도 없어야 함
    });

    testWidgets('handles onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('탭 테스트'),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('탭 테스트'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('탭 없음'),
          ),
        ),
      );

      // Should not throw when tapped without onTap
      await tester.tap(find.text('탭 없음'));
      await tester.pump();
    });

    testWidgets('uses default elevated variant', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('기본 변형'),
          ),
        ),
      );

      // elevated variant는 그림자가 있어야 함 — AnimatedContainer를 찾아 decoration 확인
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('filled variant has white background in light mode',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('filled'),
            variant: SajuVariant.filled,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
    });

    testWidgets('outlined variant has transparent background and border',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('outlined'),
            variant: SajuVariant.outlined,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.transparent));
      expect(decoration.border, isNotNull);
    });

    testWidgets('flat/ghost variant has subtle background', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('flat'),
            variant: SajuVariant.flat,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      // flat은 black 2% alpha 배경
      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white));
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(24);

      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('패딩 테스트'),
            padding: customPadding,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      // AnimatedContainer의 padding 확인
      expect(container.padding, equals(customPadding));
    });

    testWidgets('applies borderColor when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('border 테스트'),
            variant: SajuVariant.filled,
            borderColor: Colors.red,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      // border 색상이 red인지 확인
      final border = decoration.border as Border;
      expect(border.top.color, equals(Colors.red));
    });

    testWidgets('uses radiusLg (16) for border radius', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('radius 테스트'),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(AppTheme.radiusLg)),
      );
    });

    testWidgets('wraps content in GestureDetector', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('gesture 테스트'),
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('uses Column with CrossAxisAlignment.start', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            header: const Text('헤더'),
            content: const Text('본문'),
            footer: const Text('푸터'),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.crossAxisAlignment, equals(CrossAxisAlignment.start));
      expect(column.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('dark mode: filled variant uses dark card color',
        (tester) async {
      await tester.pumpWidget(
        buildDarkTestWidget(
          SajuCard(
            content: const Text('dark filled'),
            variant: SajuVariant.filled,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF35363F)));
    });

    testWidgets('dark mode: outlined variant uses dark border color',
        (tester) async {
      await tester.pumpWidget(
        buildDarkTestWidget(
          SajuCard(
            content: const Text('dark outlined'),
            variant: SajuVariant.outlined,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, equals(const Color(0xFF45464F)));
    });

    testWidgets('ghost variant has same style as flat', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuCard(
            content: const Text('ghost'),
            variant: SajuVariant.ghost,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      // ghost는 flat과 동일: subtle background
      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white));
      expect(decoration.color, isNot(Colors.transparent));
    });
  });
}
