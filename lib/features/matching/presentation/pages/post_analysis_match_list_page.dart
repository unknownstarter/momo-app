/// 분석 완료 후 매칭 리스트 페이지
///
/// 사주+관상 분석 완료 후 궁합 점수가 높은 순으로 추천 프로필을 리스트로 보여준다.
/// 카드를 탭하면 궁합 프리뷰 바텀시트가 열리고,
/// 하단 CTA로 홈으로 이동할 수 있다.
///
/// ```
/// ┌──────────────────────────────────┐
/// │         캐릭터 (64px)            │
/// │       분석 완료!                 │
/// │ 최적의 궁합을 가진 상대를 찾았습니다│
/// ├──────────────────────────────────┤
/// │  ┌─ MatchListTile ★ Best ──┐    │
/// │  └─────────────────────────┘    │
/// │  ┌─ MatchListTile ─────────┐    │
/// │  └─────────────────────────┘    │
/// │  ...                            │
/// ├──────────────────────────────────┤
/// │    [처음으로 돌아가기]            │
/// └──────────────────────────────────┘
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/post_analysis_matches_provider.dart';
import '../widgets/match_list_tile.dart';
import 'compatibility_preview_page.dart';

/// 분석 완료 후 매칭 추천 리스트
class PostAnalysisMatchListPage extends ConsumerWidget {
  const PostAnalysisMatchListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(postAnalysisMatchesProvider);
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // --- 헤더 ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SajuSpacing.space24,
              ),
              child: Column(
                children: [
                  SajuSpacing.gap32,

                  // 캐릭터 아이콘
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.waterPastel.withValues(alpha: 0.5),
                          AppTheme.waterPastel,
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.waterColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        CharacterAssets.mulgyeoriWaterDefault,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.favorite_rounded,
                          size: 28,
                          color: AppTheme.waterColor,
                        ),
                      ),
                    ),
                  ),

                  SajuSpacing.gap16,

                  Text(
                    '분석 완료!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SajuSpacing.gap8,

                  Text(
                    '최적의 궁합을 가진 상대를 찾았습니다',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SajuSpacing.gap24,
                ],
              ),
            ),

            // --- 매칭 리스트 ---
            Expanded(
              child: matchesAsync.when(
                loading: () => _buildLoadingSkeleton(context),
                error: (error, _) => Center(
                  child: SajuErrorState(
                    message: '추천 프로필을 불러오지 못했어요',
                    onRetry: () => ref
                        .read(postAnalysisMatchesProvider.notifier)
                        .refresh(),
                  ),
                ),
                data: (profiles) {
                  if (profiles.isEmpty) {
                    return Center(
                      child: SajuEmptyState(
                        message: '아직 매칭 상대가 없어요',
                        subtitle: '조금만 기다려 주세요,\n운명의 상대를 찾고 있어요',
                        characterAssetPath:
                            CharacterAssets.heuksuniEarthDefault,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SajuSpacing.space20,
                    ),
                    itemCount: profiles.length,
                    separatorBuilder: (_, _) => SajuSpacing.gap12,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      final showBestMatch = index == 0 &&
                          profile.compatibilityScore >= 70;

                      return MatchListTile(
                        profile: profile,
                        isBestMatch: showBestMatch,
                        onTap: () => showCompatibilityPreview(
                            context, ref, profile),
                        animationDelay:
                            Duration(milliseconds: 80 * index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- 하단 CTA ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          SajuSpacing.space24,
          SajuSpacing.space8,
          SajuSpacing.space24,
          SajuSpacing.space16,
        ),
        decoration: BoxDecoration(
          color: colors.bgPrimary,
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
            label: '처음으로 돌아가기',
            onPressed: () => context.go(RoutePaths.home),
            variant: SajuVariant.outlined,
            color: SajuColor.primary,
            size: SajuSize.lg,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colors = context.sajuColors;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space20),
      itemCount: 3,
      separatorBuilder: (_, _) => SajuSpacing.gap12,
      itemBuilder: (_, _) => Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          children: [
            // 아바타 스켈레톤
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.bgSecondary,
              ),
            ),
            SajuSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SajuSpacing.gap8,
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SajuSpacing.gap8,
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            SajuSpacing.hGap8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
