import 'match_profile.dart';

/// 섹션별 일일 추천 결과
///
/// 운명의 매칭, 궁합 매칭, 관상 매칭, 신규 유저 등 섹션별로 분류된 추천 목록.
class SectionedRecommendations {
  const SectionedRecommendations({
    this.destinyMatches = const [],
    this.compatibilityMatches = const [],
    this.gwansangMatches = const [],
    this.newUserMatches = const [],
  });

  /// 운명의 매칭 (궁합 85+ 또는 일주 합)
  final List<MatchProfile> destinyMatches;

  /// 궁합 매칭 (궁합 점수 상위)
  final List<MatchProfile> compatibilityMatches;

  /// 관상 매칭 (관상 traits 유사도 기반)
  final List<MatchProfile> gwansangMatches;

  /// 신규 유저 매칭 (최근 가입자)
  final List<MatchProfile> newUserMatches;

  int get totalCount =>
      destinyMatches.length +
      compatibilityMatches.length +
      gwansangMatches.length +
      newUserMatches.length;

  bool get hasDestiny => destinyMatches.isNotEmpty;
  bool get hasCompatibility => compatibilityMatches.isNotEmpty;
  bool get hasGwansang => gwansangMatches.isNotEmpty;
  bool get hasNewUsers => newUserMatches.isNotEmpty;

  SectionedRecommendations copyWith({
    List<MatchProfile>? destinyMatches,
    List<MatchProfile>? compatibilityMatches,
    List<MatchProfile>? gwansangMatches,
    List<MatchProfile>? newUserMatches,
  }) {
    return SectionedRecommendations(
      destinyMatches: destinyMatches ?? this.destinyMatches,
      compatibilityMatches: compatibilityMatches ?? this.compatibilityMatches,
      gwansangMatches: gwansangMatches ?? this.gwansangMatches,
      newUserMatches: newUserMatches ?? this.newUserMatches,
    );
  }

  @override
  String toString() =>
      'SectionedRecommendations(destiny: ${destinyMatches.length}, '
      'compatibility: ${compatibilityMatches.length}, '
      'gwansang: ${gwansangMatches.length}, '
      'newUsers: ${newUserMatches.length})';
}
