/// 사주 분석 Repository 구현체
///
/// [SajuRepository] 인터페이스의 구현.
/// [SajuRemoteDatasource]를 통해 Edge Function을 호출하고,
/// 결과를 조합하여 도메인 엔티티를 생성합니다.
library;

import '../../domain/entities/saju_entity.dart';
import '../../domain/repositories/saju_repository.dart';
import '../datasources/saju_remote_datasource.dart';

// =============================================================================
// 사주 Repository 구현체
// =============================================================================

/// 사주 분석 Repository 구현체
///
/// 두 단계의 Edge Function 호출을 체이닝합니다:
/// 1. `calculate-saju` → 만세력 기반 사주팔자 계산
/// 2. `generate-saju-insight` → AI 기반 해석 생성
///
/// 최종적으로 두 결과를 조합하여 완전한 [SajuProfile] 엔티티를 반환합니다.
class SajuRepositoryImpl implements SajuRepository {
  const SajuRepositoryImpl(this._datasource);

  final SajuRemoteDatasource _datasource;

  @override
  Future<SajuProfile> analyzeSaju({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  }) async {
    // Step 1: 만세력 기반 사주팔자 계산
    final sajuModel = await _datasource.calculateSaju(
      birthDate: birthDate,
      birthTime: birthTime,
      isLunar: isLunar,
    );

    // Step 2: AI 인사이트 생성 (사주 계산 결과를 입력으로)
    final insightModel = await _datasource.generateInsight(
      sajuResult: sajuModel.toJson(),
      userName: userName,
    );

    // Step 3: 두 결과를 조합하여 SajuProfile 엔티티 생성
    //
    // ID는 "userId_타임스탬프" 형식으로 생성합니다.
    // 향후 Supabase에서 UUID를 반환하도록 변경할 수 있습니다.
    final profileId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

    return sajuModel.toEntity(
      id: profileId,
      userId: userId,
      personalityTraits: insightModel.personalityTraits,
      aiInterpretation: insightModel.interpretation,
    );
  }
}
