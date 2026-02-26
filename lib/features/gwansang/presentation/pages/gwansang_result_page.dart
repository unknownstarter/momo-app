/// 관상 결과 페이지 — 동물상 리빌 + 분석 결과 화면
///
/// **이 앱의 와우 모먼트!** 바이럴의 핵심 포인트.
/// 동물상 이모지 대형 리빌 → 매력 키워드 → 성격/연애/시너지 카드
/// → 찰떡/밀당 궁합 동물 → 공유 CTA.
/// 다크 테마(미스틱 모드), 스태거드 페이드인 애니메이션.
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
import '../../domain/entities/animal_type.dart';
import '../../domain/entities/face_measurements.dart';
import '../../domain/entities/gwansang_entity.dart';
import '../providers/gwansang_provider.dart';

/// 관상 결과 페이지 — 동물상 리빌
class GwansangResultPage extends ConsumerStatefulWidget {
  const GwansangResultPage({super.key, this.result});

  /// 관상 분석 결과 (GoRouter extra)
  final dynamic result;

  @override
  ConsumerState<GwansangResultPage> createState() =>
      _GwansangResultPageState();
}

class _GwansangResultPageState extends ConsumerState<GwansangResultPage> {
  GwansangAnalysisResult? get _analysisResult {
    if (widget.result is GwansangAnalysisResult) {
      return widget.result as GwansangAnalysisResult;
    }
    return null;
  }

  /// mock 데이터 (result가 null일 때 사용)
  GwansangProfile get _profile =>
      _analysisResult?.profile ?? _mockProfile;

  static final _mockProfile = GwansangProfile(
    id: 'mock-id',
    userId: 'mock-user',
    animalType: AnimalType.cat,
    measurements: FaceMeasurements.fromJson(const {}),
    photoUrls: const [],
    headline: '타고난 리더형 관상, 눈빛에 결단력이 서려 있어요',
    personalitySummary:
        '겉으로는 도도하지만 마음 한 켠에는 따뜻함을 품고 있는 타입이에요. '
        '첫인상은 다가가기 어렵지만, 한번 친해지면 끝없이 매력을 발산하는 스타일이죠. '
        '독립적이고 자기 주관이 뚜렷해서, 주변 사람들에게 신뢰감을 줘요.',
    romanceSummary:
        '연애에서는 밀당의 달인이에요. 쉽게 마음을 열지 않지만, '
        '한번 마음을 주면 깊고 진실한 사랑을 해요. '
        '상대방의 지적인 면에 끌리고, 서로 독립적이면서도 깊은 유대감을 나누는 관계를 선호해요.',
    sajuSynergy:
        '사주의 木 기운과 고양이상의 독립적 매력이 만나 '
        '자기만의 세계를 가진 신비로운 존재감을 만들어요. '
        '성장과 변화를 두려워하지 않는 당신의 관상은 사주의 기운과 완벽히 조화를 이루고 있어요.',
    charmKeywords: const ['밀당의 달인', '신비로운 눈빛', '도도한 매력'],
    elementModifier: '木 기운의 신비로운 매력가',
    createdAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;
          final profile = _profile;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            body: CustomScrollView(
              slivers: [
                // 앱바
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
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // 본문
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SajuSpacing.space24,
                    ),
                    child: _ResultRevealContent(
                      profile: profile,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 스태거드 리빌 컨테이너
// =============================================================================

class _ResultRevealContent extends StatefulWidget {
  const _ResultRevealContent({required this.profile});

  final GwansangProfile profile;

  @override
  State<_ResultRevealContent> createState() => _ResultRevealContentState();
}

class _ResultRevealContentState extends State<_ResultRevealContent>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1400);
  static const _stagger = 0.12;
  static const _sectionCount = 8;

  late final AnimationController _controller;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * _stagger).clamp(0.0, 0.85);
      final end = (start + 0.30).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _slides = List.generate(_sectionCount, (i) {
      final start = (i * _stagger).clamp(0.0, 0.85);
      final end = (start + 0.30).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final colors = context.sajuColors;

    final sections = <Widget>[
      // 1. 동물상 히어로 리빌
      _buildAnimalHero(context, profile, colors),
      // 2. 헤드라인
      _buildHeadline(context, profile, colors),
      // 3. 매력 키워드 칩
      _buildCharmKeywords(context, profile),
      // 4. 성격 요약 카드
      _buildSectionCard(context, '성격', profile.personalitySummary, colors),
      // 5. 연애 스타일 카드
      _buildSectionCard(context, '연애 스타일', profile.romanceSummary, colors),
      // 6. 사주 x 관상 시너지
      _buildSynergyCard(context, profile, colors),
      // 7. 궁합 동물상
      _buildCompatibleAnimals(context, profile, colors),
      // 8. 액션 버튼
      _buildActions(context, profile.photoUrls),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          FadeTransition(
            opacity: _fades[i],
            child: SlideTransition(
              position: _slides[i],
              child: sections[i],
            ),
          ),
          SizedBox(height: i == 0 ? SajuSpacing.space16 : SajuSpacing.space24),
        ],
        const SizedBox(height: SajuSpacing.space48),
      ],
    );
  }

