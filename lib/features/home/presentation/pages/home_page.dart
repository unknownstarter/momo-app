import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/domain/entities/match_profile.dart';
import '../../../matching/presentation/providers/matching_provider.dart';

/// HomePage — 홈 탭 (2026-02-28 리디자인)
///
/// 섹션 순서:
/// 1. 인사 + 캐릭터
/// 2. 오늘의 연애운 (신설)
/// 3. 궁합 매칭 추천 2열 그리드 (★ 메인)
/// 4. 받은 좋아요 + 카운트 뱃지
/// 5. 관상 매칭 (관상 케미)
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    final receivedLikes = ref.watch(receivedLikesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ---- 1. 인사 + 캐릭터 ----
              _FadeSlideSection(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
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
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ---- 2. 오늘의 연애운 (신설) ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _DailyLoveFortuneCard(),
                ),
              ),

              const SizedBox(height: 32),

              // ---- 3. 궁합 매칭 추천 2열 그리드 (★ 메인) ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '궁합 매칭 추천 이성',
                            style: textTheme.titleLarge,
                          ),
                          GestureDetector(
                            onTap: () => context.go(RoutePaths.matching),
                            child: Text(
                              '더보기',
                              style: textTheme.bodySmall?.copyWith(
                                color: textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    recommendations.when(
                      loading: () => _buildGridSkeleton(context),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptyState(
                          message: '추천을 불러오지 못했어요',
                          height: 200,
                        ),
                      ),
                      data: (profiles) => _RecommendationGrid(
                        profiles: profiles,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ---- 4. 받은 좋아요 ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('받은 좋아요', style: textTheme.titleLarge),
                          const SizedBox(width: 8),
                          receivedLikes.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (likes) => likes.isNotEmpty
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.fireColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${likes.length}',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      receivedLikes.when(
                        loading: () => Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.sajuColors.bgSecondary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (likes) =>
                            _ReceivedLikesCard(count: likes.length),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ---- 5. 관상 매칭 (관상 케미) ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _GwansangMatchSection(),
                ),
              ),

              // 플로팅 네비바 뒤 여백
              SizedBox(height: MediaQuery.of(context).padding.bottom + 88),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildGridSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => const SkeletonCard(),
      ),
    );
  }
}

// =============================================================================
// 추천 매칭 2열 그리드 (★ 메인 콘텐츠)
// =============================================================================

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({
    required this.profiles,
  });

  final List<MatchProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _EmptyState(
          message: '아직 추천이 준비되지 않았어요',
          height: 200,
        ),
      );
    }

    final displayProfiles = profiles.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: displayProfiles.length,
        itemBuilder: (context, index) {
          final profile = displayProfiles[index];
          return SajuMatchCard(
            name: profile.name,
            age: profile.age,
            bio: profile.bio,
            photoUrl: profile.photoUrl,
            characterName: profile.characterName,
            characterAssetPath: profile.characterAssetPath,
            elementType: profile.elementType,
            compatibilityScore: profile.compatibilityScore,
            showCharacterInstead: true,
            heroTag: 'home_char_${profile.userId}_$index',
            onTap: () => context.push(
              RoutePaths.profileDetail,
              extra: {
                'profile': profile,
                'heroTag': 'home_char_${profile.userId}_$index',
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 오늘의 연애운 카드 (기존 _FortuneCard 대체)
// =============================================================================

class _DailyLoveFortuneCard extends StatelessWidget {
  const _DailyLoveFortuneCard();

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
        Text('오늘의 연애운', style: textTheme.titleLarge),
        const SizedBox(height: 14),
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

// =============================================================================
// 받은 좋아요 카드 — 미니멀
// =============================================================================

class _ReceivedLikesCard extends StatelessWidget {
  const _ReceivedLikesCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.sajuColors.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: context.sajuColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          // 블러 아바타들
          SizedBox(
            width: 64,
            height: 32,
            child: Stack(
              children: List.generate(
                count.clamp(0, 3),
                (i) => Positioned(
                  left: i * 18.0,
                  child: ClipOval(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.firePastel.withValues(alpha: 0.6),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              count > 0 ? '$count명이 좋아해요' : '아직 없어요',
              style: textTheme.titleSmall,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: textTheme.bodySmall?.color?.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 관상 매칭 섹션 (관상 케미)
// =============================================================================

class _GwansangMatchSection extends StatelessWidget {
  const _GwansangMatchSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.sajuColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('관상 매칭', style: textTheme.titleLarge),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => context.go(RoutePaths.matching),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.firePastel.withValues(alpha: 0.25),
                  AppTheme.waterPastel.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.firePastel.withValues(alpha: 0.4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 24,
                          color: AppTheme.fireColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '관상으로 보는 우리의 케미는?',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '리더십 · 따뜻함 · 독립성 · 섬세함 · 에너지',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '나와 케미 좋은 관상 TOP 3',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TraitChip(icon: Icons.shield_outlined, label: '리더십', value: '높음'),
                    const SizedBox(width: 16),
                    _TraitChip(icon: Icons.favorite_outline, label: '따뜻함', value: '높음'),
                    const SizedBox(width: 16),
                    _TraitChip(icon: Icons.bolt_outlined, label: '에너지', value: '중간'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '관상 매칭 보러가기',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: context.sajuColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: textTheme.labelSmall),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: context.sajuColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 섹션 등장 애니메이션 (fadeIn + slideUp)
// =============================================================================

class _FadeSlideSection extends StatefulWidget {
  const _FadeSlideSection({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideSection> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlideSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// 빈 상태
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.height = 120});

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
        ),
      ),
    );
  }
}
