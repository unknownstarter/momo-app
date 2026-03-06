/// 사주 분석 Repository 구현체
///
/// [SajuRepository] 인터페이스의 구현.
/// [SajuRemoteDatasource]를 통해 Edge Function을 호출하고,
/// 결과를 조합하여 도메인 엔티티를 생성합니다.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/saju_entity.dart';
import '../../domain/repositories/saju_repository.dart';
import '../datasources/saju_remote_datasource.dart';

// =============================================================================
// 사주 Repository 구현체
// =============================================================================

/// 오행 → 캐릭터 타입 매핑 (DB 저장용)
const _elementToCharacter = <String, String>{
  'wood': 'namuri',
  'fire': 'bulkkori',
  'earth': 'heuksuni',
  'metal': 'soedongi',
  'water': 'mulgyeori',
};

/// 사주 분석 Repository 구현체
///
/// 두 단계의 Edge Function 호출을 체이닝합니다:
/// 1. `calculate-saju` → 만세력 기반 사주팔자 계산
/// 2. `generate-saju-insight` → AI 기반 해석 생성
///
/// 최종적으로 두 결과를 조합하여 완전한 [SajuProfile] 엔티티를 반환합니다.
class SajuRepositoryImpl implements SajuRepository {
  const SajuRepositoryImpl(this._datasource, this._supabaseHelper);

  final SajuRemoteDatasource _datasource;
  final SupabaseHelper _supabaseHelper;

  @override
  Future<SajuProfile> analyzeSaju({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  }) async {
    debugPrint('[SajuRepo] analyzeSaju 시작: userId=$userId, birthDate=$birthDate, birthTime=$birthTime, userName=$userName');

    // Step 1: 만세력 기반 사주팔자 계산
    debugPrint('[SajuRepo] Step 1: calculateSaju 호출...');
    final sajuModel = await _datasource.calculateSaju(
      birthDate: birthDate,
      birthTime: birthTime,
      isLunar: isLunar,
    );
    debugPrint('[SajuRepo] Step 1 완료: dominantElement=${sajuModel.dominantElement}');

    // Step 2: AI 인사이트 생성
    debugPrint('[SajuRepo] Step 2: generateInsight 호출...');
    final insightModel = await _datasource.generateInsight(
      sajuResult: sajuModel.toJson(),
      userName: userName,
    );
    debugPrint('[SajuRepo] Step 2 완료: traits=${insightModel.personalityTraits.length}개');

    // Step 3: DB에 사주 프로필 저장 (upsert)
    debugPrint('[SajuRepo] Step 3: saveSajuProfile 호출 (userId=$userId)...');
    final savedId = await _datasource.saveSajuProfile(
      userId: userId,
      sajuModel: sajuModel,
      insightModel: insightModel,
    );
    debugPrint('[SajuRepo] Step 3 완료: savedId=$savedId');

    // Step 4: 프로필에 사주 연결
    final element = sajuModel.dominantElement ?? 'wood';
    final character = _elementToCharacter[element] ?? 'namuri';
    debugPrint('[SajuRepo] Step 4: linkSajuProfileToUser 호출...');
    await _datasource.linkSajuProfileToUser(
      userId: userId,
      sajuProfileId: savedId,
      dominantElement: element,
      characterType: character,
    );
    debugPrint('[SajuRepo] Step 4 완료: 전체 사주 분석 성공!');

    // Step 4.5: 배치 궁합 계산 비동기 트리거 (fire-and-forget)
    // 사주 분석 완료 후 다른 유저와의 궁합을 백그라운드로 계산합니다.
    // UI를 블로킹하지 않으며, 실패해도 사주 분석 결과에 영향을 주지 않습니다.
    try {
      _supabaseHelper
          .invokeFunction(
            SupabaseFunctions.batchCalculateCompatibility,
            body: {'userId': userId},
            timeout: const Duration(seconds: 60),
          )
          .then((_) => debugPrint('[SajuRepo] 배치 궁합 계산 완료'))
          .catchError(
            (Object e) =>
                debugPrint('[SajuRepo] 배치 궁합 계산 실패 (무시): $e'),
          );
    } catch (_) {
      // 트리거 자체가 실패해도 무시 — 사주 분석 결과에 영향 없음
    }

    // Step 5: 실제 DB ID로 엔티티 생성
    return sajuModel.toEntity(
      id: savedId,
      userId: userId,
      personalityTraits: insightModel.personalityTraits,
      aiInterpretation: insightModel.interpretation,
    );
  }

  @override
  Future<Map<String, dynamic>?> getSajuForCompatibility(String userId) async {
    final model = await _datasource.getSajuProfileByUserId(userId);
    return model?.toJson();
  }

  @override
  Future<String> saveSajuProfile({
    required String userId,
    required SajuProfile sajuProfile,
  }) async {
    throw UnimplementedError(
      'saveSajuProfile은 analyzeSaju 내부에서 자동으로 호출됩니다.',
    );
  }
}