  // ===========================================================================
  // 1. 동물상 히어로 리빌
  // ===========================================================================

  Widget _buildAnimalHero(
    BuildContext context,
    GwansangProfile profile,
    SajuColors colors,
  ) {
    return Column(
      children: [
        // 이모지 + 글로우
        Stack(
          alignment: Alignment.center,
          children: [
            // 글로우 배경
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mysticGlow.withValues(alpha: 0.15),
                    AppTheme.mysticGlow.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
            // 이모지
            Text(
              profile.animalType.emoji,
              style: const TextStyle(fontSize: 64),
            ),
          ],
        ),

        SajuSpacing.gap16,

        // 동물상 레이블
        Text(
          profile.animalType.label,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),

        SajuSpacing.gap8,

        // 오행 보정자
        if (profile.elementModifier != null)
          Text(
            profile.elementModifier!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mysticGlow,
                  fontWeight: FontWeight.w500,
                ),
          ),
      ],
    );
  }

  // ===========================================================================
  // 2. 헤드라인
  // ===========================================================================

  Widget _buildHeadline(
    BuildContext context,
    GwansangProfile profile,
    SajuColors colors,
  ) {
    return Text(
      profile.headline,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.textSecondary,
            height: 1.6,
          ),
    );
  }

  // ===========================================================================
  // 3. 매력 키워드
  // ===========================================================================

  Widget _buildCharmKeywords(
    BuildContext context,
    GwansangProfile profile,
  ) {
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

  // ===========================================================================
  // 4-5. 섹션 카드 (성격 / 연애 스타일)
  // ===========================================================================

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

  // ===========================================================================
  // 6. 사주 x 관상 시너지
  // ===========================================================================

  Widget _buildSynergyCard(
    BuildContext context,
    GwansangProfile profile,
    SajuColors colors,
  ) {
    return SajuCard(
      variant: SajuVariant.elevated,
      borderColor: AppTheme.mysticGlow.withValues(alpha: 0.3),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppTheme.mysticGlow,
              ),
              SajuSpacing.hGap8,
              Text(
                '사주 \u00D7 관상 시너지',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.mysticGlow,
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

  // ===========================================================================
  // 7. 궁합 동물상
  // ===========================================================================

  Widget _buildCompatibleAnimals(
    BuildContext context,
    GwansangProfile profile,
    SajuColors colors,
  ) {
    // 찰떡궁합 + 밀당궁합 찾기
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
          // 찰떡궁합
          _buildCompatRow(
            context,
            label: '찰떡궁합',
            animal: bestMatch,
            colors: colors,
            accentColor: AppTheme.statusSuccess,
          ),
          SajuSpacing.gap12,
          // 밀당궁합
          _buildCompatRow(
            context,
            label: '밀당궁합',
            animal: pushPull,
            colors: colors,
            accentColor: AppTheme.mysticGlow,
          ),
        ],
      ),
    );
  }

  Widget _buildCompatRow(
    BuildContext context, {
    required String label,
    required AnimalType animal,
    required SajuColors colors,
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

  // ===========================================================================
  // 8. 액션 버튼
  // ===========================================================================

  Widget _buildActions(BuildContext context, List<String> photoUrls) {
    return Column(
      children: [
        // 메인 CTA — 관상 사진 URL을 매칭 프로필로 전달
        SajuButton(
          label: '운명의 인연 찾으러 가기',
          onPressed: () => context.go(
            RoutePaths.matchingProfile,
            extra: photoUrls.isNotEmpty
                ? {'gwansangPhotoUrls': photoUrls}
                : null,
          ),
          variant: SajuVariant.filled,
          color: SajuColor.primary,
          size: SajuSize.lg,
          leadingIcon: Icons.favorite_outlined,
        ),

        SajuSpacing.gap12,

        // 공유
        SajuButton(
          label: '내 관상 공유하기',
          onPressed: () {
            // TODO: 공유 기능 구현
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('공유 기능은 준비 중이에요!')),
            );
          },
          variant: SajuVariant.outlined,
          color: SajuColor.primary,
          size: SajuSize.lg,
          leadingIcon: Icons.share_outlined,
        ),

        SajuSpacing.gap8,

        // 나중에
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
