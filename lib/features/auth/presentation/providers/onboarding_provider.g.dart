// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingNotifierHash() => r'onboarding_notifier_hash';

/// 온보딩 데이터를 Supabase에 저장하는 노티파이어
///
/// Copied from [OnboardingNotifier].
@ProviderFor(OnboardingNotifier)
final onboardingNotifierProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingNotifier, UserEntity?>.internal(
  OnboardingNotifier.new,
  name: r'onboardingNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$onboardingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingNotifier = AutoDisposeAsyncNotifier<UserEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
