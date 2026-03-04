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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀은 항상 표시, 뱃지만 데이터에 따라 조건부
        SectionHeader(
          title: '받은 좋아요',
          badgeCount: receivedLikes.valueOrNull?.isNotEmpty == true
              ? receivedLikes.valueOrNull!.length
              : null,
        ),
        HomeLayout.gapHeaderContent,
        receivedLikes.when(
          loading: () => Container(
            height: 64,
            decoration: BoxDecoration(
              color: context.sajuColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (likes) => _ReceivedLikesCard(
            count: likes.length,
            onTap: () {
              AnalyticsService.clickCardInHome(section: 'received_likes');
              // "받은" 세그먼트(인덱스 2)로 설정 후 매칭 탭 이동
              ref.read(matchingTabSegmentProvider.notifier).state = 2;
              context.go(RoutePaths.matching);
            },
          ),
        ),
      ],
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
