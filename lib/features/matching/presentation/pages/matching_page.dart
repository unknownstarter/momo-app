import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/match_profile.dart';
import '../providers/matching_provider.dart';
import '../widgets/matching_segment_control.dart';
import '../widgets/received_like_tile.dart';
import '../widgets/sent_like_tile.dart';

/// MatchingPage — 매칭 탭 (3-Segment: 추천 / 보낸 / 받은)
///
/// 세그먼트 컨트롤로 상태별 분류, 추천 탭에만 오행 필터 제공.
class MatchingPage extends ConsumerStatefulWidget {
  const MatchingPage({super.key});

  @override
  ConsumerState<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends ConsumerState<MatchingPage> {
  String? _selectedFilter;

  static const _filters = [
    _Filter(label: '전체', value: null),
    _Filter(label: '나무', value: 'wood', color: SajuColor.wood),
    _Filter(label: '불', value: 'fire', color: SajuColor.fire),
    _Filter(label: '흙', value: 'earth', color: SajuColor.earth),
    _Filter(label: '금', value: 'metal', color: SajuColor.metal),
    _Filter(label: '물', value: 'water', color: SajuColor.water),
  ];

  @override
  Widget build(BuildContext context) {
    final segment = ref.watch(matchingTabSegmentProvider);
    final receivedCount =
        ref.watch(receivedLikesProvider).valueOrNull?.length ?? 0;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ---- 헤더 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '매칭',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- 세그먼트 컨트롤 ----
            MatchingSegmentControl(
              selectedIndex: segment,
              onChanged: (index) =>
                  ref.read(matchingTabSegmentProvider.notifier).state = index,
              receivedBadge: receivedCount > 0 ? receivedCount : null,
            ),

            const SizedBox(height: 14),

            // ---- 추천 탭: 오행 필터 칩 ----
            if (segment == 0) ...[
              _buildFilterRow(),
              const SizedBox(height: 12),
            ],

            // ---- 콘텐츠 영역 ----
            Expanded(
              child: switch (segment) {
                0 => _buildRecommendationTab(context, textTheme),
                1 => _buildSentTab(context),
                2 => _buildReceivedTab(context),
                _ => const SizedBox.shrink(),
              },
            ),

            // ---- 하단 무료 좋아요 잔여 ----
            if (segment == 0) _buildBottomBar(context, textTheme),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 추천 탭
  // ===========================================================================

  Widget _buildRecommendationTab(BuildContext context, TextTheme textTheme) {
    final recommendations = ref.watch(filteredRecommendationsProvider);

    return recommendations.when(
      loading: () => const MomoLoading(),
      error: (_, _) => _buildErrorState(),
      data: (profiles) {
        final filtered = _selectedFilter == null
            ? profiles
            : profiles
                .where((p) => p.elementType == _selectedFilter)
                .toList();
        return _buildGrid(context, filtered, textTheme);
      },
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _filters.map((f) {
          final selected = _selectedFilter == f.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SajuChip(
              label: f.label,
              color: f.color,
              size: SajuSize.sm,
              isSelected: selected,
              onTap: () => setState(() => _selectedFilter = f.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<MatchProfile> profiles,
    TextTheme textTheme,
  ) {
    if (profiles.isEmpty) {
      return const SajuEmptyState(
        message: '해당 오행의 프로필이 없어요',
        subtitle: '다른 오행 필터를 눌러보거나, 내일 다시 확인해 주세요',
        characterAssetPath: CharacterAssets.heuksuniEarthDefault,
        characterName: '흙순이',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dailyRecommendationsProvider.notifier).refresh();
      },
      color: AppTheme.waterColor,
      child: GridView.builder(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 88,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemCount: profiles.length,
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
            isPhoneVerified: profile.isPhoneVerified,
            heroTag: 'match_char_${profile.userId}_$index',
            showCharacterInstead: true,
            onTap: () => context.push(
              RoutePaths.profileDetail,
              extra: {
                'profile': profile,
                'heroTag': 'match_char_${profile.userId}_$index',
                'source': 'recommendation',
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 보낸 탭
  // ===========================================================================

  Widget _buildSentTab(BuildContext context) {
    final sentLikes = ref.watch(sentLikesProvider);

    return sentLikes.when(
      loading: () => const MomoLoading(),
      error: (_, _) => SajuErrorState(
        message: '보낸 좋아요를 불러오지 못했어요',
        onRetry: () => ref.read(sentLikesProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SajuEmptyState(
            message: '아직 좋아요를 보내지 않았어요',
            subtitle: '추천 탭에서 마음에 드는 상대에게\n좋아요를 보내보세요',
            characterAssetPath: CharacterAssets.bulkkoriFireDefault,
            characterName: '불꼬리',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(sentLikesProvider.notifier).refresh();
          },
          color: AppTheme.waterColor,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => SajuSpacing.gap12,
            itemBuilder: (context, index) {
              final sentLike = items[index];
              return SentLikeTile(
                sentLike: sentLike,
                animationDelay: Duration(milliseconds: 80 * index),
                onTap: () => context.push(
                  RoutePaths.profileDetail,
                  extra: {
                    'profile': sentLike.profile,
                    'source': 'sent',
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 받은 탭
  // ===========================================================================

  Widget _buildReceivedTab(BuildContext context) {
    final receivedLikes = ref.watch(receivedLikesWithProfilesProvider);

    return receivedLikes.when(
      loading: () => const MomoLoading(),
      error: (_, _) => SajuErrorState(
        message: '받은 좋아요를 불러오지 못했어요',
        onRetry: () =>
            ref.read(receivedLikesWithProfilesProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SajuEmptyState(
            message: '아직 받은 좋아요가 없어요',
            subtitle: '프로필을 완성하면 더 많은\n좋아요를 받을 수 있어요',
            characterAssetPath: CharacterAssets.mulgyeoriWaterDefault,
            characterName: '물결이',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(receivedLikesWithProfilesProvider.notifier)
                .refresh();
          },
          color: AppTheme.waterColor,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => SajuSpacing.gap12,
            itemBuilder: (context, index) {
              final item = items[index];
              return ReceivedLikeTile(
                like: item.like,
                profile: item.profile,
                animationDelay: Duration(milliseconds: 80 * index),
                onAccept: () => _handleAcceptLike(context, item.like.id, item.profile),
                onReject: () => _handleRejectLike(item.like.id),
                onTap: () => context.push(
                  RoutePaths.profileDetail,
                  extra: {
                    'profile': item.profile,
                    'source': 'received',
                    'likeId': item.like.id,
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 액션 핸들러
  // ===========================================================================

  Future<void> _handleAcceptLike(
    BuildContext context,
    String likeId,
    MatchProfile profile,
  ) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.acceptLike(likeId);

    if (!context.mounted) return;

    // 매칭 축하 시트 표시
    await showMutualMatchCelebration(context, profile);

    // 데이터 새로고침
    ref.read(receivedLikesWithProfilesProvider.notifier).refresh();
    ref.read(receivedLikesProvider.notifier).refresh();
    ref.read(activeMatchesProvider.notifier).refresh();
  }

  Future<void> _handleRejectLike(String likeId) async {
    final repo = ref.read(matchingRepositoryProvider);
    await repo.rejectLike(likeId);

    // 데이터 새로고침
    ref.read(receivedLikesWithProfilesProvider.notifier).refresh();
    ref.read(receivedLikesProvider.notifier).refresh();
  }

  // ===========================================================================
  // 공통 위젯
  // ===========================================================================

  Widget _buildErrorState() {
    return SajuErrorState(
      message: '프로필을 불러오지 못했어요',
      onRetry: () =>
          ref.read(dailyRecommendationsProvider.notifier).refresh(),
    );
  }

  Widget _buildBottomBar(BuildContext context, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: SajuSpacing.space8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.fireColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '오늘 무료 좋아요 3/3회 남음',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filter {
  const _Filter({required this.label, required this.value, this.color});

  final String label;
  final String? value;
  final SajuColor? color;
}

/// 상호 매칭 축하 바텀시트 표시
Future<void> showMutualMatchCelebration(
  BuildContext context,
  MatchProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _MutualMatchCelebrationSheet(profile: profile),
  );
}

/// 매칭 성사 축하 바텀시트
class _MutualMatchCelebrationSheet extends StatelessWidget {
  const _MutualMatchCelebrationSheet({required this.profile});

  final MatchProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;
    final elementColor = AppTheme.fiveElementColor(profile.elementType);
    final elementPastel = AppTheme.fiveElementPastel(profile.elementType);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 24),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 32),

          // 축하 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.mysticGlow.withValues(alpha: 0.2),
                  AppTheme.mysticGlow.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: elementPastel.withValues(alpha: 0.3),
                  border: Border.all(
                    color: elementColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: profile.characterAssetPath != null
                      ? Image.asset(
                          profile.characterAssetPath!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.favorite_rounded,
                            size: 28,
                            color: elementColor,
                          ),
                        )
                      : Icon(
                          Icons.favorite_rounded,
                          size: 28,
                          color: elementColor,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '매칭 성사!',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${profile.name}님과 서로 좋아요를 보냈어요\n지금 바로 대화를 시작해보세요',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // 채팅 시작 버튼
          SizedBox(
            width: double.infinity,
            child: SajuButton(
              label: '채팅 시작하기',
              onPressed: () {
                Navigator.of(context).pop();
                // TODO(PROD): 실제 채팅방으로 라우팅
                context.go(RoutePaths.chat);
              },
              variant: SajuVariant.filled,
              color: SajuColor.primary,
              size: SajuSize.lg,
              leadingIcon: Icons.chat_bubble_outline_rounded,
            ),
          ),

          const SizedBox(height: 12),

          // 나중에 버튼
          SajuButton(
            label: '나중에 할게요',
            onPressed: () => Navigator.of(context).pop(),
            variant: SajuVariant.ghost,
            color: SajuColor.primary,
            size: SajuSize.md,
          ),
        ],
      ),
    );
  }
}
