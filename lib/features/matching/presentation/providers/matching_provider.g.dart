// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
String _$sectionedRecommendationsNotifierHash() =>
    r'sectionedRecommendationsNotifier';

/// 섹션별 추천 Provider
///
/// Copied from [SectionedRecommendationsNotifier].
@ProviderFor(SectionedRecommendationsNotifier)
final sectionedRecommendationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SectionedRecommendationsNotifier,
        SectionedRecommendations>.internal(
  SectionedRecommendationsNotifier.new,
  name: r'sectionedRecommendationsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sectionedRecommendationsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SectionedRecommendationsNotifier
    = AutoDisposeAsyncNotifier<SectionedRecommendations>;
String _$photoRevealNotifierHash() => r'photoRevealNotifier';

/// 사진 열람 Provider
///
/// Copied from [PhotoRevealNotifier].
@ProviderFor(PhotoRevealNotifier)
final photoRevealNotifierProvider =
    AutoDisposeNotifierProvider<PhotoRevealNotifier, AsyncValue<void>>.internal(
  PhotoRevealNotifier.new,
  name: r'photoRevealNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$photoRevealNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PhotoRevealNotifier = AutoDisposeNotifier<AsyncValue<void>>;
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
String _$sentLikesHash() => r'sentLikes';

/// 보낸 좋아요 목록 상태 관리
///
/// Copied from [SentLikes].
@ProviderFor(SentLikes)
final sentLikesProvider =
    AutoDisposeAsyncNotifierProvider<SentLikes, List<SentLike>>.internal(
  SentLikes.new,
  name: r'sentLikesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sentLikesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SentLikes = AutoDisposeAsyncNotifier<List<SentLike>>;
String _$activeMatchesHash() => r'activeMatches';

/// 활성 매칭 목록 상태 관리
///
/// Copied from [ActiveMatches].
@ProviderFor(ActiveMatches)
final activeMatchesProvider =
    AutoDisposeAsyncNotifierProvider<ActiveMatches, List<Match>>.internal(
  ActiveMatches.new,
  name: r'activeMatchesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeMatchesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveMatches = AutoDisposeAsyncNotifier<List<Match>>;
String _$receivedLikesWithProfilesHash() => r'receivedLikesWithProfiles';

/// 받은 좋아요 + 프로필 정보 함께 관리
///
/// Copied from [ReceivedLikesWithProfiles].
@ProviderFor(ReceivedLikesWithProfiles)
final receivedLikesWithProfilesProvider = AutoDisposeAsyncNotifierProvider<
    ReceivedLikesWithProfiles,
    List<({Like like, MatchProfile profile})>>.internal(
  ReceivedLikesWithProfiles.new,
  name: r'receivedLikesWithProfilesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$receivedLikesWithProfilesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReceivedLikesWithProfiles
    = AutoDisposeAsyncNotifier<List<({Like like, MatchProfile profile})>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
