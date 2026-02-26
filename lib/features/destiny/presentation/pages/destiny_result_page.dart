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
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../gwansang/domain/entities/animal_type.dart';
import '../../../gwansang/domain/entities/face_measurements.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/domain/entities/saju_entity.dart';
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

  GwansangProfile get _gwansangProfile =>
      _gwansangResult?.profile ?? _mockGwansangProfile;

  static final _mockGwansangProfile = GwansangProfile(
    id: 'mock-id',
    userId: 'mock-user',
    animalType: AnimalType.cat,
    measurements: FaceMeasurements.fromJson(const {}),
    photoUrls: const [],
    headline: '타고난 리더형 관상, 눈빛에 결단력이 서려 있어요',
    personalitySummary:
        '겉으로는 도도하지만 마음 한 켠에는 따뜻함을 품고 있는 타입이에요. '
        '첫인상은 다가가기 어렵지만, 한번 친해지면 끝없이 매력을 발산하는 스타일이죠.',
    romanceSummary:
        '연애에서는 밀당의 달인이에요. 쉽게 마음을 열지 않지만, '
        '한번 마음을 주면 깊고 진실한 사랑을 해요.',
    sajuSynergy:
        '사주의 기운과 관상의 매력이 만나 '
        '자기만의 세계를 가진 신비로운 존재감을 만들어요.',
    charmKeywords: const ['밀당의 달인', '신비로운 눈빛', '도도한 매력'],
    elementModifier: '신비로운 매력가',
    createdAt: DateTime.now(),
  );

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
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // 닫기 버튼
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  leading: const SizedBox.shrink(),
                  actions: [
                    IconButton(
                      onPressed: () => context.go(RoutePaths.home),
                      icon: Icon(
                        Icons.close,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
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
    SajuColorScheme colors,
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

                // 동물상 이모지
                if (_gwansangResult != null)
                  Positioned(
                    right: 10,
                    bottom: 0,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
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
                          gwansang.animalType.emoji,
                          style: const TextStyle(fontSize: 28),
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
              if (_gwansangResult != null) ...[
                SajuSpacing.hGap8,
                SajuBadge(
                  label: gwansang.animalType.label,
                  color: SajuColor.primary,
                  size: SajuSize.sm,
                ),
              ],
            ],
          ),

          SajuSpacing.gap8,

          // 타이틀
          Text(
            '${_sajuResult!.profile.summary}',
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
          label: '운명의 인연 찾으러 가기',
          onPressed: () => context.go(
            RoutePaths.matchingProfile,
            extra: {'quickMode': true},
          ),
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

  final GwansangProfile profile;
  final bool hasResult;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;

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
          profile.headline,
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

        // 성격 요약
        _buildSectionCard(context, '성격', profile.personalitySummary, colors),
        SajuSpacing.gap24,

        // 연애 스타일
        _buildSectionCard(context, '연애 스타일', profile.romanceSummary, colors),
        SajuSpacing.gap24,

        // 사주 x 관상 시너지
        _buildSynergyCard(context, colors),
        SajuSpacing.gap24,

        // 궁합 동물상
        _buildCompatibleAnimals(context, colors),

        // 하단 여백
        const SizedBox(height: SajuSpacing.space48),
      ],
    );
  }

  Widget _buildAnimalHero(BuildContext context, SajuColorScheme colors) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mysticGlow.withValues(alpha: 0.1),
                    AppTheme.mysticGlow.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
            Text(
              profile.animalType.emoji,
              style: const TextStyle(fontSize: 52),
            ),
          ],
        ),
        SajuSpacing.gap12,
        Text(
          profile.animalType.label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (profile.elementModifier != null) ...[
          SajuSpacing.gap4,
          Text(
            profile.elementModifier!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mysticAccent,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCharmKeywords(BuildContext context) {
    final elementColor = _elementToSajuColor(profile.animalType.element);

    return Wrap(
      spacing: SajuSpacing.space8,
      runSpacing: SajuSpacing.space8,
      alignment: WrapAlignment.center,
      children: profile.charmKeywords.map((keyword) {
        return SajuChip(
          label: keyword,
          color: elementColor,
          size: SajuSize.sm,
          isSelected: true,
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    String body,
    SajuColorScheme colors,
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

  Widget _buildSynergyCard(BuildContext context, SajuColorScheme colors) {
    return SajuCard(
      variant: SajuVariant.elevated,
      borderColor: AppTheme.mysticGlow.withValues(alpha: 0.2),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: AppTheme.mysticAccent),
              SajuSpacing.hGap8,
              Text(
                '사주 \u00D7 관상 시너지',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.mysticAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SajuSpacing.gap12,
          Text(
            profile.sajuSynergy,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibleAnimals(BuildContext context, SajuColorScheme colors) {
    AnimalType? bestMatch;
    AnimalType? pushPull;

    for (final entry in AnimalCompatibility.matrix.entries) {
      final (a, b) = entry.key;
      if (a == profile.animalType || b == profile.animalType) {
        final other = a == profile.animalType ? b : a;
        if (entry.value == 5 && bestMatch == null) {
          bestMatch = other;
        } else if (entry.value == 4 && pushPull == null) {
          pushPull = other;
        }
      }
    }

    bestMatch ??= AnimalType.dog;
    pushPull ??= AnimalType.wolf;

    return SajuCard(
      variant: SajuVariant.flat,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '궁합 동물상',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SajuSpacing.gap16,
          _buildCompatRow(
            context,
            label: '찰떡궁합',
            animal: bestMatch,
            colors: colors,
            accentColor: AppTheme.statusSuccess,
          ),
          SajuSpacing.gap12,
          _buildCompatRow(
            context,
            label: '밀당궁합',
            animal: pushPull,
            colors: colors,
            accentColor: AppTheme.mysticAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCompatRow(
    BuildContext context, {
    required String label,
    required AnimalType animal,
    required SajuColorScheme colors,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
        SajuSpacing.hGap12,
        Text(
          '${animal.label} ${animal.emoji}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
        ),
      ],
    );
  }

  SajuColor _elementToSajuColor(FiveElementType element) {
    return switch (element) {
      FiveElementType.wood => SajuColor.wood,
      FiveElementType.fire => SajuColor.fire,
      FiveElementType.earth => SajuColor.earth,
      FiveElementType.metal => SajuColor.metal,
      FiveElementType.water => SajuColor.water,
    };
  }
}
