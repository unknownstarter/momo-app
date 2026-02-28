/// 관상(觀相) 분석 결과 도메인 엔티티
///
/// 삼정(三停)/오관(五官) 기반 관상학적 해석 + 닮은 동물 + 성격 traits 5축.
/// 순수 Dart 클래스로 외부 의존성이 없다.
library;

import 'face_measurements.dart';

/// 관상 traits 5축 (관상학 기반)
///
/// 삼정(三停)/오관(五官)에서 자연스럽게 도출되는 성격 특성 축.
/// 각 축은 0~100 범위. 궁합 계산에 사용된다.
///
/// - leadership: 리더십 (눈썹·턱 → 결단력, 추진력)
/// - warmth: 온화함 (눈·입 → 감성 표현, 정이 깊음)
/// - independence: 독립성 (코·이마 → 자존심, 원칙)
/// - sensitivity: 감성 (눈매·입술 → 감수성, 섬세함)
/// - energy: 에너지 (얼굴형·턱 → 활력, 열정)
class GwansangTraits {
  const GwansangTraits({
    required this.leadership,
    required this.warmth,
    required this.independence,
    required this.sensitivity,
    required this.energy,
  });

  final int leadership;
  final int warmth;
  final int independence;
  final int sensitivity;
  final int energy;

  factory GwansangTraits.fromJson(Map<String, dynamic> json) {
    return GwansangTraits(
      leadership: (json['leadership'] as num?)?.toInt() ?? 50,
      warmth: (json['warmth'] as num?)?.toInt() ?? 50,
      independence: (json['independence'] as num?)?.toInt() ?? 50,
      sensitivity: (json['sensitivity'] as num?)?.toInt() ?? 50,
      energy: (json['energy'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'leadership': leadership,
    'warmth': warmth,
    'independence': independence,
    'sensitivity': sensitivity,
    'energy': energy,
  };

  /// traits 벡터를 리스트로 변환 (궁합 계산용)
  List<int> toVector() => [leadership, warmth, independence, sensitivity, energy];

  /// 두 traits 간 상보성 점수 (0~100)
  static int compatibilityScore(GwansangTraits a, GwansangTraits b) {
    final va = a.toVector();
    final vb = b.toVector();

    var totalScore = 0.0;
    for (var i = 0; i < va.length; i++) {
      final diff = (va[i] - vb[i]).abs();
      final axisScore = diff <= 30
          ? 80 + (30 - diff) * 0.67
          : diff <= 60
              ? 60 + (60 - diff) * 0.67
              : 40 + (100 - diff) * 0.5;
      totalScore += axisScore;
    }
    return (totalScore / va.length).round().clamp(0, 100);
  }
}

/// 삼정(三停) 해석 — 얼굴 3구역별 운세
class SamjeongReading {
  const SamjeongReading({
    required this.upper,
    required this.middle,
    required this.lower,
  });

  /// 상정(上停) — 이마~눈썹: 초년운
  final String upper;

  /// 중정(中停) — 눈썹~코끝: 중년운
  final String middle;

  /// 하정(下停) — 코끝~턱: 말년운
  final String lower;

  factory SamjeongReading.fromJson(Map<String, dynamic> json) {
    return SamjeongReading(
      upper: json['upper'] as String? ?? '',
      middle: json['middle'] as String? ?? '',
      lower: json['lower'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'upper': upper,
    'middle': middle,
    'lower': lower,
  };
}

/// 오관(五官) 해석 — 눈·코·입·귀·눈썹 개별 해석
class OgwanReading {
  const OgwanReading({
    required this.eyes,
    required this.nose,
    required this.mouth,
    required this.ears,
    required this.eyebrows,
  });

  /// 눈 — 감찰관(監察官)
  final String eyes;

  /// 코 — 심판관(審判官)
  final String nose;

  /// 입 — 출납관(出納官)
  final String mouth;

  /// 귀 — 채청관(採聽官)
  final String ears;

  /// 눈썹 — 보수관(保壽官)
  final String eyebrows;

  factory OgwanReading.fromJson(Map<String, dynamic> json) {
    return OgwanReading(
      eyes: json['eyes'] as String? ?? '',
      nose: json['nose'] as String? ?? '',
      mouth: json['mouth'] as String? ?? '',
      ears: json['ears'] as String? ?? '',
      eyebrows: json['eyebrows'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'eyes': eyes,
    'nose': nose,
    'mouth': mouth,
    'ears': ears,
    'eyebrows': eyebrows,
  };
}

/// 관상 분석 결과 엔티티
class GwansangProfile {
  const GwansangProfile({
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

  final String id;
  final String userId;

  /// 닮은 동물 영어 키 (동적). 예: "cat", "dinosaur", "camel"
  final String animalType;

  /// 관상 특징에서 도출된 수식어. 예: "나른한", "배고픈"
  final String animalModifier;

  /// 동물 한글명. 예: "고양이", "공룡"
  final String animalTypeKorean;

  final FaceMeasurements measurements;
  final List<String> photoUrls;

  /// 한줄 헤드라인 (관상학 기반)
  final String headline;

  /// 삼정(三停) 해석
  final SamjeongReading samjeong;

  /// 오관(五官) 해석
  final OgwanReading ogwan;

  /// 성격 traits 5축
  final GwansangTraits traits;

  /// 성격 요약
  final String personalitySummary;

  /// 연애 스타일 요약
  final String romanceSummary;

  /// 연애/궁합 핵심 포인트 (3~5개)
  final List<String> romanceKeyPoints;

  /// 매력 키워드 (3개)
  final List<String> charmKeywords;

  /// 상세 관상 해석 (프리미엄 전용)
  final String? detailedReading;

  final DateTime createdAt;

  /// 수식어 + 동물 라벨. 예: "나른한 고양이상"
  String get animalLabel => '$animalModifier $animalTypeKorean상';

  GwansangProfile copyWith({
    String? id,
    String? userId,
    String? animalType,
    String? animalModifier,
    String? animalTypeKorean,
    FaceMeasurements? measurements,
    List<String>? photoUrls,
    String? headline,
    SamjeongReading? samjeong,
    OgwanReading? ogwan,
    GwansangTraits? traits,
    String? personalitySummary,
    String? romanceSummary,
    List<String>? romanceKeyPoints,
    List<String>? charmKeywords,
    String? detailedReading,
    DateTime? createdAt,
  }) {
    return GwansangProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      animalType: animalType ?? this.animalType,
      animalModifier: animalModifier ?? this.animalModifier,
      animalTypeKorean: animalTypeKorean ?? this.animalTypeKorean,
      measurements: measurements ?? this.measurements,
      photoUrls: photoUrls ?? this.photoUrls,
      headline: headline ?? this.headline,
      samjeong: samjeong ?? this.samjeong,
      ogwan: ogwan ?? this.ogwan,
      traits: traits ?? this.traits,
      personalitySummary: personalitySummary ?? this.personalitySummary,
      romanceSummary: romanceSummary ?? this.romanceSummary,
      romanceKeyPoints: romanceKeyPoints ?? this.romanceKeyPoints,
      charmKeywords: charmKeywords ?? this.charmKeywords,
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
      'GwansangProfile(id: $id, animal: $animalModifier $animalTypeKorean)';
}
