import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션: 새로 가입한 인연
///
/// 2열 그리드, 최대 4명. 데이터 없으면 SizedBox.shrink().
class NewUsersSection extends ConsumerWidget {
  const NewUsersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionedAsync = ref.watch(sectionedRecommendationsNotifierProvider);

    return sectionedAsync.when(
      loading: () => _buildGridSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (sectioned) {
        final profiles = sectioned.newUserMatches;
        if (profiles.isEmpty) return const SizedBox.shrink();

        final displayProfiles =
            profiles.take(HomeLayout.newUsersMaxItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeLayout.gapSection,
            Padding(
              padding: HomeLayout.screenPadding,
              child: SectionHeader(
                title: '새로 가입한 인연',
                actionLabel: '더보기',
                onAction: () {
                  AnalyticsService.clickSeeMoreInHome(section: 'new_users');
                  context.go(RoutePaths.matching);
                },
              ),
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
                    isNew: true,
                    heroTag: 'new_user_char_${profile.userId}_$index',
                    onTap: () {
                      AnalyticsService.clickCardInHome(section: 'new_users');
                      context.push(
                        RoutePaths.profileDetail,
                        extra: {
                          'profile': profile,
                          'heroTag':
                              'new_user_char_${profile.userId}_$index',
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

  static Widget _buildGridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeLayout.gapSection,
        Padding(
          padding: HomeLayout.screenPadding,
          child: const SectionHeader(title: '새로 가입한 인연'),
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
