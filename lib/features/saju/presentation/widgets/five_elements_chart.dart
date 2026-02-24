import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/saju_entity.dart';

/// FiveElementsChart -- 오행 분포 수평 바 차트
///
/// [FiveElements] 데이터를 받아 각 오행별 수평 바를 렌더링한다.
/// 바 너비는 전체 합 대비 비율에 따라 결정되며,
/// 최초 빌드 시 0에서 최종 값까지 600ms 애니메이션이 적용된다.
///
/// ```dart
/// FiveElementsChart(fiveElements: profile.fiveElements)
/// ```
class FiveElementsChart extends StatefulWidget {
  const FiveElementsChart({
    super.key,
    required this.fiveElements,
  });

  /// 오행 분포 데이터
  final FiveElements fiveElements;

  @override
  State<FiveElementsChart> createState() => _FiveElementsChartState();
}

class _FiveElementsChartState extends State<FiveElementsChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // 첫 프레임 이후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elements = widget.fiveElements;
    final entries = <_ElementEntry>[
      _ElementEntry(FiveElementType.wood, elements.wood, AppTheme.woodColor, AppTheme.woodPastel),
      _ElementEntry(FiveElementType.fire, elements.fire, AppTheme.fireColor, AppTheme.firePastel),
      _ElementEntry(FiveElementType.earth, elements.earth, AppTheme.earthColor, AppTheme.earthPastel),
      _ElementEntry(FiveElementType.metal, elements.metal, AppTheme.metalColor, AppTheme.metalPastel),
      _ElementEntry(FiveElementType.water, elements.water, AppTheme.waterColor, AppTheme.waterPastel),
    ];

    final total = elements.total;
    final maxCount = entries.fold<int>(0, (prev, e) => e.count > prev ? e.count : prev);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
              child: _buildBar(context, entry, total, maxCount),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    _ElementEntry entry,
    int total,
    int maxCount,
  ) {
    // 비율 계산: maxCount 기준으로 바 너비를 정한다
    final ratio = maxCount > 0 ? entry.count / maxCount : 0.0;
    final animatedRatio = ratio * _animation.value;

    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // 오행 라벨 (한글 + 한자)
        SizedBox(
          width: 56,
          child: Row(
            children: [
              // 오행 색상 원
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.type.korean}(${entry.type.hanja})',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppTheme.spacingSm),

        // 바 영역
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * animatedRatio;
              return Stack(
                children: [
                  // 트랙 (파스텔 배경)
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: entry.pastel.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // 채워진 바
                  Container(
                    height: 20,
                    width: barWidth.clamp(0.0, constraints.maxWidth),
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(width: AppTheme.spacingSm),

        // 수치
        SizedBox(
          width: 24,
          child: Text(
            '${entry.count}',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: entry.color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// 내부용 오행 항목 데이터
class _ElementEntry {
  const _ElementEntry(this.type, this.count, this.color, this.pastel);

  final FiveElementType type;
  final int count;
  final Color color;
  final Color pastel;
}
