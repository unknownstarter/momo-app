// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserProfileHash() => r'currentUserProfile';

/// 현재 로그인 유저의 프로필 (async)
///
/// Copied from [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider =
    AutoDisposeFutureProvider<UserEntity?>.internal(
  currentUserProfile,
  name: r'currentUserProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = AutoDisposeFutureProviderRef<UserEntity?>;
String _$hasProfileHash() => r'hasProfile';

/// 프로필 존재 여부 (온보딩 완료 판별)
///
/// Copied from [hasProfile].
@ProviderFor(hasProfile)
final hasProfileProvider = AutoDisposeFutureProvider<bool>.internal(
  hasProfile,
  name: r'hasProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasProfileRef = AutoDisposeFutureProviderRef<bool>;
String _$authNotifierHash() => r'authNotifier';

/// Auth 액션 노티파이어 (로그인/로그아웃)
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, void>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
