import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션 4: 받은 좋아요 + 카운트 뱃지
class ReceivedLikesSection extends ConsumerWidget {
  const ReceivedLikesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedLikes = ref.watch(receivedLikesProvider);

    // 데이터 없음/에러/로딩 중 → 섹션 전체 숨김 (휑함 방지)
    return receivedLikes.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (likes) {
        if (likes.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeLayout.gapSection,
            SectionHeader(
              title: '받은 좋아요',
              badgeCount: likes.length,
            ),
            HomeLayout.gapHeaderContent,
            _ReceivedLikesCard(
              count: likes.length,
              onTap: () {
                AnalyticsService.clickCardInHome(section: 'received_likes');
                ref.read(matchingTabSegmentProvider.notifier).state = 2;
                context.go(RoutePaths.matching);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ReceivedLikesCard extends StatelessWidget {
  const _ReceivedLikesCard({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.sajuColors.bgElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: context.sajuColors.borderDefault),
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
                            border:
                                Border.all(color: Colors.white, width: 2),
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
      ),
    );
  }
}
