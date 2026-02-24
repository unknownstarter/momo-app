// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saju_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sajuRemoteDatasourceHash() => r'sajuRemoteDatasource';

/// 사주 Remote 데이터소스 Provider
///
/// Copied from [sajuRemoteDatasource].
@ProviderFor(sajuRemoteDatasource)
final sajuRemoteDatasourceProvider =
    AutoDisposeProvider<SajuRemoteDatasource>.internal(
  sajuRemoteDatasource,
  name: r'sajuRemoteDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuRemoteDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuRemoteDatasourceRef = AutoDisposeProviderRef<SajuRemoteDatasource>;
String _$sajuRepositoryHash() => r'sajuRepository';

/// 사주 Repository Provider
///
/// Copied from [sajuRepository].
@ProviderFor(sajuRepository)
final sajuRepositoryProvider = AutoDisposeProvider<SajuRepository>.internal(
  sajuRepository,
  name: r'sajuRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuRepositoryRef = AutoDisposeProviderRef<SajuRepository>;
String _$sajuAnalysisNotifierHash() => r'sajuAnalysisNotifier';

/// 사주 분석 상태 관리 Notifier
///
/// Copied from [SajuAnalysisNotifier].
@ProviderFor(SajuAnalysisNotifier)
final sajuAnalysisNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SajuAnalysisNotifier, SajuAnalysisResult?>.internal(
  SajuAnalysisNotifier.new,
  name: r'sajuAnalysisNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuAnalysisNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SajuAnalysisNotifier = AutoDisposeAsyncNotifier<SajuAnalysisResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
