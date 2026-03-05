/// 통합 결과 페이지 — TabBar [사주 | 관상]
///
/// 사주 결과와 관상 결과를 하나의 페이지에서 탭으로 전환하며 보여준다.
/// 공통 헤더(캐릭터 + 동물상)와 통합 CTA를 제공한다.
///
/// **구조:**
/// ```
/// ┌─────────────────────────────────┐
/// │ 공통 헤더: 캐릭터 + 동물상      │
/// ├───────────┬─────────────────────┤
/// │  사주 탭  │   관상 탭           │
/// ├───────────┴─────────────────────┤
/// │ TabBarView (사주/관상 콘텐츠)   │
/// ├─────────────────────────────────┤
/// │ 통합 CTA: 운명의 인연 찾기      │
/// └─────────────────────────────────┘
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/presentation/providers/saju_provider.dart';
import '../../../saju/presentation/widgets/five_elements_chart.dart';
import '../../../saju/presentation/widgets/pillar_card.dart';

/// 통합 결과 페이지
class DestinyResultPage extends ConsumerStatefulWidget {
  const DestinyResultPage({
    super.key,
    this.sajuResult,
    this.gwansangResult,
  });

  final dynamic sajuResult;
  final dynamic gwansangResult;

  @override
  ConsumerState<DestinyResultPage> createState() => _DestinyResultPageState();
}

class _DestinyResultPageState extends ConsumerState<DestinyResultPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  SajuAnalysisResult? get _sajuResult {
    if (widget.sajuResult is SajuAnalysisResult) {
      return widget.sajuResult as SajuAnalysisResult;
    }
    return null;
  }

  GwansangAnalysisResult? get _gwansangResult {
    if (widget.gwansangResult is GwansangAnalysisResult) {
      return widget.gwansangResult as GwansangAnalysisResult;
    }
    return null;
  }

  GwansangProfile? get _gwansangProfile => _gwansangResult?.profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sajuResult == null) {
      return _buildNoDataState(context);
    }

    final sajuProfile = _sajuResult!.profile;
    final elementColor = _toSajuColor(sajuProfile.dominantElement);

    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            body: SafeArea(
              bottom: false,
              child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // 상단 여백 (닫기 버튼 영역 유지)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 48),
                ),

                // 공통 헤더
                SliverToBoxAdapter(
                  child: _buildHero(context, colors, elementColor),
                ),

                // TabBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      indicatorColor: elementColor.resolve(context),
                      indicatorWeight: 3,
                      labelColor: colors.textPrimary,
                      unselectedLabelColor: colors.textTertiary,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: const [
                        Tab(text: '사주'),
                        Tab(text: '관상'),
                      ],
                    ),
                    backgroundColor: colors.bgPrimary,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: 사주
                  _SajuTab(
                    result: _sajuResult!,
                    elementColor: elementColor,
                  ),

                  // Tab 2: 관상
                  _GwansangTab(
                    profile: _gwansangProfile,
                    hasResult: _gwansangResult != null,
                  ),
                ],
              ),
            ),
            ),

            // 하단 CTA
            bottomNavigationBar: _buildBottomCta(context, elementColor),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 공통 헤더 — 캐릭터 + 동물상
  // ===========================================================================

  Widget _buildHero(
    BuildContext context,
    SajuColors colors,
    SajuColor elementColor,
  ) {
    final sajuProfile = _sajuResult!.profile;
    final elementColorValue = sajuProfile.dominantElement != null
        ? AppTheme.fiveElementColor(sajuProfile.dominantElement!.korean)
        : AppTheme.metalColor;
    final elementPastelValue = sajuProfile.dominantElement != null
        ? AppTheme.fiveElementPastel(sajuProfile.dominantElement!.korean)
        : AppTheme.metalPastel;

    final gwansang = _gwansangProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        children: [
          // 캐릭터 + 동물상 이모지 겹침
          SizedBox(
            width: 140,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 오행 캐릭터
                Positioned(
                  left: 10,
                  child: Container(
                    width: 96,
                    height: 96,
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
                        _sajuResult!.characterAssetPath,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            _sajuResult!.characterName.characters.first,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: elementColorValue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 동물상 배지
                if (gwansang != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: colors.bgPrimary,
                        border: Border.all(
                          color: AppTheme.mysticGlow.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${gwansang.animalTypeKorean}상',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SajuSpacing.gap12,

          // 이름 + 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SajuBadge(
                label: _sajuResult!.characterName,
                color: elementColor,
                size: SajuSize.sm,
              ),
              if (gwansang != null) ...[
                SajuSpacing.hGap8,
                SajuBadge(
                  label: gwansang.animalLabel,
                  color: SajuColor.primary,
                  size: SajuSize.sm,
                ),
              ],
            ],
          ),

          SajuSpacing.gap8,

          // 타이틀
          Text(
            _sajuResult!.profile.summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  letterSpacing: 1,
                ),
            textAlign: TextAlign.center,
          ),

          SajuSpacing.gap16,
        ],
      ),
    );
  }

  // ===========================================================================
  // 하단 CTA
  // ===========================================================================

  Widget _buildBottomCta(BuildContext context, SajuColor elementColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SajuSpacing.space24,
        SajuSpacing.space8,
        SajuSpacing.space24,
        SajuSpacing.space16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SajuButton(
          label: '내 사주와 찰떡인 사람, 만나볼까요?',
          onPressed: () {
            AnalyticsService.clickFindMatchesInDestinyResult();
            context.push(
              RoutePaths.matchingProfile,
            );
          },
          variant: SajuVariant.filled,
          color: elementColor,
          size: SajuSize.xl,
          leadingIcon: Icons.favorite_outlined,
        ),
      ),
    );
  }

  // ===========================================================================
  // No Data
  // ===========================================================================

  Widget _buildNoDataState(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3EE),
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
// TabBar Delegate (SliverPersistentHeader용)
// =============================================================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

