/// 관상 분석 Repository 구현체
///
/// [GwansangRepository] 인터페이스의 구현.
/// 사진은 이미 profiles.profile_images에 업로드된 URL을 사용합니다.
/// 업로드 없이 Claude Vision AI 해석 + 결과 저장만 수행합니다.
library;

import '../../domain/entities/gwansang_entity.dart';
import '../../domain/repositories/gwansang_repository.dart';
import '../datasources/gwansang_remote_datasource.dart';
import '../models/gwansang_profile_model.dart';

// =============================================================================
// 관상 Repository 구현체
// =============================================================================

class GwansangRepositoryImpl implements GwansangRepository {
  const GwansangRepositoryImpl(this._datasource);

  final GwansangRemoteDatasource _datasource;

  @override
  Future<GwansangProfile> analyzeGwansang({
    required String userId,
    required List<String> photoUrls,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    // Step 1: Claude Vision AI 관상 해석 (이미 업로드된 URL 사용)
    final reading = await _datasource.generateReading(
      photoUrl: photoUrls.first,
      sajuData: sajuData,
      gender: gender,
      age: age,
    );

    // Step 2: DB에 관상 프로필 저장 (upsert)
    final animalType = reading['animal_type'] as String? ?? 'cat';
    final animalModifier = reading['animal_modifier'] as String? ?? '';
    final animalTypeKorean = reading['animal_type_korean'] as String? ?? '';
    final dbData = <String, dynamic>{
      'user_id': userId,
      'animal_type': animalType,
      'animal_modifier': animalModifier,
      'animal_type_korean': animalTypeKorean,
      'photo_urls': photoUrls,
      'headline': reading['headline'] ?? '',
      'samjeong': reading['samjeong'] ?? <String, dynamic>{},
      'ogwan': reading['ogwan'] ?? <String, dynamic>{},
      'traits': reading['traits'] ?? <String, dynamic>{},
      'personality_summary': reading['personality_summary'] ?? '',
      'romance_summary': reading['romance_summary'] ?? '',
      'romance_key_points': reading['romance_key_points'] ?? <String>[],
      'charm_keywords': reading['charm_keywords'] ?? <String>[],
      'detailed_reading': reading['detailed_reading'],
    };

    final savedId = await _datasource.saveGwansangProfile(dbData);

    // Step 3: 유저 프로필에 관상 연결 (gwansang_profile_id, animal_type만)
    await _datasource.linkGwansangToProfile(
      userId: userId,
      gwansangProfileId: savedId,
      animalType: animalType,
      photoUrls: photoUrls,
    );

    // Step 4: 저장된 ID로 Model 생성 후 Entity 변환
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
