import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/theme/app_theme.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';
import 'package:saju_app/core/widgets/saju_input.dart';

/// SajuInput 위젯 테스트
///
/// TDD 방식으로 테스트를 먼저 작성하고, 이후 구현체를 작성한다.
void main() {
  /// 테스트용 MaterialApp wrapper
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('SajuInput', () {
    testWidgets('renders with label and hint text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '이름',
            hint: '이름을 입력해주세요',
          ),
        ),
      );

      // 라벨 텍스트가 렌더링되는지 확인
      expect(find.text('이름'), findsOneWidget);

      // 힌트 텍스트가 렌더링되는지 확인
      expect(find.text('이름을 입력해주세요'), findsOneWidget);
    });

    testWidgets('accepts text input via controller', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestWidget(
          SajuInput(
            label: '이름',
            controller: controller,
          ),
        ),
      );

      // TextField를 찾아서 텍스트 입력
      await tester.enterText(find.byType(TextField), '홍길동');
      await tester.pump();

      // controller를 통해 입력 값 확인
      expect(controller.text, '홍길동');

      controller.dispose();
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '이름',
            errorText: '필수 입력입니다',
          ),
        ),
      );

      // 에러 메시지가 렌더링되는지 확인
      expect(find.text('필수 입력입니다'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        buildTestWidget(
          SajuInput(
            label: '이름',
            onChanged: (value) => changedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '테스트');
      await tester.pump();

      expect(changedValue, '테스트');
    });

    testWidgets('renders with prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '검색',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '이름',
            enabled: false,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '큰 입력',
            size: SajuSize.lg,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      // lg size의 fontSize는 16
      expect(textField.style?.fontSize, SajuSize.lg.fontSize);
    });

    testWidgets('hides maxLength counter', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '이름',
            maxLength: 20,
          ),
        ),
      );

      // maxLength가 설정되었지만 카운터 텍스트는 숨겨져야 함
      // "0/20" 같은 카운터 텍스트가 없어야 한다
      expect(find.textContaining('/20'), findsNothing);
    });

    testWidgets('label has correct style (w600, fontSize * 0.9)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SajuInput(
            label: '라벨 스타일',
            size: SajuSize.md,
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('라벨 스타일'));
      expect(labelText.style?.fontWeight, FontWeight.w600);
      // md fontSize=14, 0.9배 = 12.6
      expect(labelText.style?.fontSize, SajuSize.md.fontSize * 0.9);
    });
  });
}
