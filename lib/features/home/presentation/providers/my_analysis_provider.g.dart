// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_analysis_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myAnalysisHash() => r'myAnalysis';

/// 내 사주 + 관상 데이터를 병렬로 로드하는 Provider
///
/// Copied from [myAnalysis].
@ProviderFor(myAnalysis)
final myAnalysisProvider = AutoDisposeFutureProvider<
    ({SajuProfile? saju, GwansangProfile? gwansang})>.internal(
  myAnalysis,
  name: r'myAnalysisProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myAnalysisHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyAnalysisRef = AutoDisposeFutureProviderRef<
    ({SajuProfile? saju, GwansangProfile? gwansang})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
