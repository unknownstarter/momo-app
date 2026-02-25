import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/saju_entity.dart';

/// PillarCard -- 사주 기둥(柱) 카드 위젯
///
/// 연주/월주/일주/시주 한 기둥의 정보를 세로 카드 형태로 표시한다.
/// 4개를 나란히 배치하면 사주팔자(四柱八字) 전체를 한눈에 볼 수 있다.
///
/// ```dart
/// PillarCard(
///   pillar: profile.yearPillar,
///   label: '연주',
///   sublabel: '年柱',
/// )
/// ```
class PillarCard extends StatelessWidget {
  const PillarCard({
    super.key,
    this.pillar,
    required this.label,
    required this.sublabel,
    this.isMissing = false,
  });

  /// 기둥 데이터. null이면 [isMissing] 모드로 "?" 표시
  final Pillar? pillar;

  /// 기둥 라벨 (예: "연주", "월주", "일주", "시주")
  final String label;

  /// 기둥 한자 라벨 (예: "年柱", "月柱", "日柱", "時柱")
  final String sublabel;

  /// 시주 미입력 등의 이유로 기둥 데이터가 없을 때 true
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectivePillar = pillar;
    final hasPillar = effectivePillar != null && !isMissing;

    // 오행 컬러 결정
    final stemElement = hasPillar ? effectivePillar.stemElement : null;
    final elementColor = stemElement != null
        ? AppTheme.fiveElementColor(stemElement.korean)
        : AppTheme.metalColor;
    final elementPastel = stemElement != null
        ? AppTheme.fiveElementPastel(stemElement.korean)
        : AppTheme.metalPastel;

    // SajuColor 매핑 (뱃지용)
    final sajuColor = _toSajuColor(stemElement);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space8,
        vertical: SajuSpacing.space16,
      ),
      decoration: BoxDecoration(
        color: elementPastel.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: elementColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨 (연주/월주/일주/시주)
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: elementColor,
            ),
          ),
          Text(
            sublabel,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: elementColor.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: SajuSpacing.space8),

          // 천간 한자 (큰 글씨)
          Text(
            hasPillar ? effectivePillar.heavenlyStemHanja : '?',
            style: textTheme.displaySmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: hasPillar
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : elementColor.withValues(alpha: 0.3),
              height: 1.2,
            ),
          ),

          // 지지 한자
          Text(
            hasPillar ? effectivePillar.earthlyBranchHanja : '?',
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: hasPillar
                  ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8)
                  : elementColor.withValues(alpha: 0.2),
              height: 1.2,
            ),
          ),

          const SizedBox(height: SajuSpacing.space4),

          // 한글 표기 (예: "갑자")
          Text(
            hasPillar ? effectivePillar.korean : '모름',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: hasPillar
                  ? Theme.of(context).textTheme.bodySmall?.color
                  : elementColor.withValues(alpha: 0.4),
            ),
          ),

          const SizedBox(height: SajuSpacing.space8),

          // 오행 뱃지
          if (hasPillar && stemElement != null)
            SajuBadge(
              label: '${stemElement.korean}(${stemElement.hanja})',
              color: sajuColor,
              size: SajuSize.xs,
            )
          else
            SajuBadge(
              label: '미상',
              color: SajuColor.metal,
              size: SajuSize.xs,
            ),
        ],
      ),
    );
  }

  /// FiveElementType을 SajuColor로 변환
  SajuColor _toSajuColor(FiveElementType? element) {
    return switch (element) {
      FiveElementType.wood => SajuColor.wood,
      FiveElementType.fire => SajuColor.fire,
      FiveElementType.earth => SajuColor.earth,
      FiveElementType.metal => SajuColor.metal,
      FiveElementType.water => SajuColor.water,
      null => SajuColor.metal,
    };
  }
}
