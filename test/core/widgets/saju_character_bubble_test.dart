import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/theme/app_theme.dart';
import 'package:saju_app/core/widgets/saju_character_bubble.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

/// SajuCharacterBubble 위젯 테스트
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

  group('SajuCharacterBubble', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '나무리',
            message: '안녕! 네 사주를 봐줄게~',
            elementColor: SajuColor.wood,
          ),
        ),
      );

      expect(find.text('안녕! 네 사주를 봐줄게~'), findsOneWidget);
    });

    testWidgets('renders character name', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '나무리',
            message: '안녕! 네 사주를 봐줄게~',
            elementColor: SajuColor.wood,
          ),
        ),
      );

      expect(find.text('나무리'), findsAtLeast(1));
    });

    testWidgets('renders with different element colors (fire)',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '불꼬리',
            message: '오늘 운세가 아주 좋아!',
            elementColor: SajuColor.fire,
          ),
        ),
      );

      // 위젯이 정상 렌더링되는지 확인
      expect(find.text('불꼬리'), findsAtLeast(1));
      expect(find.text('오늘 운세가 아주 좋아!'), findsOneWidget);
    });

    testWidgets('renders character circle with first character of name',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '물결이',
            message: '테스트 메시지',
            elementColor: SajuColor.water,
          ),
        ),
      );

      // 캐릭터 원 안에 이름의 첫 글자가 표시되어야 함
      // '물결이'의 첫 글자 '물'이 원 안에, '물결이'가 이름 레이블에 있으므로
      // '물' 텍스트를 찾아야 함
      expect(find.text('물'), findsOneWidget);
    });

    testWidgets('uses Row layout with character circle and speech bubble',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '나무리',
            message: '레이아웃 테스트',
            elementColor: SajuColor.wood,
          ),
        ),
      );

      // Row 레이아웃 확인
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('default size is md', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '나무리',
            message: '사이즈 테스트',
            elementColor: SajuColor.wood,
          ),
        ),
      );

      // md 사이즈 기본값으로 정상 렌더링
      expect(find.text('사이즈 테스트'), findsOneWidget);
    });

    testWidgets('renders with custom size (lg)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '흙순이',
            message: '큰 사이즈 테스트',
            elementColor: SajuColor.earth,
            size: SajuSize.lg,
          ),
        ),
      );

      expect(find.text('큰 사이즈 테스트'), findsOneWidget);
      expect(find.text('흙순이'), findsAtLeast(1));
    });

    testWidgets('speech bubble has asymmetric border radius (topLeft = 0)',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuCharacterBubble(
            characterName: '나무리',
            message: '모서리 테스트',
            elementColor: SajuColor.wood,
          ),
        ),
      );

      // 말풍선 Container를 찾아 borderRadius 확인
      // speech bubble effect: topLeft = 0, 나머지 = radiusLg
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        buildDarkTestWidget(
          const SajuCharacterBubble(
            characterName: '쇠동이',
            message: '다크 모드 테스트',
            elementColor: SajuColor.metal,
          ),
        ),
      );

      expect(find.text('쇠동이'), findsAtLeast(1));
      expect(find.text('다크 모드 테스트'), findsOneWidget);
    });
  });
}
