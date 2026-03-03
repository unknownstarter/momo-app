import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/domain/entities/match_profile.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션 3: 궁합 매칭 추천 2열 그리드 (★ 메인)
///
/// 헤더와 그리드의 좌우 패딩을 자체 관리.
/// [HomeSection]에서는 `applyHorizontalPadding: false`로 사용.
class RecommendationSection extends ConsumerWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: HomeLayout.screenPadding,
          child: SectionHeader(
            title: '궁합 매칭 추천 이성',
            actionLabel: '더보기',
            onAction: () => context.go(RoutePaths.matching),
          ),
        ),
        HomeLayout.gapHeaderContent,
        recommendations.when(
          loading: () => _buildGridSkeleton(),
          error: (_, _) => Padding(
            padding: HomeLayout.screenPadding,
            child: const _EmptyState(message: '추천을 불러오지 못했어요'),
          ),
          data: (profiles) => _RecommendationGrid(profiles: profiles),
        ),
      ],
    );
  }

  static Widget _buildGridSkeleton() {
    return Padding(
      padding: HomeLayout.screenPadding,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: HomeLayout.gridCrossAxisCount,
          crossAxisSpacing: HomeLayout.gridSpacing,
          mainAxisSpacing: HomeLayout.gridSpacing,
          childAspectRatio: HomeLayout.gridChildAspectRatio,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => const SkeletonCard(),
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({required this.profiles});

  final List<MatchProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Padding(
        padding: HomeLayout.screenPadding,
        child: const _EmptyState(message: '아직 추천이 준비되지 않았어요'),
      );
    }

    final displayProfiles = profiles.take(HomeLayout.gridMaxItems).toList();

    return Padding(
      padding: HomeLayout.screenPadding,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: HomeLayout.gridCrossAxisCount,
          crossAxisSpacing: HomeLayout.gridSpacing,
          mainAxisSpacing: HomeLayout.gridSpacing,
          childAspectRatio: HomeLayout.gridChildAspectRatio,
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
            isPhoneVerified: profile.isPhoneVerified,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
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
