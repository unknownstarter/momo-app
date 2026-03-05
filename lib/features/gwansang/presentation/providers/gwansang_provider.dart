/// 관상 분석 Riverpod Providers
library;

import 'dart:io';

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
  Future<void> analyze({
    required String userId,
    required List<String> photoLocalPaths,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    state = const AsyncLoading();

    debugPrint('[GwansangProvider] analyze 시작: userId=$userId, photos=${photoLocalPaths.length}, gender=$gender, age=$age');

    if (photoLocalPaths.isEmpty) {
      state = AsyncError(
        Exception('관상 분석을 위한 사진이 없어요. 사진을 등록해 주세요.'),
        StackTrace.current,
      );
      return;
    }

    // 파일 존재 여부 사전 검증
    for (final path in photoLocalPaths) {
      final exists = File(path).existsSync();
      debugPrint('[GwansangProvider] 사진 파일: $path (존재: $exists)');
      if (!exists) {
        state = AsyncError(
          Exception('사진 파일을 찾을 수 없어요: $path'),
          StackTrace.current,
        );
        return;
      }
    }

    state = await AsyncValue.guard(() async {
      debugPrint('[GwansangProvider] Repository 호출 시작 (Claude Vision)...');
      final repository = ref.read(gwansangRepositoryProvider);
      final profile = await repository.analyzeGwansang(
        userId: userId,
        photoLocalPaths: photoLocalPaths,
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
