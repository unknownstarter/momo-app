/// 관상 분석 Riverpod Providers
library;

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/gwansang_entity.dart';
import '../../domain/services/face_analyzer_service.dart';

part 'gwansang_provider.g.dart';

/// 관상 분석 결과 (프레젠테이션용)
class GwansangAnalysisResult {
  const GwansangAnalysisResult({
    required this.profile,
    required this.isNewAnalysis,
  });

  final GwansangProfile profile;
  final bool isNewAnalysis;
}

/// 관상 분석 상태 관리
@riverpod
class GwansangAnalysisNotifier extends _$GwansangAnalysisNotifier {
  FaceAnalyzerService? _faceAnalyzer;

  @override
  FutureOr<GwansangAnalysisResult?> build() {
    ref.onDispose(() => _faceAnalyzer?.dispose());
    return null;
  }

  /// 전체 관상 분석 실행
  Future<void> analyze({
    required String userId,
    required List<String> photoLocalPaths,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      _faceAnalyzer ??= FaceAnalyzerService();

      final images = photoLocalPaths.map((p) => File(p)).toList();
      final measurements = await _faceAnalyzer!.analyzeMultiple(images);

      if (measurements == null) {
        throw Exception('얼굴을 감지하지 못했어요. 정면 사진으로 다시 시도해주세요.');
      }

      final repository = ref.read(gwansangRepositoryProvider);
      final profile = await repository.analyzeGwansang(
        userId: userId,
        photoLocalPaths: photoLocalPaths,
        measurements: measurements,
        sajuData: sajuData,
        gender: gender,
        age: age,
      );

      return GwansangAnalysisResult(profile: profile, isNewAnalysis: true);
    });
  }

  /// 기존 관상 프로필 로드
  Future<void> loadExisting(String userId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(gwansangRepositoryProvider);
      final profile = await repository.getGwansangProfile(userId);
      if (profile == null) return null;
      return GwansangAnalysisResult(profile: profile, isNewAnalysis: false);
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// 사진 유효성 검증 Provider
@riverpod
class PhotoValidator extends _$PhotoValidator {
  FaceAnalyzerService? _analyzer;

  @override
  FutureOr<bool?> build() {
    ref.onDispose(() => _analyzer?.dispose());
    return null;
  }

  Future<bool> validate(String path) async {
    _analyzer ??= FaceAnalyzerService();
    return _analyzer!.validatePhoto(File(path));
  }
}
