// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_analysis_matches_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postAnalysisMatchesHash() => r'postAnalysisMatches';

/// 분석 완료 후 매칭 추천 목록 (궁합 점수 내림차순)
///
/// Copied from [PostAnalysisMatches].
@ProviderFor(PostAnalysisMatches)
final postAnalysisMatchesProvider = AutoDisposeAsyncNotifierProvider<
    PostAnalysisMatches, List<MatchProfile>>.internal(
  PostAnalysisMatches.new,
  name: r'postAnalysisMatchesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postAnalysisMatchesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostAnalysisMatches = AutoDisposeAsyncNotifier<List<MatchProfile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
