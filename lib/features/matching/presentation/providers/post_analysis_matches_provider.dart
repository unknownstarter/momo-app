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

/// 분석 완료 후 매칭 추천 목록 (궁합 점수 내림차순, 최대 5명)
///
/// 온보딩 직후 최초 매칭을 생성(isInitial=true)하고,
/// 운명 섹션 → 궁합 섹션 순으로 상위 5명을 반환한다.
@riverpod
class PostAnalysisMatches extends _$PostAnalysisMatches {
  @override
  Future<List<MatchProfile>> build() async {
    return _fetchInitialMatches();
  }

  /// 최초 매칭 5명 조회
  Future<List<MatchProfile>> _fetchInitialMatches() async {
    final repo = ref.read(matchingRepositoryProvider);

    // 최초 매칭: isInitial=true로 상위 5명만 생성
    await repo.ensureDailyRecommendations(isInitial: true);
    final sectioned = await repo.getSectionedRecommendations();

    // destiny 섹션에서 최대 5명 (isInitial=true이면 상위 5명이 destiny에 들어감)
    final matches = sectioned.destinyMatches.take(5).toList();

    // 만약 destiny가 비어있으면 compatibility에서 가져옴
    if (matches.isEmpty) {
      return sectioned.compatibilityMatches.take(5).toList();
    }

    return matches;
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitialMatches());
  }
}
