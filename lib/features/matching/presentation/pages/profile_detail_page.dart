import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../saju/presentation/providers/saju_provider.dart';
import '../../domain/entities/match_profile.dart';
import '../providers/matching_provider.dart';

/// ProfileDetailPage — 5섹션 스크롤 스토리텔링 (다크 모드)
///
/// ## 핵심 UX — "스크롤 = 이 사람을 알아가는 서사"
/// 1. Hero: 패럴랙스 블러 사진 + 캐릭터 스케일 등장 + 궁합 뱃지
/// 2. 첫인상: 캐릭터 말풍선 소개 + 기본 정보 칩
/// 3. 궁합: 인라인 게이지 카운트업 + 강점/도전 스태거드
/// 4. 관상 케미: 동물상 + traits 미니 바 (조건부)
/// 5. 액션: 고정 하단 좋아요 + 건너뛰기
class ProfileDetailPage extends ConsumerStatefulWidget {
  const ProfileDetailPage({
    super.key,
    required this.profile,
    this.heroTag,
  });

  final MatchProfile profile;
  final String? heroTag;

  @override
  ConsumerState<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends ConsumerState<ProfileDetailPage> {
  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    // 궁합 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(compatibilityPreviewProvider.notifier)
          .loadPreview(widget.profile.userId);
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final elementColor = AppTheme.fiveElementColor(profile.elementType);
    final elementPastel = AppTheme.fiveElementPastel(profile.elementType);

    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;
          final screenHeight = MediaQuery.sizeOf(context).height;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            body: Stack(
              children: [
                // ---- 메인 스크롤 콘텐츠 ----
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ---- SECTION 1: HERO ----
                    SliverAppBar(
                      expandedHeight: screenHeight * 0.45,
                      backgroundColor: colors.bgPrimary,
                      surfaceTintColor: Colors.transparent,
                      pinned: true,
                      stretch: true,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colors.textPrimary,
                        ),
                      ),
                      title: _scrollOffset > screenHeight * 0.25
                          ? Text(
                              '${profile.name}, ${profile.age}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            )
                          : null,
                      actions: [
                        IconButton(
                          onPressed: () {
                            // TODO(PROD): 신고/차단 기능
                          },
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _HeroSection(
                          profile: profile,
                          elementColor: elementColor,
                          elementPastel: elementPastel,
                          scrollOffset: _scrollOffset,
                          heroTag: widget.heroTag,
                        ),
                      ),
                    ),

                    // ---- SECTION 2: 첫인상 ----
                    SliverToBoxAdapter(
                      child: _FirstImpressionSection(profile: profile),
                    ),

                    // ---- SECTION 3: 우리의 궁합 (인라인) ----
                    SliverToBoxAdapter(
                      child: _CompatibilitySection(profile: profile),
                    ),

                    // ---- SECTION 4: 관상 케미 (조건부) ----
                    if (profile.animalType != null)
                      SliverToBoxAdapter(
                        child: _GwansangChemiSection(profile: profile),
                      ),

                    // 하단 액션 영역 여백
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 140),
                    ),
                  ],
                ),

                // ---- SECTION 5: 고정 하단 액션 ----
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomActionBar(profile: profile),
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
// SECTION 1: Hero — 패럴랙스 블러 사진 + 캐릭터 스케일 등장
// =============================================================================

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.profile,
    required this.elementColor,
    required this.elementPastel,
    required this.scrollOffset,
    this.heroTag,
  });

  final MatchProfile profile;
  final Color elementColor;
  final Color elementPastel;
  final double scrollOffset;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;
    final scoreColor =
        AppTheme.compatibilityColor(profile.compatibilityScore);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 패럴랙스 블러 사진 배경
        Transform.translate(
          offset: Offset(0, scrollOffset * 0.3),
          child: profile.photoUrl != null
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Image.network(
                    profile.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _gradientPlaceholder(elementPastel),
                  ),
                )
              : _gradientPlaceholder(elementPastel),
        ),

        // 다크 오버레이
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                colors.bgPrimary.withValues(alpha: 0.85),
                colors.bgPrimary,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),

        // 중앙 콘텐츠
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 캐릭터 아바타
              _wrapHero(
                  tag: heroTag,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: elementPastel.withValues(alpha: 0.3),
                      border: Border.all(
                        color: elementColor.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profile.characterAssetPath != null
                          ? Image.asset(
                              profile.characterAssetPath!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color:
                                      elementColor.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: elementColor.withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                  ),
              ),

              const SizedBox(height: 6),

              // 캐릭터 이름
              Text(
                profile.characterName,
                style: textTheme.labelMedium?.copyWith(
                  color: elementColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // 이름, 나이 + 오행 뱃지
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${profile.name}, ${profile.age}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SajuBadge(
                    label: _elementLabel(profile.elementType),
                    color: _toSajuColor(profile.elementType),
                    size: SajuSize.sm,
                  ),
                ],
              ),

            ],
          ),
        ),

        // 궁합 점수 뱃지 (우상단)
        Positioned(
          top: MediaQuery.of(context).padding.top + 48,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${profile.compatibilityScore}%',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _gradeLabel(profile.compatibilityScore),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 잠금 안내
        Positioned(
          top: MediaQuery.of(context).padding.top + 48,
          left: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '좋아요하면 사진 공개',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _wrapHero({String? tag, required Widget child}) {
    if (tag == null) return child;
    return Hero(tag: tag, child: child);
  }

  static Widget _gradientPlaceholder(Color pastel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pastel.withValues(alpha: 0.4),
            pastel.withValues(alpha: 0.7),
          ],
        ),
      ),
    );
  }

  static String _elementLabel(String type) {
    return switch (type) {
      'wood' => '목(木)',
      'fire' => '화(火)',
      'earth' => '토(土)',
      'metal' => '금(金)',
      'water' => '수(水)',
      _ => type,
    };
  }

  static SajuColor _toSajuColor(String type) {
    return switch (type) {
      'wood' => SajuColor.wood,
      'fire' => SajuColor.fire,
      'earth' => SajuColor.earth,
      'metal' => SajuColor.metal,
      'water' => SajuColor.water,
      _ => SajuColor.primary,
    };
  }

  static String _gradeLabel(int score) {
    if (score >= 90) return '천생연분';
    if (score >= 75) return '최고';
    if (score >= 60) return '좋음';
    if (score >= 40) return '보통';
    return '도전';
  }
}

