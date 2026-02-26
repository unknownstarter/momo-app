// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gwansang_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gwansangAnalysisNotifierHash() => r'gwansangAnalysisNotifier';

/// 관상 분석 상태 관리
///
/// Copied from [GwansangAnalysisNotifier].
@ProviderFor(GwansangAnalysisNotifier)
final gwansangAnalysisNotifierProvider = AutoDisposeAsyncNotifierProvider<
    GwansangAnalysisNotifier, GwansangAnalysisResult?>.internal(
  GwansangAnalysisNotifier.new,
  name: r'gwansangAnalysisNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gwansangAnalysisNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GwansangAnalysisNotifier
    = AutoDisposeAsyncNotifier<GwansangAnalysisResult?>;
String _$photoValidatorHash() => r'photoValidator';

/// 사진 유효성 검증 Provider
///
/// Copied from [PhotoValidator].
@ProviderFor(PhotoValidator)
final photoValidatorProvider =
    AutoDisposeAsyncNotifierProvider<PhotoValidator, bool?>.internal(
  PhotoValidator.new,
  name: r'photoValidatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$photoValidatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PhotoValidator = AutoDisposeAsyncNotifier<bool?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
