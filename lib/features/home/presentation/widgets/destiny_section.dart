import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션: 운명의 매칭 (궁합 85%+ 또는 일주 합)
///
/// 수평 스크롤 카드, 금색 테두리 (isPremium), 최대 5명.
/// 데이터 없으면 섹션 전체 숨김 (SizedBox.shrink()).
class DestinySection extends ConsumerWidget {
  const DestinySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionedAsync = ref.watch(sectionedRecommendationsNotifierProvider);

    return sectionedAsync.when(
      loading: () => _buildSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (sectioned) {
        final profiles = sectioned.destinyMatches;
        if (profiles.isEmpty) return const SizedBox.shrink();

        final displayProfiles =
            profiles.take(HomeLayout.destinyMaxItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeLayout.gapSection,
            Padding(
              padding: HomeLayout.screenPadding,
              child: SectionHeader(
                title: '오늘의 운명 매칭',
                actionLabel: '더보기',
                onAction: () {
                  AnalyticsService.clickSeeMoreInHome(section: 'destiny');
                  context.go(RoutePaths.matching);
                },
              ),
            ),
            HomeLayout.gapHeaderContent,
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: HomeLayout.screenPadding,
                itemCount: displayProfiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                    isPremium: true,
                    width: 160,
                    heroTag: 'destiny_char_${profile.userId}_$index',
                    onTap: () {
                      AnalyticsService.clickCardInHome(section: 'destiny');
                      context.push(
                        RoutePaths.profileDetail,
                        extra: {
                          'profile': profile,
                          'heroTag': 'destiny_char_${profile.userId}_$index',
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeLayout.gapSection,
        Padding(
          padding: HomeLayout.screenPadding,
          child: const SectionHeader(title: '오늘의 운명 매칭'),
        ),
        HomeLayout.gapHeaderContent,
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: HomeLayout.screenPadding,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SizedBox(
              width: 160,
              child: SkeletonCard(),
            ),
          ),
        ),
      ],
    );
  }
}
