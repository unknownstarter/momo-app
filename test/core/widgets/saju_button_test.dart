import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/theme/app_theme.dart';
import 'package:saju_app/core/widgets/saju_button.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

/// SajuButton 위젯 테스트
///
/// TDD 방식으로 테스트를 먼저 작성하고, 이후 구현체를 작성한다.
void main() {
  /// 테스트용 MaterialApp wrapper
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  group('SajuButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '테스트 버튼',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('테스트 버튼'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '탭 테스트',
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('탭 테스트'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuButton(
            label: '비활성 버튼',
            onPressed: null,
          ),
        ),
      );

      // Find the underlying button widget and check it's disabled
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '아이콘 버튼',
            onPressed: () {},
            leadingIcon: Icons.favorite,
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('아이콘 버튼'), findsOneWidget);
    });

    testWidgets('respects size parameter (sm size has correct minimum height)',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '작은 버튼',
            onPressed: () {},
            size: SajuSize.sm,
          ),
        ),
      );

      // SajuSize.sm.height == 32
      // The rendered widget height should be at least 32
      final sizeOfWidget = tester.getSize(find.byType(SajuButton));
      expect(sizeOfWidget.height, greaterThanOrEqualTo(SajuSize.sm.height));
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '로딩 중',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables tap when isLoading is true', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '로딩 중',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(SajuButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('outlined variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '아웃라인',
            onPressed: () {},
            variant: SajuVariant.outlined,
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('flat variant renders TextButton', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '플랫',
            onPressed: () {},
            variant: SajuVariant.flat,
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('ghost variant renders TextButton', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '고스트',
            onPressed: () {},
            variant: SajuVariant.ghost,
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('expand false makes button shrink-wrap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Center(
            child: SajuButton(
              label: '축소',
              onPressed: () {},
              expand: false,
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(SajuButton));
      // Shrink-wrapped button should be less than full screen width
      final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
      expect(buttonSize.width, lessThan(screenWidth));
    });

    testWidgets('expand true makes button fill width', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SajuButton(
            label: '확장',
            onPressed: () {},
            expand: true,
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(SajuButton));
      // Scaffold body spans the full width
      final scaffoldSize = tester.getSize(find.byType(Scaffold));
      expect(buttonSize.width, equals(scaffoldSize.width));
    });
  });
}
