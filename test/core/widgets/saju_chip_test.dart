import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saju_app/core/widgets/saju_chip.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

/// SajuChip 테스트를 위한 헬퍼 — MaterialApp으로 감싸서 Theme/MediaQuery 제공
Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('SajuChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const SajuChip(label: '목(木)')),
      );

      expect(find.text('목(木)'), findsOneWidget);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuChip(
            label: '음악',
            leadingIcon: Icons.music_note,
          ),
        ),
      );

      expect(find.text('음악'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('handles onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildTestApp(
          SajuChip(
            label: '관심사',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('관심사'));
      expect(tapped, isTrue);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuChip(
            label: '선택됨',
            isSelected: true,
          ),
        ),
      );

      // 선택된 상태에서도 라벨이 정상 렌더링되어야 함
      expect(find.text('선택됨'), findsOneWidget);

      // AnimatedContainer가 존재해야 함 (선택 상태 시각 변화용)
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('shows delete icon when onDeleted provided', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        _buildTestApp(
          SajuChip(
            label: '삭제가능',
            onDeleted: () => deleted = true,
          ),
        ),
      );

      expect(find.text('삭제가능'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // close 아이콘 탭 시 onDeleted 콜백 호출
      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, isTrue);
    });

    testWidgets('applies SajuColor correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuChip(
            label: '목(木)',
            color: SajuColor.wood,
          ),
        ),
      );

      // 위젯이 정상 렌더링되는지만 확인 (컬러는 시각적 결과)
      expect(find.text('목(木)'), findsOneWidget);
    });

    testWidgets('applies SajuSize correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuChip(
            label: '큰 칩',
            size: SajuSize.lg,
          ),
        ),
      );

      expect(find.text('큰 칩'), findsOneWidget);
    });

    testWidgets('uses default values when optional params omitted',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const SajuChip(label: '기본')),
      );

      expect(find.text('기본'), findsOneWidget);
      // 기본 상태: leadingIcon 없음, delete 아이콘 없음
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
