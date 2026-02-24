/// 궁합(Compatibility) 공유 도메인 엔티티
///
/// 궁합은 사주(saju)와 매칭(matching) 두 feature에서 모두 사용하는
/// 교차 도메인 개념입니다. Clean Architecture의 의존성 규칙을 지키기 위해
/// core/domain에 위치하여 양쪽 feature가 동등하게 참조합니다.
///
/// 사주 feature: 궁합을 **계산**한다
/// 매칭 feature: 궁합을 **소비/표시**한다
library;

// =============================================================================
// 궁합(Compatibility) 결과
// =============================================================================

/// 두 사람의 사주 궁합 결과
///
/// 오행 상생상극 분석, 일주 합충 분석, AI 보강 해석을 종합한 결과입니다.
class Compatibility {
  const Compatibility({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.score,
    this.fiveElementScore,
    this.dayPillarScore,
    this.overallAnalysis,
    required this.strengths,
    required this.challenges,
    this.advice,
    this.aiStory,
    required this.calculatedAt,
  });

  /// 궁합 결과 고유 ID
  final String id;

  /// 요청자 사용자 ID
  final String userId;

  /// 상대방 사용자 ID
  final String partnerId;

  // --- 점수 ---

  /// 종합 궁합 점수 (0~100)
  ///
  /// 오행 궁합, 일주 합충, AI 분석을 종합한 최종 점수입니다.
  final int score;

  /// 오행 상생상극 기반 점수 (0~100)
  final int? fiveElementScore;

  /// 일주(日柱) 합충 기반 점수 (0~100)
  final int? dayPillarScore;

  // --- 분석 결과 ---

  /// 전체 궁합 분석 요약
  final String? overallAnalysis;

  /// 궁합의 강점들
  ///
  /// 예: ["오행 상생 관계로 서로를 성장시킴", "일간 합으로 깊은 정서적 교감 가능"]
  final List<String> strengths;

  /// 궁합의 도전 과제들
  ///
  /// 예: ["금목 상충으로 의견 충돌 가능성", "화토 과다로 감정 격앙 주의"]
  final List<String> challenges;

  /// 관계를 위한 조언
  final String? advice;

  /// AI가 생성한 인연 스토리
  ///
  /// 매칭 시 사용자에게 보여주는 로맨틱한 내러티브입니다.
  /// 예: "당신의 맑은 수(水)기운과 상대의 따뜻한 화(火)기운이 만나
  /// 서로를 완성하는 운명적 조합입니다..."
  final String? aiStory;

  /// 궁합 계산 시각
  final DateTime calculatedAt;

  // ===========================================================================
  // 계산 프로퍼티
  // ===========================================================================

  /// 궁합 등급
  CompatibilityGrade get grade {
    if (score >= 90) return CompatibilityGrade.destined;
    if (score >= 75) return CompatibilityGrade.excellent;
    if (score >= 60) return CompatibilityGrade.good;
    if (score >= 40) return CompatibilityGrade.average;
    return CompatibilityGrade.challenging;
  }

  /// 프리미엄 전용 상세 분석이 포함되어 있는지
  bool get hasDetailedAnalysis =>
      overallAnalysis != null && advice != null && aiStory != null;

  Compatibility copyWith({
    String? id,
    String? userId,
    String? partnerId,
    int? score,
    int? fiveElementScore,
    int? dayPillarScore,
    String? overallAnalysis,
    List<String>? strengths,
    List<String>? challenges,
    String? advice,
    String? aiStory,
    DateTime? calculatedAt,
  }) {
    return Compatibility(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      score: score ?? this.score,
      fiveElementScore: fiveElementScore ?? this.fiveElementScore,
      dayPillarScore: dayPillarScore ?? this.dayPillarScore,
      overallAnalysis: overallAnalysis ?? this.overallAnalysis,
      strengths: strengths ?? this.strengths,
      challenges: challenges ?? this.challenges,
      advice: advice ?? this.advice,
      aiStory: aiStory ?? this.aiStory,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Compatibility && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Compatibility(score: $score, grade: ${grade.label})';
}

/// 궁합 등급
///
/// 마케팅적으로 매력적인 표현을 사용합니다.
enum CompatibilityGrade {
  destined('천생연분', '운명이 이끈 만남이에요', 90),
  excellent('최고의 인연', '아주 잘 맞는 사이예요', 75),
  good('좋은 인연', '함께 성장할 수 있는 관계예요', 60),
  average('보통 인연', '노력하면 좋은 관계가 될 수 있어요', 40),
  challenging('도전적 인연', '서로 다른 매력이 있는 관계예요', 0);

  const CompatibilityGrade(this.label, this.description, this.minScore);

  final String label;
  final String description;
  final int minScore;
}
