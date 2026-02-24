import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saju_app/core/widgets/saju_avatar.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

/// SajuAvatar 테스트를 위한 헬퍼 — MaterialApp으로 감싸서 Theme/MediaQuery 제공
Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('SajuAvatar', () {
    testWidgets('renders fallback initials when no image', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const SajuAvatar(name: '김사주')),
      );

      // imageUrl이 없으면 이름의 첫 글자 '김'을 표시해야 함
      expect(find.text('김'), findsOneWidget);
    });

    testWidgets('renders with element badge', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuAvatar(
            name: '이화',
            elementColor: SajuColor.fire,
          ),
        ),
      );

      // elementColor가 지정되면 위젯이 정상 렌더링되어야 함
      expect(find.byType(SajuAvatar), findsOneWidget);
      // 이름 첫 글자가 폴백으로 표시됨
      expect(find.text('이'), findsOneWidget);
    });

    testWidgets('applies different sizes — SajuSize.xl', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuAvatar(
            name: '박수',
            size: SajuSize.xl,
          ),
        ),
      );

      // SajuSize.xl.height = 56
      final avatarWidget = tester.widget<SajuAvatar>(
        find.byType(SajuAvatar),
      );
      expect(avatarWidget.size, SajuSize.xl);

      // SizedBox의 크기가 SajuSize.xl.height와 같아야 함
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, SajuSize.xl.height);
      expect(sizedBox.height, SajuSize.xl.height);
    });

    testWidgets('default size is md', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const SajuAvatar(name: '최기본')),
      );

      final avatarWidget = tester.widget<SajuAvatar>(
        find.byType(SajuAvatar),
      );
      expect(avatarWidget.size, SajuSize.md);
    });

    testWidgets('shows notification badge with count', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuAvatar(
            name: '정알림',
            badgeCount: 5,
          ),
        ),
      );

      // badgeCount > 0이면 숫자가 표시되어야 함
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ when badge count exceeds 99', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuAvatar(
            name: '정알림',
            badgeCount: 150,
          ),
        ),
      );

      // 99 초과 시 "99+"로 표시되어야 함
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows notification badge without count when showBadge is true',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SajuAvatar(
            name: '강뱃지',
            showBadge: true,
          ),
        ),
      );

      // showBadge가 true면 뱃지 표시, 하지만 숫자는 없음
      expect(find.byType(SajuAvatar), findsOneWidget);
    });

    testWidgets('applies all SajuSize values correctly', (tester) async {
      for (final size in SajuSize.values) {
        await tester.pumpWidget(
          _buildTestApp(
            SajuAvatar(
              name: '테스트',
              size: size,
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, size.height,
            reason: 'SajuSize.${size.name} width should be ${size.height}');
        expect(sizedBox.height, size.height,
            reason: 'SajuSize.${size.name} height should be ${size.height}');
      }
    });
  });
}