// =============================================================================
// SECTION 2: 첫인상 — 캐릭터 가이드 + 기본 정보
// =============================================================================

class _FirstImpressionSection extends StatefulWidget {
  const _FirstImpressionSection({required this.profile});

  final MatchProfile profile;

  @override
  State<_FirstImpressionSection> createState() =>
      _FirstImpressionSectionState();
}

class _FirstImpressionSectionState extends State<_FirstImpressionSection> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // 캐릭터 말풍선
          SajuCharacterBubble(
            characterName: profile.characterName,
            message: '이 사람은요... ${profile.bio.length > 20 ? '특별한 매력이 있어요!' : '한번 알아봐요!'}',
            elementColor: _toSajuColor(profile.elementType),
            characterAssetPath: profile.characterAssetPath,
            size: SajuSize.sm,
          ),

          const SizedBox(height: 24),

          // 자기소개
          AnimatedCrossFade(
            firstChild: Text(
              profile.bio,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              profile.bio,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            crossFadeState: _bioExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (profile.bio.length > 80)
            GestureDetector(
              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _bioExpanded ? '접기' : '더 보기',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // 기본 정보 칩
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.straighten_rounded,
                label: '키 정보 비공개',
                colors: colors,
              ),
              _InfoChip(
                icon: Icons.work_outline_rounded,
                label: '직업 정보 비공개',
                colors: colors,
              ),
              _InfoChip(
                icon: Icons.location_on_outlined,
                label: '지역 정보 비공개',
                colors: colors,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 구분선
          Container(
            height: 1,
            color: colors.borderDefault,
          ),
        ],
      ),
    );
  }

  static SajuColor _toSajuColor(String type) {
    return switch (type) {
      'wood' => SajuColor.wood,
      'fire' => SajuColor.fire,
      'earth' => SajuColor.earth,
      'metal' => SajuColor.metal,
      'water' => SajuColor.water,
      _ => SajuColor.primary,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final sajuColors = context.sajuColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sajuColors.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: sajuColors.borderDefault,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: sajuColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: sajuColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 3: 궁합 — 인라인 와우 모먼트
// =============================================================================

class _CompatibilitySection extends ConsumerWidget {
  const _CompatibilitySection({
    required this.profile,
  });

  final MatchProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;
    final compatibilityAsync = ref.watch(compatibilityPreviewProvider);
    final isDestined = profile.compatibilityScore >= 90;
    final scoreColor =
        AppTheme.compatibilityColor(profile.compatibilityScore);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // 섹션 제목
          Text(
            '우리의 궁합',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '사주로 본 두 사람의 인연',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),

          const SizedBox(height: 28),

          // 캐릭터 쌍
          _buildCharacterPair(context, ref),

          const SizedBox(height: 28),

          // 궁합 게이지
          if (isDestined)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mysticGlow.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppTheme.mysticGlow.withValues(alpha: 0.1),
                    blurRadius: 64,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: CompatibilityGauge(
                score: profile.compatibilityScore,
                size: 140,
                strokeWidth: 8,
              ),
            )
          else
            CompatibilityGauge(
              score: profile.compatibilityScore,
              size: 140,
              strokeWidth: 8,
            ),

          const SizedBox(height: 20),

          // 등급 설명
          Text(
            _scoreComment(profile.compatibilityScore),
            style: textTheme.titleMedium?.copyWith(
              color: isDestined
                  ? AppTheme.mysticGlow
                  : scoreColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // 강점/도전 — 프로바이더 데이터 or 폴백
          compatibilityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: MomoLoading(),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (compat) {
              if (compat == null) {
                return _buildFallbackStrengthsChallenges(
                    context, textTheme, scoreColor);
              }
              return _StrengthsChallengesList(
                strengths: compat.strengths,
                challenges: compat.challenges,
                scoreColor: scoreColor,
              );
            },
          ),

          const SizedBox(height: 16),

          // 구분선
          Container(
            height: 1,
            color: colors.borderDefault,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterPair(BuildContext context, WidgetRef ref) {
    final partnerColor =
        AppTheme.fiveElementColor(profile.elementType);
    final partnerPastel =
        AppTheme.fiveElementPastel(profile.elementType);

    final myAnalysis = ref.watch(sajuAnalysisNotifierProvider).valueOrNull;
    final myElement = myAnalysis?.profile.dominantElement?.name ?? 'wood';
    final myColor = AppTheme.fiveElementColor(myElement);
    final myPastel = AppTheme.fiveElementPastel(myElement);
    final myAssetPath = myAnalysis?.characterAssetPath ??
        CharacterAssets.defaultForString(myElement);
    final myCharacterName =
        myAnalysis?.characterName ?? CharacterAssets.nameForString(myElement);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CharacterAvatar(
          label: '나',
          color: myColor,
          pastelColor: myPastel,
          assetPath: myAssetPath,
          characterName: myCharacterName,
        ),
        const SizedBox(width: 24),
        Icon(
          Icons.favorite_rounded,
          size: 20,
          color: AppTheme.mysticGlow.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 24),
        _CharacterAvatar(
          label: profile.name,
          color: partnerColor,
          pastelColor: partnerPastel,
          assetPath: profile.characterAssetPath,
          characterName: profile.characterName,
        ),
      ],
    );
  }

  Widget _buildFallbackStrengthsChallenges(
    BuildContext context,
    TextTheme textTheme,
    Color scoreColor,
  ) {
    // 점수 기반 기본 강점/도전
    final strengths = _defaultStrengths(profile.compatibilityScore);
    final challenges = _defaultChallenges(profile.compatibilityScore);

    return _StrengthsChallengesList(
      strengths: strengths,
      challenges: challenges,
      scoreColor: scoreColor,
    );
  }

  static List<String> _defaultStrengths(int score) {
    if (score >= 90) {
      return [
        '서로의 오행이 자연스럽게 상생해요',
        '깊은 정서적 교감이 가능한 사이예요',
        '함께 있으면 서로 성장할 수 있어요',
      ];
    }
    if (score >= 75) {
      return [
        '서로를 이해하는 직관이 있어요',
        '대화가 편안하게 흘러가는 조합이에요',
        '서로의 부족한 부분을 채워줘요',
      ];
    }
    return [
      '서로 다른 매력을 발견할 수 있어요',
      '새로운 관점을 배울 수 있는 관계예요',
      '노력하면 더 깊은 이해가 생겨요',
    ];
  }

  static List<String> _defaultChallenges(int score) {
    if (score >= 75) {
      return [
        '서로의 속도가 다를 때 인내가 필요해요',
        '가끔 의견 차이가 있지만 그것도 매력이에요',
      ];
    }
    return [
      '서로의 다른 점을 존중하는 연습이 필요해요',
      '소통 방식의 차이를 이해하면 좋겠어요',
      '서로의 공간을 존중해주세요',
    ];
  }

  static String _scoreComment(int score) {
    return switch (score) {
      >= 90 => '천생연분! 하늘이 맺어준 인연이에요',
      >= 75 => '별이 겹치는 특별한 사이예요',
      >= 60 => '함께 성장할 수 있는 관계예요',
      >= 40 => '알아갈수록 깊어지는 인연이에요',
      _ => '정반대이기에 끌리는 특별한 관계예요',
    };
  }
}

// =============================================================================
// 강점/도전 스태거드 등장
// =============================================================================

class _StrengthsChallengesList extends StatelessWidget {
  const _StrengthsChallengesList({
    required this.strengths,
    required this.challenges,
    required this.scoreColor,
  });

  final List<String> strengths;
  final List<String> challenges;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strengths.isNotEmpty) ...[
          _SectionTitle(title: '이런 점이 잘 맞아요'),
          const SizedBox(height: 12),
          ...strengths.take(3).map((text) => _BulletItem(
                text: text,
                accentColor: scoreColor,
              )),
          const SizedBox(height: 20),
        ],
        if (challenges.isNotEmpty) ...[
          _SectionTitle(title: '함께 노력하면 좋은 점'),
          const SizedBox(height: 12),
          ...challenges.take(3).map((text) => _BulletItem(
                text: text,
                accentColor: Colors.white.withValues(alpha: 0.3),
              )),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({
    required this.text,
    required this.accentColor,
  });

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 4: 관상 케미 (조건부)
// =============================================================================

class _GwansangChemiSection extends StatelessWidget {
  const _GwansangChemiSection({
    required this.profile,
  });

  final MatchProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;

    final animalDisplayText =
        (profile.animalModifier != null && profile.animalTypeKorean != null)
            ? '${profile.animalModifier} ${profile.animalTypeKorean}상'
            : '${profile.animalType}상';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // 섹션 제목
          Text(
            '관상 케미',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.mysticGlow.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                // 동물상 표시
                Text(
                  '${profile.name}님은 $animalDisplayText',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Traits 미니 바 차트
                if (profile.gwansangTraits != null)
                  _TraitsBars(
                    traits: profile.gwansangTraits!,
                    isRevealed: true,
                  )
                else
                  // 기본 traits
                  _TraitsBars(
                    traits: const {
                      '리더십': 70,
                      '따뜻함': 85,
                      '독립성': 60,
                      '섬세함': 75,
                      '에너지': 65,
                    },
                    isRevealed: true,
                  ),

                const SizedBox(height: 16),

                // 내 관상 확인 넛지 CTA
                Text(
                  '내 관상을 알면 동물상 케미도 확인할 수 있어요',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                SajuButton(
                  label: '내 관상 알아보기',
                  onPressed: () => context.go(RoutePaths.gwansangBridge),
                  variant: SajuVariant.outlined,
                  color: SajuColor.primary,
                  size: SajuSize.sm,
                  leadingIcon: Icons.face_retouching_natural,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            color: colors.borderDefault,
          ),
        ],
      ),
    );
  }
}

class _TraitsBars extends StatelessWidget {
  const _TraitsBars({
    required this.traits,
    required this.isRevealed,
  });

  final Map<String, int> traits;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final entries = traits.entries.toList();

    return Column(
      children: entries.asMap().entries.map((entry) {
        final i = entry.key;
        final trait = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: i < entries.length - 1 ? 8 : 0),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  trait.key,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: isRevealed ? trait.value / 100 : 0,
                    ),
                    duration: Duration(milliseconds: 800 + (i * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: colors.bgSecondary,
                      valueColor: AlwaysStoppedAnimation(
                        AppTheme.mysticGlow.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '${trait.value}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SECTION 5: 고정 하단 액션 바
// =============================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.profile});

  final MatchProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // 스와이프 업 = 좋아요
        if (details.velocity.pixelsPerSecond.dy < -500) {
          HapticService.medium();
          _handleLike(context);
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.bgPrimary.withValues(alpha: 0.0),
              colors.bgPrimary.withValues(alpha: 0.9),
              colors.bgPrimary,
            ],
            stops: const [0.0, 0.3, 0.5],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 좋아요 버튼
            SizedBox(
              width: double.infinity,
              child: LikeButton(
                onPressed: () async {
                  _handleLike(context);
                  return true;
                },
                label: '좋아요 보내기',
              ),
            ),

            const SizedBox(height: 8),

            // 건너뛰기
            SajuButton(
              label: '건너뛰기',
              onPressed: () => Navigator.of(context).pop(),
              variant: SajuVariant.ghost,
              color: SajuColor.primary,
              size: SajuSize.md,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.name}님에게 좋아요를 보냈어요'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


// =============================================================================
// 공용 위젯: DelayedFadeIn — 딜레이 후 페이드인
// =============================================================================

// =============================================================================
// 캐릭터 아바타 (궁합 섹션용)
// =============================================================================

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({
    required this.label,
    required this.color,
    required this.pastelColor,
    this.assetPath,
    required this.characterName,
  });

  final String label;
  final Color color;
  final Color pastelColor;
  final String? assetPath;
  final String characterName;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pastelColor.withValues(alpha: 0.2),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: assetPath != null
                ? Image.asset(
                    assetPath!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        characterName.characters.first,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
