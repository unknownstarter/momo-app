/// 사주 분석 Remote 데이터소스
///
/// Supabase Edge Functions를 호출하여 사주 계산 및 AI 인사이트를 생성합니다.
/// - `calculate-saju`: 만세력 기반 사주팔자 계산
/// - `generate-saju-insight`: Claude AI 기반 사주 해석
library;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/saju_profile_model.dart';

// Supabase 테이블명
const _sajuProfilesTable = SupabaseTables.sajuProfiles;

// =============================================================================
// 사주 Remote 데이터소스
// =============================================================================

/// Supabase Edge Function을 통한 사주 분석 데이터소스
///
/// [SupabaseHelper.invokeFunction]을 사용하여 서버사이드 함수를 호출합니다.
/// 이 클래스는 순수한 데이터 접근 계층으로, 비즈니스 로직을 포함하지 않습니다.
class SajuRemoteDatasource {
  const SajuRemoteDatasource(this._helper);

  final SupabaseHelper _helper;

  /// 사주팔자 계산
  ///
  /// 생년월일시를 기반으로 만세력 데이터를 조회하고
  /// 사주팔자(연주/월주/일주/시주)와 오행 분포를 계산합니다.
  ///
  /// [birthDate]: ISO 8601 날짜 문자열 (예: "1995-03-15")
  /// [birthTime]: 시:분 문자열 (예: "14:30"), 모르면 null
  /// [isLunar]: 음력 날짜 여부
  ///
  /// 반환: [SajuProfileModel] — 계산된 사주 데이터
  ///
  /// 예외:
  /// - [Exception]: Edge Function 호출 실패 또는 응답 파싱 에러
  Future<SajuProfileModel> calculateSaju({
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
  }) async {
    final body = <String, dynamic>{
      'birthDate': birthDate,
      'isLunar': isLunar,
    };

    if (birthTime != null && birthTime.isNotEmpty) {
      body['birthTime'] = birthTime;
    }

    final response = await _helper.invokeFunction(
      SupabaseFunctions.calculateSaju,
      body: body,
    );

    if (response == null) {
      throw Exception('사주 계산 결과가 비어있습니다.');
    }

    return SajuProfileModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// 사주 프로필 조회 (by user_id) — 궁합 계산용
  ///
  /// [userId]: profiles.id (또는 auth user id와 매핑되는 프로필 id)
  /// 반환: 저장된 사주가 있으면 [SajuProfileModel], 없으면 null.
  /// RLS: 본인 또는 daily_matches 추천 대상의 사주만 조회 가능.
  Future<SajuProfileModel?> getSajuProfileByUserId(String userId) async {
    final row = await _helper.getSingleBy(
      _sajuProfilesTable,
      'user_id',
      userId,
    );
    if (row == null) return null;

    final yearPillar = row['year_pillar'];
    final monthPillar = row['month_pillar'];
    final dayPillar = row['day_pillar'];
    final hourPillar = row['hour_pillar'];
    final fiveElements = row['five_elements'];
    final dominantElement = row['dominant_element'];
    if (yearPillar == null || monthPillar == null || dayPillar == null ||
        fiveElements == null || dominantElement == null) {
      return null;
    }

    return SajuProfileModel.fromJson({
      'yearPillar': yearPillar,
      'monthPillar': monthPillar,
      'dayPillar': dayPillar,
      'hourPillar': hourPillar,
      'fiveElements': fiveElements,
      'dominantElement': dominantElement,
      'birthDate': '2000-01-01',
      'birthTime': null,
      'isLunar': row['is_lunar_calendar'] == true,
    });
  }

  /// AI 사주 인사이트 생성
  ///
  /// 계산된 사주 데이터를 Claude API에 전달하여
  /// 성격 분석, 해석 텍스트, 오행이 캐릭터 배정 결과를 생성합니다.
  ///
  /// [sajuResult]: [SajuProfileModel.toJson]의 결과 (사주 계산 데이터)
  /// [userName]: 사용자 이름 (개인화된 해석에 사용, optional)
  ///
  /// 반환: [SajuInsightModel] — AI 해석 결과
  Future<SajuInsightModel> generateInsight({
    required Map<String, dynamic> sajuResult,
    String? userName,
  }) async {
    final body = <String, dynamic>{
      'sajuData': sajuResult,
    };

    if (userName != null && userName.isNotEmpty) {
      body['userName'] = userName;
    }

    final response = await _helper.invokeFunction(
      SupabaseFunctions.generateSajuInsight,
      body: body,
    );

    if (response == null) {
      throw Exception('AI 인사이트 생성 결과가 비어있습니다.');
    }

    return SajuInsightModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// 사주 분석 결과를 DB에 저장 (upsert)
  Future<String> saveSajuProfile({
    required String userId,
    required SajuProfileModel sajuModel,
    required SajuInsightModel insightModel,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'year_pillar': sajuModel.yearPillar.toJson(),
      'month_pillar': sajuModel.monthPillar.toJson(),
      'day_pillar': sajuModel.dayPillar.toJson(),
      'hour_pillar': sajuModel.hourPillar?.toJson(),
      'five_elements': sajuModel.fiveElements.toJson(),
      'dominant_element': sajuModel.dominantElement ?? 'wood',
      'personality_traits': insightModel.personalityTraits,
      'ai_interpretation': insightModel.interpretation,
      'is_lunar_calendar': sajuModel.isLunar,
      'calculated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final row = await _helper.upsert(_sajuProfilesTable, data);
    return row['id'] as String;
  }

  /// 사주 프로필을 유저 프로필에 연결
  Future<void> linkSajuProfileToUser({
    required String userId,
    required String sajuProfileId,
    required String dominantElement,
    required String characterType,
  }) async {
    await _helper.update(
      SupabaseTables.profiles,
      userId,
      {
        'saju_profile_id': sajuProfileId,
        'dominant_element': dominantElement,
        'character_type': characterType,
      },
    );
  }
}
