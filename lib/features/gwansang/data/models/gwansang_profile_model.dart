/// 관상 프로필 DTO (Data Transfer Object)
///
/// Supabase `gwansang_profiles` 테이블과 1:1 매핑되는 데이터 모델.
/// snake_case JSON 키를 사용하며, 도메인 엔티티로의 변환 메서드를 제공합니다.
library;

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
    required this.animalModifier,
    required this.animalTypeKorean,
    required this.measurements,
    required this.photoUrls,
    required this.headline,
    required this.samjeong,
    required this.ogwan,
    required this.traits,
    required this.personalitySummary,
    required this.romanceSummary,
    required this.romanceKeyPoints,
    required this.charmKeywords,
    this.detailedReading,
    required this.createdAt,
  });

  /// 관상 프로필 고유 ID
  final String id;

  /// 소유 사용자 ID
  final String userId;

  /// 분석된 동물상 타입 영어 키 (예: "cat", "dinosaur")
  final String animalType;

  /// 관상 특징에서 도출된 수식어 (예: "나른한", "배고픈")
  final String animalModifier;

  /// 동물 한글명 (예: "고양이", "공룡")
  final String animalTypeKorean;

  /// 얼굴 측정값 (JSON Map)
  final Map<String, dynamic> measurements;

  /// 분석에 사용된 사진 URL 목록
  final List<String> photoUrls;

  /// 한줄 헤드라인
  final String headline;

  /// 삼정(三停) 해석 (JSON Map: upper/middle/lower)
  final Map<String, dynamic> samjeong;

  /// 오관(五官) 해석 (JSON Map: eyes/nose/mouth/ears/eyebrows)
  final Map<String, dynamic> ogwan;

  /// 성격 traits 5축 (JSON Map: leadership/warmth/independence/sensitivity/energy)
  final Map<String, dynamic> traits;

  /// 성격 요약 (AI 해석)
  final String personalitySummary;

  /// 연애 스타일 요약 (AI 해석)
  final String romanceSummary;

  /// 연애/궁합 핵심 포인트 (3~5개)
  final List<String> romanceKeyPoints;

  /// 매력 키워드 목록
  final List<String> charmKeywords;

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
      animalModifier: json['animal_modifier'] as String? ?? '',
      animalTypeKorean: json['animal_type_korean'] as String? ?? '',
      measurements: json['face_measurements'] != null
          ? Map<String, dynamic>.from(json['face_measurements'] as Map)
          : <String, dynamic>{},
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List)
          : <String>[],
      headline: json['headline'] as String? ?? '',
      samjeong: json['samjeong'] != null
          ? Map<String, dynamic>.from(json['samjeong'] as Map)
          : <String, dynamic>{},
      ogwan: json['ogwan'] != null
          ? Map<String, dynamic>.from(json['ogwan'] as Map)
          : <String, dynamic>{},
      traits: json['traits'] != null
          ? Map<String, dynamic>.from(json['traits'] as Map)
          : <String, dynamic>{},
      personalitySummary: json['personality_summary'] as String? ?? '',
      romanceSummary: json['romance_summary'] as String? ?? '',
      romanceKeyPoints: json['romance_key_points'] != null
          ? List<String>.from(json['romance_key_points'] as List)
          : <String>[],
      charmKeywords: json['charm_keywords'] != null
          ? List<String>.from(json['charm_keywords'] as List)
          : <String>[],
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
        'animal_modifier': animalModifier,
        'animal_type_korean': animalTypeKorean,
        'face_measurements': measurements,
        'photo_urls': photoUrls,
        'headline': headline,
        'samjeong': samjeong,
        'ogwan': ogwan,
        'traits': traits,
        'personality_summary': personalitySummary,
        'romance_summary': romanceSummary,
        'romance_key_points': romanceKeyPoints,
        'charm_keywords': charmKeywords,
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
      animalType: animalType,
      animalModifier: animalModifier,
      animalTypeKorean: animalTypeKorean,
      photoUrls: photoUrls,
      headline: headline,
      samjeong: SamjeongReading.fromJson(samjeong),
      ogwan: OgwanReading.fromJson(ogwan),
      traits: GwansangTraits.fromJson(traits),
      personalitySummary: personalitySummary,
      romanceSummary: romanceSummary,
      romanceKeyPoints: romanceKeyPoints,
      charmKeywords: charmKeywords,
      detailedReading: detailedReading,
      createdAt: createdAt,
    );
  }
}
