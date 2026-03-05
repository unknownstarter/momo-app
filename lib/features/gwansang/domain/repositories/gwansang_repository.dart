/// 관상 분석 Repository 인터페이스
///
/// Claude Vision AI를 통한 관상 해석과 결과 저장을 추상화합니다.
/// 사진은 이미 profiles.profile_images에 업로드된 URL을 사용합니다.
library;

import '../entities/gwansang_entity.dart';

/// 관상 분석 Repository 인터페이스
abstract class GwansangRepository {
  /// 관상 분석 실행 (Claude Vision AI 해석 + 결과 저장)
  ///
  /// [userId]: 분석 대상 사용자 ID (profiles.id)
  /// [photoUrls]: 이미 Storage에 업로드된 사진 URL 목록
  /// [sajuData]: 사주팔자 데이터 (오행 시너지 분석용)
  /// [gender]: 성별 ("남성" | "여성")
  /// [age]: 나이
  Future<GwansangProfile> analyzeGwansang({
    required String userId,
    required List<String> photoUrls,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  });

  /// 저장된 관상 프로필 조회
  Future<GwansangProfile?> getGwansangProfile(String userId);
}
