import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/compatibility_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
// NOTE: saju_provider 참조는 현재 유저의 오행 캐릭터 정보를 읽기 위한
// presentation-level 크로스 피처 의존성입니다. 사주 분석 결과를
// 공유 상태로 리팩토링할 때 해소 예정입니다.
import '../../../saju/presentation/providers/saju_provider.dart';
import '../../domain/entities/match_profile.dart';
import '../providers/matching_provider.dart';

/// CompatibilityPreviewPage — 궁합 프리뷰 바텀시트 (토스 스타일 미니멀)
///
/// 다크 모드, 여백 넉넉, 타이포 위계 명확, 장식 최소화.
class CompatibilityPreviewPage extends ConsumerWidget {
  const CompatibilityPreviewPage({
    super.key,
    required this.partnerId,
    required this.partnerProfile,
    required this.scrollController,
  });

  final String partnerId;
  final MatchProfile partnerProfile;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatibilityAsync = ref.watch(compatibilityPreviewProvider);

    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.inkBlack,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHandle(),
                  const SizedBox(height: 28),

                  // --- 캐릭터 쌍 ---
                  _buildCharacterPair(context, textTheme, ref),

                  const SizedBox(height: 32),

                  // --- 궁합 결과 ---
                  compatibilityAsync.when(
                    loading: () => const SizedBox(
                      height: 280,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.mysticGlow,
                        ),
                      ),
                    ),
                    error: (_, _) => SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          '궁합 분석에 실패했어요',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    data: (compat) {
                      if (compat == null) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.mysticGlow,
                            ),
                          ),
                        );
                      }
                      return _buildResult(context, textTheme, compat);
                    },
                  ),

                  const SizedBox(height: 28),

                  // --- 액션 버튼 ---
                  _buildActions(context, textTheme),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 캐릭터 쌍: 내 캐릭터 + 상대 캐릭터 (깔끔한 원형)
  Widget _buildCharacterPair(
    BuildContext context,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    final partnerColor =
        AppTheme.fiveElementColor(partnerProfile.elementType);
    final partnerPastel =
        AppTheme.fiveElementPastel(partnerProfile.elementType);

    // 현재 유저의 사주 분석 결과에서 오행 캐릭터 정보를 가져옴
    final myAnalysis = ref.watch(sajuAnalysisNotifierProvider).valueOrNull;
    final myElement = myAnalysis?.profile.dominantElement?.name ?? 'wood';
    final myColor = AppTheme.fiveElementColor(myElement);
    final myPastel = AppTheme.fiveElementPastel(myElement);
    final myAssetPath =
        myAnalysis?.characterAssetPath ?? CharacterAssets.defaultForString(myElement);
    final myCharacterName =
        myAnalysis?.characterName ?? CharacterAssets.nameForString(myElement);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CharacterAvatar(
          label: '나',
          color: myColor,
          pastelColor: myPastel,
          assetPath: myAssetPath,
          characterName: myCharacterName,
        ),
        const SizedBox(width: 24),
        // 연결 점
        Column(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 20,
              color: AppTheme.mysticGlow.withValues(alpha: 0.5),
            ),
          ],
        ),
        const SizedBox(width: 24),
        _CharacterAvatar(
          label: partnerProfile.name,
          color: partnerColor,
          pastelColor: partnerPastel,
          assetPath: partnerProfile.characterAssetPath,
          characterName: partnerProfile.characterName,
        ),
      ],
    );
  }

  /// 궁합 결과: 게이지 + 강점/도전
  Widget _buildResult(
    BuildContext context,
    TextTheme textTheme,
    Compatibility compat,
  ) {
    return Column(
      children: [
        // 게이지
        CompatibilityGauge(
          score: compat.score,
          grade: compat.grade,
          size: 140,
          strokeWidth: 8,
        ),
        const SizedBox(height: 8),
        Text(
          compat.grade.description,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),

        const SizedBox(height: 32),

        // 강점
        if (compat.strengths.isNotEmpty) ...[
          _SectionList(
            title: '잘 맞는 점',
            items: compat.strengths,
            accentColor: AppTheme.woodColor,
          ),
          const SizedBox(height: 24),
        ],

        // 도전
        if (compat.challenges.isNotEmpty)
          _SectionList(
            title: '노력이 필요한 점',
            items: compat.challenges,
            accentColor: AppTheme.earthColor,
          ),
      ],
    );
  }

  /// 액션 버튼들
  Widget _buildActions(BuildContext context, TextTheme textTheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${partnerProfile.name}님에게 좋아요를 보냈어요'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.mysticGlow,
              foregroundColor: AppTheme.inkBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text(
              '좋아요 보내기',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {},
          child: Text(
            '500P로 상세 궁합 보기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 캐릭터 아바타
// =============================================================================

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({
    required this.label,
    required this.color,
    required this.pastelColor,
    this.assetPath,
    required this.characterName,
  });

  final String label;
  final Color color;
  final Color pastelColor;
  final String? assetPath;
  final String characterName;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pastelColor.withValues(alpha: 0.2),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: assetPath != null
                ? Image.asset(
                    assetPath!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        characterName.characters.first,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// =============================================================================
// 강점/도전 섹션 리스트 — 미니멀
// =============================================================================

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.items,
    required this.accentColor,
  });

  final String title;
  final List<String> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        ...items.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// =============================================================================
// 바텀시트 헬퍼
// =============================================================================

void showCompatibilityPreview(
  BuildContext context,
  WidgetRef ref,
  MatchProfile profile,
) {
  ref.read(compatibilityPreviewProvider.notifier).loadPreview(profile.userId);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => CompatibilityPreviewPage(
        partnerId: profile.userId,
        partnerProfile: profile,
        scrollController: scrollController,
      ),
    ),
  );
}
