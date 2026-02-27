import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/domain/entities/match_profile.dart';
import '../../../matching/presentation/pages/compatibility_preview_page.dart';
import '../../../matching/presentation/providers/matching_provider.dart';

/// HomePage — 홈 탭 (토스 스타일 미니멀)
///
/// 타이포그래피 위계로 구조를 잡고, 여백으로 호흡을 주는 깔끔한 레이아웃.
/// 아이콘/장식 최소화, 핵심 정보만 노출.
/// 각 섹션은 스태거드 fadeIn + slideUp으로 등장한다.
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
                      // 나무리 캐릭터 — 은은하게
                      Image.asset(
                        CharacterAssets.namuriWoodDefault,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ---- 2. 오늘의 추천 ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '오늘의 추천',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 14),
                    recommendations.when(
                      loading: () => SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 3,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, _) => const SkeletonCard(),
                        ),
                      ),
                      error: (_, _) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptyState(
                          message: '추천을 불러오지 못했어요',
                          height: 200,
                        ),
                      ),
                      data: (profiles) => _RecommendationList(
                        profiles: profiles,
                        ref: ref,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ---- 관상 넛지 배너 ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _GwansangNudgeBanner(),
                ),
              ),

              const SizedBox(height: 32),

              // ---- 3. 받은 좋아요 ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '받은 좋아요',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      receivedLikes.when(
                        loading: () => Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDE8),
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

              // ---- 4. 오늘의 한마디 ----
              _FadeSlideSection(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 한마디',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      const _FortuneCard(),
                    ],
                  ),
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
}

// =============================================================================
// 추천 매칭 가로 스크롤
// =============================================================================

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({
    required this.profiles,
    required this.ref,
  });

  final List<MatchProfile> profiles;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const _EmptyState(
        message: '아직 추천이 준비되지 않았어요',
        height: 200,
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: profiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return SajuMatchCard(
            name: profile.name,
            age: profile.age,
            bio: profile.bio,
            photoUrl: profile.photoUrl,
            characterName: profile.characterName,
            characterAssetPath: profile.characterAssetPath,
            elementType: profile.elementType,
            compatibilityScore: profile.compatibilityScore,
            width: 180,
            height: 260,
            onTap: () => showCompatibilityPreview(context, ref, profile),
          );
        },
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
// 오늘의 한마디 카드
// =============================================================================

class _FortuneCard extends StatelessWidget {
  const _FortuneCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.sajuColors.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: context.sajuColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.waterPastel.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: characterAssetPath != null
                      ? Image.asset(
                          characterAssetPath!,
                          width: 28,
                          height: 28,
                          errorBuilder: (_, _, _) => Text(
                            '물',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.waterColor,
                            ),
                          ),
                        )
                      : Text(
                          '물',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.waterColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '물결이의 한마디',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.waterColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '오늘은 새로운 인연이 다가올 기운이 느껴져요.\n마음을 열고 자연스럽게 대화해보세요.',
            style: textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  String? get characterAssetPath => CharacterAssets.mulgyeoriWaterDefault;
}

// =============================================================================
// 관상 넛지 배너
// =============================================================================

class _GwansangNudgeBanner extends StatelessWidget {
  const _GwansangNudgeBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.go(RoutePaths.gwansangBridge),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.firePastel.withValues(alpha: 0.4),
              AppTheme.waterPastel.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: context.sajuColors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Text('🦊🐻', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '닮은 동물상끼리 잘 맞는대요!',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '내 동물상을 알면 찰떡궁합을 찾아줄게요',
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
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
