import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// 홈 섹션 1: 인사 + 캐릭터
///
/// ```
/// 오늘의 인연을          [나무리]
/// 만나봐요                64×64
/// 사주가 이끄는 운명적 만남
/// ```
class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 인연을\n만나봐요',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '사주가 이끄는 운명적 만남',
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        Image.asset(
          CharacterAssets.namuriWoodDefault,
          width: 64,
          height: 64,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
