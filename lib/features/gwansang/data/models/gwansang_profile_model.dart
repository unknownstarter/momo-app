/// 관상 프로필 DTO (Data Transfer Object)
///
/// Supabase `gwansang_profiles` 테이블과 1:1 매핑되는 데이터 모델.
/// snake_case JSON 키를 사용하며, 도메인 엔티티로의 변환 메서드를 제공합니다.
library;

import '../../domain/entities/animal_type.dart';
import '../../domain/entities/face_measurements.dart';
import '../../domain/entities/gwansang_entity.dart';

/// 관상 프로필 DTO
///
/// Supabase DB <-> Dart 객체 변환을 담당합니다.
/// JSON 키는 Supabase convention에 따라 snake_case를 사용합니다.
class GwansangProfileModel {
  const GwansangProfileModel({
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

  /// 분석된 동물상 타입 (문자열)
  final String animalType;

  /// 얼굴 측정값 (JSON Map)
  final Map<String, dynamic> measurements;

  /// 분석에 사용된 사진 URL 목록
  final List<String> photoUrls;

  /// 한줄 헤드라인
  final String headline;

  /// 성격 요약 (AI 해석)
  final String personalitySummary;

  /// 연애 스타일 요약 (AI 해석)
  final String romanceSummary;

  /// 사주 x 관상 시너지 해석
  final String sajuSynergy;

  /// 매력 키워드 목록
  final List<String> charmKeywords;

  /// 오행 보정자
  final String? elementModifier;

  /// 상세 관상 해석 (프리미엄 전용)
  final String? detailedReading;

  /// 분석 생성 시각
  final DateTime createdAt;

  // ===========================================================================
  // JSON 직렬화/역직렬화
  // ===========================================================================

  /// JSON (snake_case) -> GwansangProfileModel
  factory GwansangProfileModel.fromJson(Map<String, dynamic> json) {
    return GwansangProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      animalType: json['animal_type'] as String? ?? 'cat',
      measurements: json['face_measurements'] != null
          ? Map<String, dynamic>.from(json['face_measurements'] as Map)
          : <String, dynamic>{},
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List)
          : <String>[],
      headline: json['headline'] as String? ?? '',
      personalitySummary: json['personality_summary'] as String? ?? '',
      romanceSummary: json['romance_summary'] as String? ?? '',
      sajuSynergy: json['saju_synergy'] as String? ?? '',
      charmKeywords: json['charm_keywords'] != null
          ? List<String>.from(json['charm_keywords'] as List)
          : <String>[],
      elementModifier: json['element_modifier'] as String?,
      detailedReading: json['detailed_reading'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// GwansangProfileModel -> JSON (snake_case)
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'animal_type': animalType,
        'face_measurements': measurements,
        'photo_urls': photoUrls,
        'headline': headline,
        'personality_summary': personalitySummary,
        'romance_summary': romanceSummary,
        'saju_synergy': sajuSynergy,
        'charm_keywords': charmKeywords,
        'element_modifier': elementModifier,
        'detailed_reading': detailedReading,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  // ===========================================================================
  // 엔티티 변환
  // ===========================================================================

  /// DTO -> Domain Entity 변환
  GwansangProfile toEntity() {
    return GwansangProfile(
      id: id,
      userId: userId,
      animalType: AnimalType.fromString(animalType),
      measurements: FaceMeasurements.fromJson(measurements),
      photoUrls: photoUrls,
      headline: headline,
      personalitySummary: personalitySummary,
      romanceSummary: romanceSummary,
      sajuSynergy: sajuSynergy,
      charmKeywords: charmKeywords,
      elementModifier: elementModifier,
      detailedReading: detailedReading,
      createdAt: createdAt,
    );
  }
}
