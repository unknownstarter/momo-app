/// 사주 분석 결과 DTO (Data Transfer Object)
///
/// Supabase Edge Function의 JSON 응답을 파싱하여
/// 도메인 엔티티([SajuProfile])로 변환하는 역할을 합니다.
library;

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/saju_entity.dart';

// =============================================================================
// 사주 계산 결과 모델
// =============================================================================

/// Edge Function `calculate-saju` 응답 모델
///
/// 만세력 기반 사주팔자 계산 결과를 담습니다.
/// [fromJson]으로 JSON 파싱, [toEntity]로 도메인 엔티티 변환.
class SajuProfileModel {
  const SajuProfileModel({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.fiveElements,
    this.dominantElement,
    required this.birthDate,
    this.birthTime,
    this.isLunar = false,
  });

  /// 연주(年柱) — 천간 + 지지
  final PillarModel yearPillar;

  /// 월주(月柱) — 천간 + 지지
  final PillarModel monthPillar;

  /// 일주(日柱) — 천간 + 지지
  final PillarModel dayPillar;

  /// 시주(時柱) — 생시를 모르면 null
  final PillarModel? hourPillar;

  /// 오행 분포
  final FiveElementsModel fiveElements;

  /// 주도적 오행
  final String? dominantElement;

  /// 생년월일 (ISO 8601 date string)
  final String birthDate;

  /// 생시 (HH:mm 형식, nullable)
  final String? birthTime;

  /// 음력 여부
  final bool isLunar;

  /// JSON 파싱
  ///
  /// Edge Function이 반환하는 JSON 구조:
  /// ```json
  /// {
  ///   "yearPillar": {"stem": "갑", "branch": "자"},
  ///   "monthPillar": {"stem": "을", "branch": "축"},
  ///   "dayPillar": {"stem": "병", "branch": "인"},
  ///   "hourPillar": {"stem": "정", "branch": "묘"},  // nullable
  ///   "fiveElements": {"wood": 2, "fire": 1, "earth": 2, "metal": 1, "water": 2},
  ///   "dominantElement": "wood",
  ///   "birthDate": "1995-03-15",
  ///   "birthTime": "14:30",
  ///   "isLunar": false
  /// }
  /// ```
  factory SajuProfileModel.fromJson(Map<String, dynamic> json) {
    return SajuProfileModel(
      yearPillar: PillarModel.fromJson(
        json['yearPillar'] as Map<String, dynamic>,
      ),
      monthPillar: PillarModel.fromJson(
        json['monthPillar'] as Map<String, dynamic>,
      ),
      dayPillar: PillarModel.fromJson(
        json['dayPillar'] as Map<String, dynamic>,
      ),
      hourPillar: json['hourPillar'] != null
          ? PillarModel.fromJson(json['hourPillar'] as Map<String, dynamic>)
          : null,
      fiveElements: FiveElementsModel.fromJson(
        json['fiveElements'] as Map<String, dynamic>,
      ),
      dominantElement: json['dominantElement'] as String?,
      birthDate: json['birthDate'] as String,
      birthTime: json['birthTime'] as String?,
      isLunar: json['isLunar'] as bool? ?? false,
    );
  }

  /// JSON 직렬화 (AI 인사이트 요청 시 사용)
  Map<String, dynamic> toJson() {
    return {
      'yearPillar': yearPillar.toJson(),
      'monthPillar': monthPillar.toJson(),
      'dayPillar': dayPillar.toJson(),
      if (hourPillar != null) 'hourPillar': hourPillar!.toJson(),
      'fiveElements': fiveElements.toJson(),
      if (dominantElement != null) 'dominantElement': dominantElement,
      'birthDate': birthDate,
      if (birthTime != null) 'birthTime': birthTime,
      'isLunar': isLunar,
    };
  }

  /// 도메인 엔티티([SajuProfile])로 변환
  ///
  /// [id], [userId]는 외부에서 주입합니다.
  /// [personalityTraits], [aiInterpretation]은 AI 인사이트 결과와 합칠 때 사용합니다.
  SajuProfile toEntity({
    required String id,
    required String userId,
    List<String> personalityTraits = const [],
    String? aiInterpretation,
  }) {
    return SajuProfile(
      id: id,
      userId: userId,
      yearPillar: yearPillar.toEntity(),
      monthPillar: monthPillar.toEntity(),
      dayPillar: dayPillar.toEntity(),
      hourPillar: hourPillar?.toEntity(),
      fiveElements: fiveElements.toEntity(),
      dominantElement: _parseFiveElementType(dominantElement),
      personalityTraits: personalityTraits,
      aiInterpretation: aiInterpretation,
      isLunarCalendar: isLunar,
      birthDateTime: _parseBirthDateTime(),
      calculatedAt: DateTime.now(),
    );
  }

