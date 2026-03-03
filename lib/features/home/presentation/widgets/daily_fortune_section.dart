import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션 2: 오늘의 연애운
class DailyFortuneSection extends StatelessWidget {
  const DailyFortuneSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.sajuColors;
    // TODO(PROD): 유저 오행에 따라 동적으로 변경
    const elementColor = AppTheme.woodColor;
    const elementPastel = AppTheme.woodPastel;
    final characterAssetPath = CharacterAssets.namuriWoodDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '오늘의 연애운'),
        HomeLayout.gapHeaderContent,
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 캐릭터 + 라벨
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: elementPastel.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Image.asset(
                        characterAssetPath,
                        width: 28,
                        height: 28,
                        errorBuilder: (_, _, _) =>
                            const Text('🌳', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '나무리의 연애운',
                    style: textTheme.titleSmall?.copyWith(
                      color: elementColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 에너지 바
              Row(
                children: [
                  const Text('💘', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '연애 에너지',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.82,
                        minHeight: 6,
                        backgroundColor: Color(0xFFF0EDE8),
                        valueColor: AlwaysStoppedAnimation(elementColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '82%',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 운세 메시지
              Text(
                '오늘은 목(木)의 생기가 강해요.\n자연스러운 대화가 좋은 인연으로 이어질 수 있는 날이에요.',
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              // 하단 칩
              Row(
                children: [
                  _FortuneChip(
                    icon: '🌊',
                    label: '상생 오행',
                    value: '수(水)',
                    color: elementColor,
                    pastel: elementPastel,
                  ),
                  const SizedBox(width: 8),
                  _FortuneChip(
                    icon: '❤️',
                    label: '추천 행동',
                    value: '산책 데이트',
                    color: elementColor,
                    pastel: elementPastel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FortuneChip extends StatelessWidget {
  const _FortuneChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.pastel,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;
  final Color pastel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pastel.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: context.sajuColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
