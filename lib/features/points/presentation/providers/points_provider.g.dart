// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userPointsNotifierHash() => r'userPointsNotifier';

/// 포인트 잔액 Provider (Mock: 500P로 시작)
///
/// Copied from [UserPointsNotifier].
@ProviderFor(UserPointsNotifier)
final userPointsNotifierProvider =
    AutoDisposeNotifierProvider<UserPointsNotifier, UserPoints>.internal(
  UserPointsNotifier.new,
  name: r'userPointsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userPointsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserPointsNotifier = AutoDisposeNotifier<UserPoints>;
String _$dailyUsageNotifierHash() => r'dailyUsageNotifier';

/// 일일 무료 사용량 Provider
///
/// Copied from [DailyUsageNotifier].
@ProviderFor(DailyUsageNotifier)
final dailyUsageNotifierProvider =
    AutoDisposeNotifierProvider<DailyUsageNotifier, DailyUsage>.internal(
  DailyUsageNotifier.new,
  name: r'dailyUsageNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyUsageNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DailyUsageNotifier = AutoDisposeNotifier<DailyUsage>;
String _$sendLikeNotifierHash() => r'sendLikeNotifier';

/// 좋아요 전송 로직 Provider
///
/// Copied from [SendLikeNotifier].
@ProviderFor(SendLikeNotifier)
final sendLikeNotifierProvider = AutoDisposeNotifierProvider<SendLikeNotifier,
    AsyncValue<void>>.internal(
  SendLikeNotifier.new,
  name: r'sendLikeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendLikeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SendLikeNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
