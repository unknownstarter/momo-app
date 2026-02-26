/// 관상 분석 Repository 인터페이스
///
/// 관상 분석의 전체 흐름(사진 업로드 -> 측정 -> AI 해석 -> 저장)과
/// 저장된 프로필 조회를 추상화합니다.
/// domain 레이어에 위치하며, 구현체는 data 레이어에 존재합니다.
library;

import '../entities/face_measurements.dart';
import '../entities/gwansang_entity.dart';

/// 관상 분석 Repository 인터페이스
///
/// 관상 분석의 핵심 비즈니스 흐름을 정의합니다:
/// 1. [analyzeGwansang]: 사진 -> ML Kit 측정 -> AI 해석 -> DB 저장
/// 2. [getGwansangProfile]: 기존 분석 결과 조회
abstract class GwansangRepository {
  /// 관상 분석 실행 (사진 업로드 + 측정 + AI 해석 + 저장)
  ///
  /// [userId]: 분석 대상 사용자 ID
  /// [photoLocalPaths]: 로컬 사진 경로 목록 (1~3장)
  /// [measurements]: ML Kit에서 추출한 얼굴 측정값
  /// [sajuData]: 사주팔자 데이터 (오행 시너지 분석용)
  /// [gender]: 성별 ("male" | "female")
  /// [age]: 나이
  ///
  /// 반환: 완전한 [GwansangProfile] 엔티티
  ///
  /// 예외:
  /// - [ServerFailure]: Edge Function 호출 실패
  /// - [StorageFailure]: 사진 업로드 실패
  Future<GwansangProfile> analyzeGwansang({
    required String userId,
    required List<String> photoLocalPaths,
    required FaceMeasurements measurements,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  });

  /// 저장된 관상 프로필 조회
  ///
  /// [userId]: 조회할 사용자 ID
  ///
  /// 반환: 저장된 [GwansangProfile], 없으면 null
  Future<GwansangProfile?> getGwansangProfile(String userId);
}