// =============================================================================
// 사주 탭
// =============================================================================

class _SajuTab extends StatelessWidget {
  const _SajuTab({
    required this.result,
    required this.elementColor,
  });

  final SajuAnalysisResult result;
  final SajuColor elementColor;

  @override
  Widget build(BuildContext context) {
    final profile = result.profile;
    final elementColorValue = profile.dominantElement != null
        ? AppTheme.fiveElementColor(profile.dominantElement!.korean)
        : AppTheme.metalColor;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space24,
        vertical: SajuSpacing.space24,
      ),
      children: [
        // 캐릭터 인사
        SajuCharacterBubble(
          characterName: result.characterName,
          message: result.characterGreeting,
          elementColor: elementColor,
          characterAssetPath: result.characterAssetPath,
          size: SajuSize.md,
        ),
        SajuSpacing.gap32,

        // 사주 4기둥
        _buildSectionTitle(context, '사주팔자 (四柱八字)'),
        SajuSpacing.gap16,
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
        SajuSpacing.gap32,

        // 오행 분포
        _buildSectionTitle(context, '오행 분포 (五行)'),
        SajuSpacing.gap8,
        Row(
          children: [
            Text('균형 점수', style: Theme.of(context).textTheme.bodySmall),
            SajuSpacing.hGap8,
            Text(
              '${profile.fiveElements.balanceScore}점',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: elementColorValue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        SajuSpacing.gap16,
        SajuCard(
          variant: SajuVariant.flat,
          content: FiveElementsChart(fiveElements: profile.fiveElements),
        ),
        SajuSpacing.gap32,

        // 성격 특성
        if (profile.personalityTraits.isNotEmpty) ...[
          _buildSectionTitle(context, '성격 특성'),
          SajuSpacing.gap16,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.personalityTraits.map((trait) {
              final elementColorValue = profile.dominantElement != null
                  ? AppTheme.fiveElementColor(profile.dominantElement!.korean)
                  : AppTheme.metalColor;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: elementColorValue.withValues(alpha: 0.3),
                  ),
                  color: elementColorValue.withValues(alpha: 0.06),
                ),
                child: Text(
                  trait,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.sajuColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          SajuSpacing.gap32,
        ],

        // AI 해석
        if (profile.aiInterpretation != null &&
            profile.aiInterpretation!.isNotEmpty) ...[
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
          SajuSpacing.gap32,
        ],

        // 하단 여백
        const SizedBox(height: SajuSpacing.space48),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.sajuColors.textPrimary,
          ),
    );
  }
}

// =============================================================================
// 관상 탭
// =============================================================================

class _GwansangTab extends StatelessWidget {
  const _GwansangTab({
    required this.profile,
    required this.hasResult,
  });

  final GwansangProfile? profile;
  final bool hasResult;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;

    // 관상 분석 실패 시 안내 UI
    if (profile == null) {
      return _buildFailureState(context, colors);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space24,
        vertical: SajuSpacing.space24,
      ),
      children: [
        // 동물상 히어로
        _buildAnimalHero(context, colors),
        SajuSpacing.gap16,

        // 헤드라인
        Text(
          profile!.headline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
        ),
        SajuSpacing.gap24,

        // 매력 키워드
        _buildCharmKeywords(context),
        SajuSpacing.gap24,

        // 삼정(三停) 요약
        _buildSamjeongSummary(context, colors),
        SajuSpacing.gap24,

        // 오관(五官) 하이라이트
        _buildOgwanHighlight(context, colors),
        SajuSpacing.gap24,

        // 성격 요약
        _buildSectionCard(context, '성격', profile!.personalitySummary, colors),
        SajuSpacing.gap24,

        // 연애 스타일
        _buildSectionCard(context, '연애 스타일', profile!.romanceSummary, colors),
        SajuSpacing.gap24,

        // 연애 핵심 포인트
        _buildRomanceKeyPointsCard(context, colors),
        SajuSpacing.gap24,

        // 성격 특성 5축 바 차트
        _buildTraitsChart(context, colors),

        // 하단 여백
        const SizedBox(height: SajuSpacing.space48),
      ],
    );
  }

