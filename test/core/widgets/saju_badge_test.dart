import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saju_app/core/widgets/saju_badge.dart';
import 'package:saju_app/core/widgets/saju_enums.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('SajuBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuBadge(label: '천생연분'),
      ));
      expect(find.text('천생연분'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuBadge(
          label: '프리미엄',
          icon: Icons.star,
          color: SajuColor.fire,
        ),
      ));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('프리미엄'), findsOneWidget);
    });

    testWidgets('renders without icon', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuBadge(label: '좋은 인연'),
      ));
      expect(find.byType(Icon), findsNothing);
      expect(find.text('좋은 인연'), findsOneWidget);
    });

    testWidgets('applies different sizes', (tester) async {
      await tester.pumpWidget(buildApp(
        child: const SajuBadge(
          label: 'XS',
          size: SajuSize.xs,
        ),
      ));
      expect(find.text('XS'), findsOneWidget);
    });

    testWidgets('applies different colors', (tester) async {
      for (final color in SajuColor.values) {
        await tester.pumpWidget(buildApp(
          child: SajuBadge(label: color.name, color: color),
        ));
        expect(find.text(color.name), findsOneWidget);
      }
    });
  });
}
