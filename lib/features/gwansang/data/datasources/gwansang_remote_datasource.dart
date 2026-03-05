/// 관상 분석 Remote 데이터소스
///
/// Supabase Edge Functions, DB를 통해 관상 분석 데이터를 처리합니다.
/// - Edge Function: Claude Vision AI 관상 해석 생성
/// - DB: gwansang_profiles 테이블 (분석 결과 데이터만 저장)
///
/// 사진 업로드는 ProfileRepository가 담당합니다.
library;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/gwansang_profile_model.dart';

// Supabase 상수
const _gwansangTable = SupabaseTables.gwansangProfiles;
const _profilesTable = SupabaseTables.profiles;

// =============================================================================
// 관상 Remote 데이터소스
// =============================================================================

class GwansangRemoteDatasource {
  const GwansangRemoteDatasource(this._helper);

  final SupabaseHelper _helper;

  /// Claude Vision AI 관상 해석 생성 (Edge Function 호출)
  Future<Map<String, dynamic>> generateReading({
    required String photoUrl,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    final body = <String, dynamic>{
      'photoUrl': photoUrl,
      'sajuData': sajuData,
      'gender': gender,
      'age': age,
    };

    final response = await _helper.invokeFunction(
      SupabaseFunctions.generateGwansangReading,
      body: body,
      timeout: const Duration(seconds: 60),
    );

    if (response == null) {
      throw Exception('관상 분석 결과가 비어있습니다.');
    }

    return Map<String, dynamic>.from(response as Map);
  }

  /// 관상 프로필 DB 저장 (upsert) — 분석 결과 데이터만
  Future<String> saveGwansangProfile(Map<String, dynamic> data) async {
    final row = await _helper.upsert(
      _gwansangTable,
      data,
      onConflict: 'user_id',
    );
    return row['id'] as String;
  }

  /// 관상 분석 결과를 유저 프로필에 연결
  Future<void> linkGwansangToProfile({
    required String userId,
    required String gwansangProfileId,
    required String animalType,
    required List<String> photoUrls,
  }) async {
    await _helper.update(
      _profilesTable,
      userId,
      {
        'gwansang_profile_id': gwansangProfileId,
        'animal_type': animalType,
        'profile_images': photoUrls,
      },
    );
  }

  /// 사용자 ID로 관상 프로필 조회
  Future<GwansangProfileModel?> getByUserId(String userId) async {
    final row = await _helper.getSingleBy(
      _gwansangTable,
      'user_id',
      userId,
    );

    if (row == null) return null;

    return GwansangProfileModel.fromJson(row);
  }
}
