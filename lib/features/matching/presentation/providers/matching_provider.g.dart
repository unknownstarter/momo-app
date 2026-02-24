// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchingRepositoryHash() => r'matchingRepository';

/// 매칭 Repository Provider
///
/// Copied from [matchingRepository].
@ProviderFor(matchingRepository)
final matchingRepositoryProvider =
    AutoDisposeProvider<MatchingRepository>.internal(
  matchingRepository,
  name: r'matchingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$matchingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchingRepositoryRef = AutoDisposeProviderRef<MatchingRepository>;
String _$dailyRecommendationsHash() => r'dailyRecommendations';

/// 오늘의 매칭 추천 목록 상태 관리
///
/// Copied from [DailyRecommendations].
@ProviderFor(DailyRecommendations)
final dailyRecommendationsProvider = AutoDisposeAsyncNotifierProvider<
    DailyRecommendations, List<MatchProfile>>.internal(
  DailyRecommendations.new,
  name: r'dailyRecommendationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyRecommendationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DailyRecommendations = AutoDisposeAsyncNotifier<List<MatchProfile>>;
String _$compatibilityPreviewHash() => r'compatibilityPreview';

/// 궁합 프리뷰 상태 관리
///
/// Copied from [CompatibilityPreview].
@ProviderFor(CompatibilityPreview)
final compatibilityPreviewProvider = AutoDisposeAsyncNotifierProvider<
    CompatibilityPreview, Compatibility?>.internal(
  CompatibilityPreview.new,
  name: r'compatibilityPreviewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$compatibilityPreviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CompatibilityPreview = AutoDisposeAsyncNotifier<Compatibility?>;
String _$receivedLikesHash() => r'receivedLikes';

/// 받은 좋아요 목록 상태 관리
///
/// Copied from [ReceivedLikes].
@ProviderFor(ReceivedLikes)
final receivedLikesProvider =
    AutoDisposeAsyncNotifierProvider<ReceivedLikes, List<Like>>.internal(
  ReceivedLikes.new,
  name: r'receivedLikesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$receivedLikesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReceivedLikes = AutoDisposeAsyncNotifier<List<Like>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
