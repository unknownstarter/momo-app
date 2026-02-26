/// 관상 분석 Repository 구현체
///
/// [GwansangRepository] 인터페이스의 구현.
/// [GwansangRemoteDatasource]를 통해 사진 업로드, AI 해석, DB 저장을 수행하고
/// 결과를 도메인 엔티티로 변환합니다.
library;

import '../../domain/entities/face_measurements.dart';
import '../../domain/entities/gwansang_entity.dart';
import '../../domain/repositories/gwansang_repository.dart';
import '../datasources/gwansang_remote_datasource.dart';
import '../models/gwansang_profile_model.dart';

// =============================================================================
// 관상 Repository 구현체
// =============================================================================

/// 관상 분석 Repository 구현체
///
/// 관상 분석의 전체 파이프라인을 오케스트레이션합니다:
/// 1. 사진 업로드 (Storage)
/// 2. AI 관상 해석 생성 (Edge Function)
/// 3. DB 저장 (upsert)
/// 4. 유저 프로필 연결 (profiles 테이블)
/// 5. 도메인 엔티티 반환
class GwansangRepositoryImpl implements GwansangRepository {
  const GwansangRepositoryImpl(this._datasource);

  final GwansangRemoteDatasource _datasource;

  @override
  Future<GwansangProfile> analyzeGwansang({
    required String userId,
    required List<String> photoLocalPaths,
    required FaceMeasurements measurements,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    // Step 1: 사진 업로드 → public URL 획득
    final photoUrls = await _datasource.uploadPhotos(
      userId: userId,
      localPaths: photoLocalPaths,
    );

    // Step 2: AI 관상 해석 생성 (Edge Function)
    final reading = await _datasource.generateReading(
      faceMeasurements: measurements.toJson(),
      sajuData: sajuData,
      gender: gender,
      age: age,
    );

    // Step 3: DB에 관상 프로필 저장 (upsert)
    final animalType = reading['animal_type'] as String? ?? 'cat';
    final dbData = <String, dynamic>{
      'user_id': userId,
      'animal_type': animalType,
      'face_measurements': measurements.toJson(),
      'photo_urls': photoUrls,
      'headline': reading['headline'] ?? '',
      'personality_summary': reading['personality_summary'] ?? '',
      'romance_summary': reading['romance_summary'] ?? '',
      'saju_synergy': reading['saju_synergy'] ?? '',
      'charm_keywords': reading['charm_keywords'] ?? <String>[],
      'element_modifier': reading['element_modifier'],
      'detailed_reading': reading['detailed_reading'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final savedId = await _datasource.saveGwansangProfile(dbData);

    // Step 4: 유저 프로필에 관상 연결
    await _datasource.linkGwansangToProfile(
      userId: userId,
      gwansangProfileId: savedId,
      animalType: animalType,
      photoUrls: photoUrls,
    );

    // Step 5: 저장된 ID로 Model 생성 후 Entity 변환
    final model = GwansangProfileModel.fromJson({
      ...dbData,
      'id': savedId,
    });

    return model.toEntity();
  }

  @override
  Future<GwansangProfile?> getGwansangProfile(String userId) async {
    final model = await _datasource.getByUserId(userId);
    return model?.toEntity();
  }
}
