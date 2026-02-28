import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/saju_entity.dart';
import '../providers/saju_provider.dart';
import '../widgets/five_elements_chart.dart';
import '../widgets/pillar_card.dart';

/// SajuResultPage -- 사주 분석 결과 화면
///
/// 라이트 모드(한지 배경)에서 사주 프로필 결과를 보여준다.
/// 진입 시 스태거드 페이드인으로 "결과가 공개되는" 와우 모먼트 연출.
///
/// 레이아웃:
/// 1. 배정 캐릭터 + 이름/오행 뱃지
/// 2. 캐릭터 인사 말풍선
/// 3. 사주 4기둥 카드
/// 4. 오행 분포 차트
/// 5. 성격 특성 칩
/// 6. AI 해석 카드
/// 7. 액션 버튼 (공유 + 홈)
class SajuResultPage extends ConsumerWidget {
  const SajuResultPage({
    super.key,
    this.result,
  });

  /// 직접 전달받은 분석 결과 (GoRouter extra)
  final SajuAnalysisResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisResult =
        result ?? ref.watch(sajuAnalysisNotifierProvider).valueOrNull;

    if (analysisResult == null) {
      return _buildNoDataState(context);
    }

    final profile = analysisResult.profile;
    final elementColor = _toSajuColor(profile.dominantElement);
    final elementColorValue = profile.dominantElement != null
        ? AppTheme.fiveElementColor(profile.dominantElement!.korean)
        : AppTheme.metalColor;
    final elementPastelValue = profile.dominantElement != null
        ? AppTheme.fiveElementPastel(profile.dominantElement!.korean)
        : AppTheme.metalPastel;

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: context.sajuColors.bgPrimary,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: const SizedBox.shrink(),
              actions: [
                IconButton(
                  onPressed: () => context.go(RoutePaths.home),
                  icon: Icon(
                    Icons.close,
                    color: const Color(0xFF4A4F54),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SajuSpacing.space24,
                ),
                child: _ResultRevealContent(
                  sections: [
                    () => _buildHeader(
                      context,
                      analysisResult,
                      elementColor,
                      elementColorValue,
                      elementPastelValue,
                    ),
                    () => SajuCharacterBubble(
                      characterName: analysisResult.characterName,
                      message: analysisResult.characterGreeting,
                      elementColor: elementColor,
                      characterAssetPath: analysisResult.characterAssetPath,
                      size: SajuSize.md,
                    ),
                    () => _buildPillarsSection(context, profile),
                    () => _buildFiveElementsSection(context, profile),
                    if (profile.personalityTraits.isNotEmpty)
                      () => _buildPersonalitySection(
                        context,
                        profile,
                        elementColor,
                      ),
                    if (profile.aiInterpretation != null &&
                        profile.aiInterpretation!.isNotEmpty)
                      () => _buildAiInterpretationSection(
                        context,
                        profile,
                        elementColor,
                        elementColorValue,
                      ),
                    () => _buildActions(context, elementColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. 헤더
  // ===========================================================================

  Widget _buildHeader(
    BuildContext context,
    SajuAnalysisResult result,
    SajuColor elementColor,
    Color elementColorValue,
    Color elementPastelValue,
  ) {
    final profile = result.profile;

    return Column(
      children: [
        // 파스텔 그라디언트 배경 원
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                elementPastelValue,
                elementPastelValue.withValues(alpha: 0.3),
              ],
            ),
            border: Border.all(
              color: elementColorValue.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              result.characterAssetPath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  result.characterName.characters.first,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: elementColorValue,
                  ),
                ),
              ),
            ),
          ),
        ),

        SajuSpacing.gap16,

        // 캐릭터 이름 뱃지
        SajuBadge(
          label: result.characterName,
          color: elementColor,
          size: SajuSize.md,
        ),

        SajuSpacing.gap8,

        // 오행 뱃지
        if (profile.dominantElement != null)
          SajuBadge(
            label: '${profile.dominantElement!.korean}(${profile.dominantElement!.hanja}) 기운',
            color: elementColor,
            size: SajuSize.sm,
            icon: Icons.auto_awesome,
          ),

        SajuSpacing.gap8,

        // 사주 요약 텍스트
        Text(
          profile.summary,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF4A4F54),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. 사주 4기둥
  // ===========================================================================

  Widget _buildPillarsSection(BuildContext context, SajuProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        _buildSectionTitle(context, '사주팔자 (四柱八字)'),
        SajuSpacing.gap16,

        // 4기둥 카드 Row
        Row(
          children: [
            Expanded(
              child: PillarCard(
                pillar: profile.yearPillar,
                label: '연주',
                sublabel: '年柱',
              ),
            ),
            SajuSpacing.hGap8,
            Expanded(
              child: PillarCard(
                pillar: profile.monthPillar,
                label: '월주',
                sublabel: '月柱',
              ),
            ),
            SajuSpacing.hGap8,
            Expanded(
              child: PillarCard(
                pillar: profile.dayPillar,
                label: '일주',
                sublabel: '日柱',
              ),
            ),
            SajuSpacing.hGap8,
            Expanded(
              child: PillarCard(
                pillar: profile.hourPillar,
                label: '시주',
                sublabel: '時柱',
                isMissing: profile.hourPillar == null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. 오행 분포
  // ===========================================================================

  Widget _buildFiveElementsSection(BuildContext context, SajuProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '오행 분포 (五行)'),
        SajuSpacing.gap8,

        // 균형 점수
        Row(
          children: [
            Text(
              '균형 점수',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SajuSpacing.hGap8,
            Text(
              '${profile.fiveElements.balanceScore}점',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.fiveElementColor(
                  profile.fiveElements.dominant.korean,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SajuSpacing.gap16,

        // 차트
        SajuCard(
          variant: SajuVariant.flat,
          content: FiveElementsChart(
            fiveElements: profile.fiveElements,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. 성격 특성
  // ===========================================================================

  Widget _buildPersonalitySection(
    BuildContext context,
    SajuProfile profile,
    SajuColor elementColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '성격 특성'),
        SajuSpacing.gap16,
        Wrap(
          spacing: SajuSpacing.space8,
          runSpacing: SajuSpacing.space8,
          children: profile.personalityTraits.map((trait) {
            return SajuChip(
              label: trait,
              color: elementColor,
              size: SajuSize.sm,
              isSelected: true,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. AI 해석
  // ===========================================================================

  Widget _buildAiInterpretationSection(
    BuildContext context,
    SajuProfile profile,
    SajuColor elementColor,
    Color elementColorValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'AI 사주 해석'),
        SajuSpacing.gap16,
        SajuCard(
          variant: SajuVariant.elevated,
          borderColor: elementColorValue.withValues(alpha: 0.2),
          content: Text(
            profile.aiInterpretation!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: context.sajuColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. 액션 버튼
  // ===========================================================================

  Widget _buildActions(BuildContext context, SajuColor elementColor) {
    return Column(
      children: [
        SajuButton(
          label: '내 사주와 찰떡인 사람, 만나볼까요?',
          onPressed: () => context.go(
            RoutePaths.matchingProfile,
            extra: {'quickMode': true},
          ),
          variant: SajuVariant.filled,
          color: elementColor,
          size: SajuSize.lg,
          leadingIcon: Icons.favorite_outlined,
        ),
        SajuSpacing.gap16,
        SajuButton(
          label: '내 사주 공유하기',
          onPressed: () {
            // TODO: 공유 기능 구현
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('공유 기능은 준비 중이에요!')),
            );
          },
          variant: SajuVariant.outlined,
          color: elementColor,
          size: SajuSize.lg,
          leadingIcon: Icons.share_outlined,
        ),
        SajuSpacing.gap8,
        SajuButton(
          label: '나중에 할게요',
          onPressed: () => context.go(RoutePaths.home),
          variant: SajuVariant.ghost,
          color: SajuColor.primary,
          size: SajuSize.sm,
        ),
      ],
    );
  }

  // ===========================================================================
  // 헬퍼
  // ===========================================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: context.sajuColors.textPrimary,
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: context.sajuColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.metalColor.withValues(alpha: 0.5),
              ),
              SajuSpacing.gap16,
              Text(
                '분석 결과를 찾을 수 없어요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A4F54),
                ),
              ),
              SajuSpacing.gap32,
              SajuButton(
                label: '홈으로 돌아가기',
                onPressed: () => context.go(RoutePaths.home),
                color: SajuColor.primary,
                size: SajuSize.lg,
              ),
            ],
          ),
        ),
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

// =============================================================================
// 스태거드 리빌 컨테이너 (와우 모먼트)
// =============================================================================

class _ResultRevealContent extends StatefulWidget {
  const _ResultRevealContent({required this.sections});

  final List<Widget Function()> sections;

  @override
  State<_ResultRevealContent> createState() => _ResultRevealContentState();
}

class _ResultRevealContentState extends State<_ResultRevealContent>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1400);
  static const _stagger = 0.14;

  late final AnimationController _controller;
  late final List<Animation<double>> _fades;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _fades = List.generate(
      widget.sections.length,
      (i) {
        final start = (i * _stagger).clamp(0.0, 0.85);
        final end = (start + 0.35).clamp(0.0, 1.0);
        return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );
      },
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.sections.length; i++) ...[
          FadeTransition(
            opacity: _fades[i],
            child: widget.sections[i](),
          ),
          if (i < widget.sections.length - 1)
            SizedBox(
              height: i == 0
                  ? SajuSpacing.space24
                  : (i == 1 ? SajuSpacing.space32 : SajuSpacing.space32),
            ),
        ],
        const SizedBox(height: SajuSpacing.space48),
      ],
    );
  }
}