  Widget _buildFailureState(BuildContext context, SajuColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: SajuSpacing.space48),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.textTertiary.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Icon(
                  Icons.face_retouching_natural_outlined,
                  size: 32,
                  color: colors.textTertiary,
                ),
              ),
            ),
            SajuSpacing.gap16,
            Text(
              '관상 분석이 준비되지 않았어요',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SajuSpacing.gap8,
            Text(
              '얼굴이 잘 보이는 정면 사진으로\n다시 시도해 보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalHero(BuildContext context, SajuColors colors) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 80, minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: RadialGradient(
              colors: [
                AppTheme.mysticGlow.withValues(alpha: 0.1),
                AppTheme.mysticGlow.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Text(
            '${profile!.animalTypeKorean}상',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        SajuSpacing.gap12,
        Text(
          profile!.animalLabel,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildCharmKeywords(BuildContext context) {
    final colors = context.sajuColors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: profile!.charmKeywords.map((keyword) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.mysticGlow.withValues(alpha: 0.3),
            ),
            color: AppTheme.mysticGlow.withValues(alpha: 0.06),
          ),
          child: Text(
            keyword,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    String body,
    SajuColors colors,
  ) {
    return SajuCard(
      variant: SajuVariant.elevated,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SajuSpacing.gap12,
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRomanceKeyPointsCard(BuildContext context, SajuColors colors) {
    return SajuCard(
      variant: SajuVariant.elevated,
      borderColor: AppTheme.mysticGlow.withValues(alpha: 0.2),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outlined, size: 18, color: AppTheme.mysticAccent),
              SajuSpacing.hGap8,
              Text(
                '연애 핵심 포인트',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.mysticAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SajuSpacing.gap12,
          ...profile!.romanceKeyPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppTheme.mysticAccent, fontSize: 14)),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.7,
                        ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSamjeongSummary(BuildContext context, SajuColors colors) {
    final zones = [
      ('초년운', profile!.samjeong.upper),
      ('중년운', profile!.samjeong.middle),
      ('말년운', profile!.samjeong.lower),
    ];

    return SajuCard(
      variant: SajuVariant.flat,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '삼정(三停) 운세',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SajuSpacing.gap12,
          ...zones.map((zone) {
            final (label, reading) = zone;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SajuBadge(
                    label: label,
                    color: SajuColor.primary,
                    size: SajuSize.xs,
                  ),
                  SajuSpacing.hGap8,
                  Expanded(
                    child: Text(
                      reading,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOgwanHighlight(BuildContext context, SajuColors colors) {
    final features = [
      ('눈', profile!.ogwan.eyes),
      ('코', profile!.ogwan.nose),
      ('입', profile!.ogwan.mouth),
    ];

    return SajuCard(
      variant: SajuVariant.flat,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오관(五官) 해석',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SajuSpacing.gap12,
          ...features.map((f) {
            final (label, reading) = f;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mysticAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTraitsChart(BuildContext context, SajuColors colors) {
    final axes = [
      ('리더십', profile!.traits.leadership),
      ('온화함', profile!.traits.warmth),
      ('독립성', profile!.traits.independence),
      ('감성', profile!.traits.sensitivity),
      ('에너지', profile!.traits.energy),
    ];

    return SajuCard(
      variant: SajuVariant.flat,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성격 특성',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SajuSpacing.gap12,
          ...axes.map((a) {
            final (label, value) = a;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: value / 100,
                        minHeight: 5,
                        backgroundColor:
                            colors.textTertiary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.mysticAccent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  SajuSpacing.hGap8,
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
