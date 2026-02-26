/// 관상 분석 Remote 데이터소스
///
/// Supabase Storage, Edge Functions, DB를 통해 관상 분석 데이터를 처리합니다.
/// - Storage: 사진 업로드 (gwansang-photos 버킷)
/// - Edge Function: AI 관상 해석 생성
/// - DB: gwansang_profiles 테이블 CRUD
library;

import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/gwansang_profile_model.dart';

// Supabase 상수
const _gwansangTable = SupabaseTables.gwansangProfiles;
const _gwansangBucket = SupabaseBuckets.gwansangPhotos;
const _profilesTable = SupabaseTables.profiles;

// =============================================================================
// 관상 Remote 데이터소스
// =============================================================================

/// Supabase를 통한 관상 분석 데이터소스
///
/// [SupabaseHelper]를 사용하여 Storage, Edge Function, DB 작업을 수행합니다.
/// 순수한 데이터 접근 계층으로, 비즈니스 로직을 포함하지 않습니다.
class GwansangRemoteDatasource {
  const GwansangRemoteDatasource(this._helper);

  final SupabaseHelper _helper;

  /// 사진 업로드 → public URL 목록 반환
  ///
  /// [userId]: 사용자 ID (저장 경로에 사용)
  /// [localPaths]: 로컬 파일 경로 목록
  ///
  /// 저장 경로: `{userId}/gwansang_{index}_{timestamp}.jpg`
  /// 반환: 업로드된 사진들의 public URL 목록
  Future<List<String>> uploadPhotos({
    required String userId,
    required List<String> localPaths,
  }) async {
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < localPaths.length; i++) {
      final file = File(localPaths[i]);
      final bytes = await file.readAsBytes();
      final storagePath = '$userId/gwansang_${i}_$timestamp.jpg';

      final url = await _helper.uploadFile(
        _gwansangBucket,
        storagePath,
        bytes,
        contentType: 'image/jpeg',
      );

      urls.add(url);
    }

    return urls;
  }

  /// AI 관상 해석 생성 (Edge Function 호출)
  ///
  /// [faceMeasurements]: ML Kit에서 추출한 얼굴 측정값 (JSON)
  /// [sajuData]: 사주팔자 데이터 (오행 시너지 분석용)
  /// [gender]: 성별
  /// [age]: 나이
  ///
  /// 반환: AI 해석 결과 (animalType, headline, personalitySummary, ...)
  Future<Map<String, dynamic>> generateReading({
    required Map<String, dynamic> faceMeasurements,
    required Map<String, dynamic> sajuData,
    required String gender,
    required int age,
  }) async {
    final body = <String, dynamic>{
      'faceMeasurements': faceMeasurements,
      'sajuData': sajuData,
      'gender': gender,
      'age': age,
    };

    final response = await _helper.invokeFunction(
      SupabaseFunctions.generateGwansangReading,
      body: body,
    );

    if (response == null) {
      throw Exception('관상 분석 결과가 비어있습니다.');
    }

    return Map<String, dynamic>.from(response as Map);
  }

  /// 관상 프로필 DB 저장 (upsert)
  ///
  /// [data]: 저장할 관상 프로필 데이터 (snake_case JSON)
  ///
  /// 반환: 저장된 레코드의 ID
  Future<String> saveGwansangProfile(Map<String, dynamic> data) async {
    final row = await _helper.upsert(
      _gwansangTable,
      data,
      onConflict: 'user_id',
    );
    return row['id'] as String;
  }

  /// 관상 분석 결과를 유저 프로필에 연결
  ///
  /// profiles 테이블의 gwansang 관련 필드를 업데이트합니다.
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
        'gwansang_photo_urls': photoUrls,
      },
    );
  }

  /// 사용자 ID로 관상 프로필 조회
  ///
  /// [userId]: 조회할 사용자 ID
  ///
  /// 반환: 저장된 [GwansangProfileModel], 없으면 null
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
