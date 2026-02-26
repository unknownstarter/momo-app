/// 관상(觀相) 분석 결과 도메인 엔티티
///
/// 관상 분석의 최종 결과물로, 동물상, 얼굴 측정값, AI 해석 결과를 포함한다.
/// 순수 Dart 클래스로 외부 의존성이 없다.
library;

import 'animal_type.dart';
import 'face_measurements.dart';

/// 관상 분석 결과 엔티티
///
/// 사진에서 추출된 얼굴 측정값과 AI가 해석한 동물상, 성격, 연애 스타일,
/// 사주 시너지 등을 종합적으로 담는 도메인 엔티티.
class GwansangProfile {
  const GwansangProfile({
    required this.id,
    required this.userId,
    required this.animalType,
    required this.measurements,
    required this.photoUrls,
    required this.headline,
    required this.personalitySummary,
    required this.romanceSummary,
    required this.sajuSynergy,
    required this.charmKeywords,
    this.elementModifier,
    this.detailedReading,
    required this.createdAt,
  });

  /// 관상 프로필 고유 ID
  final String id;

  /// 소유 사용자 ID
  final String userId;

  /// 분석된 동물상 타입
  final AnimalType animalType;

  /// 얼굴 측정값 (ML Kit 추출)
  final FaceMeasurements measurements;

  /// 분석에 사용된 사진 URL 목록
  final List<String> photoUrls;

  /// 한줄 헤드라인 (예: "도도한 고양이상의 신비로운 매력")
  final String headline;

  /// 성격 요약 (AI 해석)
  final String personalitySummary;

  /// 연애 스타일 요약 (AI 해석)
  final String romanceSummary;

  /// 사주 × 관상 시너지 해석
  final String sajuSynergy;

  /// 매력 키워드 (예: ["밀당의 달인", "신비로운 눈빛", "도도한 매력"])
  final List<String> charmKeywords;

  /// 오행 보정자 — 사주 오행과 결합한 수식어 (예: "물의", "불꽃")
  final String? elementModifier;

  /// 상세 관상 해석 (프리미엄 전용)
  final String? detailedReading;

  /// 분석 생성 시각
  final DateTime createdAt;

  // ===========================================================================
  // 계산 프로퍼티
  // ===========================================================================

  /// 오행 x 동물상 유니크 레이블 (예: "물의 도도한 고양이상")
  String get uniqueLabel {
    if (elementModifier != null) {
      return '$elementModifier ${animalType.label}';
    }
    return animalType.label;
  }

  GwansangProfile copyWith({
    String? id,
    String? userId,
    AnimalType? animalType,
    FaceMeasurements? measurements,
    List<String>? photoUrls,
    String? headline,
    String? personalitySummary,
    String? romanceSummary,
    String? sajuSynergy,
    List<String>? charmKeywords,
    String? elementModifier,
    String? detailedReading,
    DateTime? createdAt,
  }) {
    return GwansangProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      animalType: animalType ?? this.animalType,
      measurements: measurements ?? this.measurements,
      photoUrls: photoUrls ?? this.photoUrls,
      headline: headline ?? this.headline,
      personalitySummary: personalitySummary ?? this.personalitySummary,
      romanceSummary: romanceSummary ?? this.romanceSummary,
      sajuSynergy: sajuSynergy ?? this.sajuSynergy,
      charmKeywords: charmKeywords ?? this.charmKeywords,
      elementModifier: elementModifier ?? this.elementModifier,
      detailedReading: detailedReading ?? this.detailedReading,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GwansangProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GwansangProfile(id: $id, animal: ${animalType.korean})';
}
