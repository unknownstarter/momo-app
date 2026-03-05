/// 관상 분석 Riverpod Providers
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/gwansang_entity.dart';

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
  @override
  FutureOr<GwansangAnalysisResult?> build() {
    return null;
  }

  /// 전체 관상 분석 실행 (Claude Vision API)
  ///
  /// [photoUrls]: profiles.profile_images에 이미 업로드된 사진 URL 목록
  Future<void> analyze({
    required String userId,
    required List<String> photoUrls,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    state = const AsyncLoading();

    debugPrint('[GwansangProvider] analyze 시작: userId=$userId, photoUrls=${photoUrls.length}, gender=$gender, age=$age');

    if (photoUrls.isEmpty) {
      state = AsyncError(
        Exception('관상 분석을 위한 사진이 없어요. 사진을 등록해 주세요.'),
        StackTrace.current,
      );
      return;
    }

    state = await AsyncValue.guard(() async {
      debugPrint('[GwansangProvider] Repository 호출 시작 (Claude Vision)...');
      final repository = ref.read(gwansangRepositoryProvider);
      final profile = await repository.analyzeGwansang(
        userId: userId,
        photoUrls: photoUrls,
        sajuData: sajuData,
        gender: gender,
        age: age,
      );
      debugPrint('[GwansangProvider] 관상 분석 완료: animalType=${profile.animalType}, headline=${profile.headline}');

      return GwansangAnalysisResult(profile: profile, isNewAnalysis: true);
    });

    if (state.hasError) {
      debugPrint('[GwansangProvider] 관상 분석 실패: ${state.error}');
      debugPrint('[GwansangProvider] 스택: ${state.stackTrace}');
    }
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
