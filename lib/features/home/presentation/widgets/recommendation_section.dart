import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/domain/entities/match_profile.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션: 궁합이 좋은 인연들 (2열 그리드)
///
/// 헤더와 그리드의 좌우 패딩을 자체 관리.
/// [HomeSection]에서는 `applyHorizontalPadding: false`로 사용.
/// 데이터 없으면 SizedBox.shrink() 반환.
class RecommendationSection extends ConsumerWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionedAsync = ref.watch(sectionedRecommendationsNotifierProvider);

    return sectionedAsync.when(
      loading: () => _buildGridSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (sectioned) {
        final profiles = sectioned.compatibilityMatches;
        if (profiles.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeLayout.gapSection,
            Padding(
              padding: HomeLayout.screenPadding,
              child: SectionHeader(
                title: '궁합이 좋은 인연들',
                actionLabel: '더보기',
                onAction: () {
                  AnalyticsService.clickSeeMoreInHome(
                      section: 'compatibility');
                  context.go(RoutePaths.matching);
                },
              ),
            ),
            HomeLayout.gapHeaderContent,
            _RecommendationGrid(profiles: profiles),
          ],
        );
      },
    );
  }

  static Widget _buildGridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeLayout.gapSection,
        Padding(
          padding: HomeLayout.screenPadding,
          child: const SectionHeader(title: '궁합이 좋은 인연들'),
        ),
        HomeLayout.gapHeaderContent,
        Padding(
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
        ),
      ],
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({required this.profiles});

  final List<MatchProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final displayProfiles =
        profiles.take(HomeLayout.compatMaxItems).toList();

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
            heroTag: 'compat_char_${profile.userId}_$index',
            onTap: () {
              AnalyticsService.clickCardInHome(section: 'compatibility');
              context.push(
                RoutePaths.profileDetail,
                extra: {
                  'profile': profile,
                  'heroTag': 'compat_char_${profile.userId}_$index',
                },
              );
            },
          );
        },
      ),
    );
  }
}
