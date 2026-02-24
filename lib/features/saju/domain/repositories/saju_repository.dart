/// 사주 분석 Repository 인터페이스
///
/// 도메인 레이어에 위치하며, 데이터 레이어에 의존하지 않습니다.
/// 구현체는 `data/repositories/saju_repository_impl.dart`에 있습니다.
library;

import '../entities/saju_entity.dart';

// =============================================================================
// 사주 Repository 인터페이스
// =============================================================================

/// 사주 분석 Repository 추상 인터페이스
///
/// 사주 계산 + AI 인사이트 생성을 하나의 분석 플로우로 묶어
/// 완전한 [SajuProfile]을 반환합니다.
///
/// 의존성 규칙:
/// - 이 인터페이스는 **순수 도메인 레이어**에 위치합니다.
/// - data 레이어의 어떤 클래스도 import하지 않습니다.
/// - presentation 레이어는 이 인터페이스에만 의존합니다.
abstract class SajuRepository {
  /// 사주 종합 분석
  ///
  /// 생년월일시를 받아 사주팔자를 계산하고, AI 인사이트를 생성하여
  /// 완전한 [SajuProfile]을 반환합니다.
  ///
  /// 내부 흐름:
  /// 1. 만세력 기반 사주팔자 계산 (연주/월주/일주/시주 + 오행 분포)
  /// 2. AI 인사이트 생성 (성격 분석, 해석 텍스트, 캐릭터 배정)
  /// 3. 결과 조합 → [SajuProfile] 엔티티 생성
  ///
  /// [userId]: 분석 대상 사용자 ID
  /// [birthDate]: ISO 8601 날짜 문자열 (예: "1995-03-15")
  /// [birthTime]: 시:분 문자열 (예: "14:30"), 모르면 null
  /// [isLunar]: 음력 날짜 여부
  /// [userName]: 사용자 이름 (AI 개인화 해석에 사용)
  ///
  /// 반환: 완전한 [SajuProfile] 엔티티
  ///
  /// 예외:
  /// - [Exception]: 사주 계산 실패, AI 인사이트 생성 실패
  Future<SajuProfile> analyzeSaju({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  });
}
