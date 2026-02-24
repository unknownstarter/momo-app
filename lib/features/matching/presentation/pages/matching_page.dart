import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/match_profile.dart';
import '../providers/matching_provider.dart';
import 'compatibility_preview_page.dart';

/// MatchingPage — 매칭 탭 (토스 스타일 미니멀)
///
/// 오행 필터 + 2열 프로필 그리드. 깔끔한 헤더, 넉넉한 그리드 간격,
/// 절제된 컬러 사용.
class MatchingPage extends ConsumerStatefulWidget {
  const MatchingPage({super.key});

  @override
  ConsumerState<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends ConsumerState<MatchingPage> {
  String? _selectedFilter;

  static const _filters = [
    _Filter(label: '전체', value: null),
    _Filter(label: '목', value: 'wood', color: SajuColor.wood),
    _Filter(label: '화', value: 'fire', color: SajuColor.fire),
    _Filter(label: '토', value: 'earth', color: SajuColor.earth),
    _Filter(label: '금', value: 'metal', color: SajuColor.metal),
    _Filter(label: '수', value: 'water', color: SajuColor.water),
  ];

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
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

            const SizedBox(height: 18),

            // ---- 필터 칩 ----
            _buildFilterRow(),

            const SizedBox(height: 16),

            // ---- 프로필 그리드 ----
            Expanded(
              child: recommendations.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => _buildErrorState(textTheme),
                data: (profiles) {
                  final filtered = _selectedFilter == null
                      ? profiles
                      : profiles
                          .where((p) => p.elementType == _selectedFilter)
                          .toList();
                  return _buildGrid(context, filtered, textTheme);
                },
              ),
            ),

            // ---- 하단 무료 좋아요 잔여 ----
            _buildBottomBar(context, textTheme),
          ],
        ),
      ),
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
      return Center(
        child: Text(
          '해당 오행의 프로필이 없어요',
          style: textTheme.bodyMedium?.copyWith(
            color: textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          onTap: () => showCompatibilityPreview(context, ref, profile),
        );
      },
    );
  }

  Widget _buildErrorState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '프로필을 불러오지 못했어요',
            style: textTheme.bodyMedium?.copyWith(
              color: textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                ref.read(dailyRecommendationsProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
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
