/// 분석 완료 후 매칭 추천 Provider
///
/// 사주+관상 분석 후 궁합 점수 내림차순으로 정렬된 프로필 목록.
/// [DailyRecommendations]와 같은 데이터 소스를 사용하되,
/// 궁합 점수로 정렬하여 Best Match를 상단에 노출한다.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/match_profile.dart';

part 'post_analysis_matches_provider.g.dart';

/// 분석 완료 후 매칭 추천 목록 (궁합 점수 내림차순)
@riverpod
class PostAnalysisMatches extends _$PostAnalysisMatches {
  @override
  Future<List<MatchProfile>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    final profiles = await repo.getDailyRecommendations();
    // 궁합 점수 내림차순 정렬 — Best Match가 최상단
    final sorted = List<MatchProfile>.from(profiles)
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    return sorted;
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profiles =
          await ref.read(matchingRepositoryProvider).getDailyRecommendations();
      return List<MatchProfile>.from(profiles)
        ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    });
  }
}