  /// 생년월일시 파싱 (birthDate + birthTime → DateTime)
  DateTime _parseBirthDateTime() {
    final date = DateTime.tryParse(birthDate) ?? DateTime.now();
    if (birthTime == null || birthTime!.isEmpty) {
      return date;
    }

    final timeParts = birthTime!.split(':');
    if (timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return date;
  }

  /// 문자열 → FiveElementType 변환
  static FiveElementType? _parseFiveElementType(String? value) {
    if (value == null) return null;
    return FiveElementType.values.where((e) => e.name == value).firstOrNull;
  }
}

// =============================================================================
// 기둥(柱) 모델
// =============================================================================

/// 기둥(柱) DTO
///
/// Edge Function 응답의 개별 기둥 데이터를 파싱합니다.
class PillarModel {
  const PillarModel({
    required this.stem,
    required this.branch,
  });

  /// 천간(天干): 갑~계
  final String stem;

  /// 지지(地支): 자~해
  final String branch;

  factory PillarModel.fromJson(Map<String, dynamic> json) {
    return PillarModel(
      stem: json['stem'] as String,
      branch: json['branch'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'stem': stem,
        'branch': branch,
      };

  /// 도메인 엔티티([Pillar])로 변환
  Pillar toEntity() {
    return Pillar(
      heavenlyStem: stem,
      earthlyBranch: branch,
    );
  }
}

// =============================================================================
// 오행 분포 모델
// =============================================================================

/// 오행 분포 DTO
class FiveElementsModel {
  const FiveElementsModel({
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
  });

  final int wood;
  final int fire;
  final int earth;
  final int metal;
  final int water;

  factory FiveElementsModel.fromJson(Map<String, dynamic> json) {
    return FiveElementsModel(
      wood: json['wood'] as int? ?? 0,
      fire: json['fire'] as int? ?? 0,
      earth: json['earth'] as int? ?? 0,
      metal: json['metal'] as int? ?? 0,
      water: json['water'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'wood': wood,
        'fire': fire,
        'earth': earth,
        'metal': metal,
        'water': water,
      };

  /// 도메인 엔티티([FiveElements])로 변환
  FiveElements toEntity() {
    return FiveElements(
      wood: wood,
      fire: fire,
      earth: earth,
      metal: metal,
      water: water,
    );
  }
}

// =============================================================================
// AI 인사이트 모델
// =============================================================================

/// Edge Function `generate-saju-insight` 응답 모델
///
/// Claude API를 통해 생성된 사주 해석 결과를 담습니다.
///
/// JSON 구조:
/// ```json
/// {
///   "personalityTraits": ["직관적", "감성적", "리더십"],
///   "interpretation": "당신의 사주는...",
///   "characterName": "나무리",
///   "characterElement": "wood",
///   "characterGreeting": "안녕! 나는 나무리야..."
/// }
/// ```
class SajuInsightModel {
  const SajuInsightModel({
    required this.personalityTraits,
    required this.interpretation,
    this.characterName,
    this.characterElement,
    this.characterGreeting,
  });

  /// AI가 분석한 성격 특성 키워드 (예: ["직관적", "감성적", "리더십"])
  final List<String> personalityTraits;

  /// AI 해석 전문
  final String interpretation;

  /// 배정된 오행이 캐릭터 이름 (예: "나무리")
  final String? characterName;

  /// 캐릭터의 오행 속성 (예: "wood")
  final String? characterElement;

  /// 캐릭터 인사말 (온보딩/결과 화면에서 표시)
  final String? characterGreeting;

  factory SajuInsightModel.fromJson(Map<String, dynamic> json) {
    return SajuInsightModel(
      personalityTraits: (json['personalityTraits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      interpretation: json['interpretation'] as String? ?? '',
      characterName: json['characterName'] as String?,
      characterElement: json['characterElement'] as String?,
      characterGreeting: json['characterGreeting'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'personalityTraits': personalityTraits,
        'interpretation': interpretation,
        if (characterName != null) 'characterName': characterName,
        if (characterElement != null) 'characterElement': characterElement,
        if (characterGreeting != null) 'characterGreeting': characterGreeting,
      };
}
