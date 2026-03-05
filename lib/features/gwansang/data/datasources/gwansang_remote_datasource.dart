/// 관상 분석 Remote 데이터소스
///
/// Supabase Storage, Edge Functions, DB를 통해 관상 분석 데이터를 처리합니다.
/// - Storage: 사진 업로드 (profile-images 버킷 — 유저 사진 단일 저장소)
/// - Edge Function: Claude Vision AI 관상 해석 생성
/// - DB: gwansang_profiles 테이블 (분석 결과 데이터만 저장)
library;

import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/gwansang_profile_model.dart';

// Supabase 상수
const _gwansangTable = SupabaseTables.gwansangProfiles;
const _profilesBucket = SupabaseBuckets.profileImages;
const _profilesTable = SupabaseTables.profiles;

// =============================================================================
// 관상 Remote 데이터소스
// =============================================================================

/// Supabase를 통한 관상 분석 데이터소스
///
/// 유저 사진은 `profile-images` 버킷 한 곳에만 저장합니다.
/// 관상 분석 결과만 `gwansang_profiles` 테이블에 저장합니다.
class GwansangRemoteDatasource {
  const GwansangRemoteDatasource(this._helper);

  final SupabaseHelper _helper;

  /// 사진 업로드 -> public URL 목록 반환
  ///
  /// 유저 사진은 모두 `profile-images` 버킷에 저장합니다.
  /// 저장 경로: `{authUid}/profile_{index}_{timestamp}.jpg`
  Future<List<String>> uploadPhotos({
    required String userId,
    required List<String> localPaths,
  }) async {
    final authUid = _helper.currentAuthUid;
    if (authUid == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < localPaths.length; i++) {
      final file = File(localPaths[i]);
      final bytes = await file.readAsBytes();
      final storagePath = '$authUid/profile_${i}_$timestamp.jpg';

      final url = await _helper.uploadFile(
        _profilesBucket,
        storagePath,
        bytes,
        contentType: 'image/jpeg',
      );

      urls.add(url);
    }

    return urls;
  }

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
  ///
  /// profiles 테이블에는 gwansang_profile_id, animal_type만 저장.
  /// 사진 URL은 profiles.profile_images에 통합 관리.
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
