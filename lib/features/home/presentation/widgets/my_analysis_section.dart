/// 홈 섹션: 내 운명 분석 (사주 + 관상 2-카드)
///
/// 사주 카드와 관상 카드를 나란히 배치하여
/// 각각 DestinyResultPage의 해당 탭으로 이동한다.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/domain/entities/saju_entity.dart';
import '../../../saju/presentation/providers/saju_provider.dart';
import '../constants/home_layout.dart';
import '../providers/my_analysis_provider.dart';
import 'section_header.dart';

/// 내 운명 분석 섹션 (사주 카드 + 관상 카드)
class MyAnalysisSection extends ConsumerWidget {
  const MyAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(myAnalysisProvider);

    return analysisAsync.when(
      loading: () => _buildSkeleton(context),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        // 둘 다 없으면 숨김
        if (data.saju == null && data.gwansang == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '내 운명 분석'),
            HomeLayout.gapHeaderContent,
            Row(
              children: [
                Expanded(
                  child: data.saju != null
                      ? _SajuCard(
                          profile: data.saju!,
                          gwansangProfile: data.gwansang,
                        )
                      : const _EmptyCard(label: '사주 분석 전'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: data.gwansang != null
                      ? _GwansangCard(
                          profile: data.gwansang!,
                          sajuProfile: data.saju,
                        )
                      : const _EmptyCard(label: '관상 분석 전'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final colors = context.sajuColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '내 운명 분석'),
        HomeLayout.gapHeaderContent,
        Row(
          children: [
            Expanded(child: _SkeletonCard(color: colors.bgElevated)),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard(color: colors.bgElevated)),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// 사주 카드
// =============================================================================

class _SajuCard extends StatelessWidget {
  const _SajuCard({required this.profile, this.gwansangProfile});

  final SajuProfile profile;
  final GwansangProfile? gwansangProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final element = profile.dominantElement ?? FiveElementType.wood;
    final characterName = CharacterAssets.nameFor(element);
    final characterAsset = _randomCharacterAsset(element);
    final elementColor = AppTheme.fiveElementColor(element.korean);

    // 오행 라벨: "목(木) 기운"
    final elementLabel = '${element.korean}(${element.hanja}) 기운';

    // 성격 특성 최대 2개
    final traits = profile.personalityTraits.take(2).toList();

    return GestureDetector(
      onTap: () => _navigateToDestiny(context, 0),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 캐릭터 이미지 + 이름
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elementColor.withValues(alpha: 0.1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      characterAsset,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          characterName.characters.first,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: elementColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        characterName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 오행 칩
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: elementColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          elementLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: elementColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 성격 특성
            if (traits.isNotEmpty)
              Text(
                traits.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),

            const SizedBox(height: 6),

            // 하단 CTA
            Text(
              '내 사주 보기 >',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDestiny(BuildContext context, int tab) {
    final element = profile.dominantElement ?? FiveElementType.wood;
    final sajuResult = SajuAnalysisResult(
      profile: profile,
      characterName: CharacterAssets.nameFor(element),
      characterAssetPath: CharacterAssets.defaultFor(element),
      characterGreeting: _characterGreetingFor(element),
    );

    final extra = <String, dynamic>{
      'sajuResult': sajuResult,
      'initialTab': tab,
    };

    if (gwansangProfile != null) {
      extra['gwansangResult'] = GwansangAnalysisResult(
        profile: gwansangProfile!,
        isNewAnalysis: false,
      );
    }

    context.push(RoutePaths.destinyResult, extra: extra);
  }
}

// =============================================================================
// 관상 카드
// =============================================================================

class _GwansangCard extends StatelessWidget {
  const _GwansangCard({required this.profile, this.sajuProfile});

  final GwansangProfile profile;
  final SajuProfile? sajuProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;

    // 동물 이모지 매핑
    final animalEmoji = _animalEmoji(profile.animalType);

    // 매력 키워드 최대 2개
    final charms = profile.charmKeywords.take(2).toList();

    return GestureDetector(
      onTap: () => _navigateToDestiny(context, 1),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 동물 이모지 + 라벨
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.mysticGlow.withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: Text(
                      animalEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    profile.animalLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 매력 키워드
            if (charms.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: charms.map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mysticGlow.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.mysticGlow.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 6),

            // 하단 CTA
            Text(
              '내 관상 보기 >',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDestiny(BuildContext context, int tab) {
    final gwansangResult = GwansangAnalysisResult(
      profile: profile,
      isNewAnalysis: false,
    );

    final extra = <String, dynamic>{
      'gwansangResult': gwansangResult,
      'initialTab': tab,
    };

    if (sajuProfile != null) {
      final element = sajuProfile!.dominantElement ?? FiveElementType.wood;
      extra['sajuResult'] = SajuAnalysisResult(
        profile: sajuProfile!,
        characterName: CharacterAssets.nameFor(element),
        characterAssetPath: CharacterAssets.defaultFor(element),
        characterGreeting: _characterGreetingFor(element),
      );
    }

    context.push(RoutePaths.destinyResult, extra: extra);
  }

  String _animalEmoji(String animalType) {
    return switch (animalType.toLowerCase()) {
      'cat' => '\u{1F431}',
      'dog' => '\u{1F436}',
      'fox' => '\u{1F98A}',
      'rabbit' => '\u{1F430}',
      'bear' => '\u{1F43B}',
      'deer' => '\u{1F98C}',
      'wolf' => '\u{1F43A}',
      'lion' => '\u{1F981}',
      'tiger' => '\u{1F42F}',
      'eagle' => '\u{1F985}',
      'owl' => '\u{1F989}',
      'dolphin' => '\u{1F42C}',
      'horse' => '\u{1F434}',
      'penguin' => '\u{1F427}',
      _ => '\u{2728}',
    };
  }
}

// =============================================================================
// 빈 카드 / 스켈레톤
// =============================================================================

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    );
  }
}

// =============================================================================
// 오행별 캐릭터 기본 인사말
// =============================================================================

/// 오행 → 캐릭터 기본 인사말 (saju_provider.dart의 _characterMap과 동일)
String _characterGreetingFor(FiveElementType element) {
  return switch (element) {
    FiveElementType.wood => '안녕! 나는 나무리야. 너의 성장하는 기운이 느껴져!',
    FiveElementType.fire => '반가워! 나는 불꼬리야. 너의 열정이 활활 타오르고 있어!',
    FiveElementType.earth => '어서와! 나는 흙순이야. 너의 든든한 기운이 좋아!',
    FiveElementType.metal => '안녕! 나는 쇠동이야. 너의 단단한 의지가 느껴져!',
    FiveElementType.water => '반가워! 나는 물결이야. 너의 깊은 지혜가 느껴져!',
  };
}

// =============================================================================
// 랜덤 캐릭터 에셋 선택
// =============================================================================

/// 오행에 해당하는 캐릭터의 랜덤 표정/포즈를 반환한다.
/// bulkkori(화)는 expressions 폴더가 없으므로 poses만 사용.
String _randomCharacterAsset(FiveElementType element) {
  final random = Random();
  final char = CharacterAssets.pathFor(element);

  final variants = <String>[];

  // 모든 캐릭터는 poses를 가짐
  for (final pose in ['waving', 'sitting', 'standing']) {
    variants.add(char.pose(pose));
  }

  // bulkkori(fire)는 expressions가 없음
  if (element != FiveElementType.fire) {
    for (final expr in ['love', 'laugh', 'surprised', 'default']) {
      variants.add(char.expression(expr));
    }
  }

  return variants[random.nextInt(variants.length)];
}
