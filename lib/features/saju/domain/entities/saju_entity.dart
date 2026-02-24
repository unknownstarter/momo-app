/// 사주(四柱) 관련 도메인 엔티티
///
/// 사주팔자(四柱八字)는 태어난 연월일시의 네 기둥(四柱)으로 구성되며,
/// 각 기둥은 천간(天干)과 지지(地支) 두 글자, 총 여덟 글자(八字)입니다.
///
/// 이 파일의 엔티티들은 순수 Dart 클래스로, 외부 의존성이 없습니다.
/// TODO: freezed 어노테이션 추가 후 build_runner 실행
library;

import '../../../../core/constants/app_constants.dart';

// =============================================================================
// 기둥(柱) - 사주의 기본 단위
// =============================================================================

/// 하나의 기둥(柱)
///
/// 천간(天干) + 지지(地支)의 조합으로 이루어집니다.
/// 예: 갑자(甲子), 을축(乙丑), 병인(丙寅) 등
class Pillar {
  const Pillar({
    required this.heavenlyStem,
    required this.earthlyBranch,
  });

  /// 천간(天干): 갑을병정무기경신임계
  final String heavenlyStem;

  /// 지지(地支): 자축인묘진사오미신유술해
  final String earthlyBranch;

  /// 천간의 한자
  String get heavenlyStemHanja =>
      HeavenlyStems.hanja[heavenlyStem] ?? heavenlyStem;

  /// 지지의 한자
  String get earthlyBranchHanja =>
      EarthlyBranches.hanja[earthlyBranch] ?? earthlyBranch;

  /// 천간의 오행
  FiveElementType? get stemElement =>
      HeavenlyStems.fiveElementMap[heavenlyStem];

  /// 지지의 오행
  FiveElementType? get branchElement =>
      EarthlyBranches.fiveElementMap[earthlyBranch];

  /// 지지에 해당하는 띠 동물 (연주에서만 의미 있음)
  String? get animal => EarthlyBranches.animals[earthlyBranch];

  /// 한글 표기 (예: "갑자")
  String get korean => '$heavenlyStem$earthlyBranch';

  /// 한자 표기 (예: "甲子")
  String get hanja => '$heavenlyStemHanja$earthlyBranchHanja';

  /// 전체 표기 (예: "갑자(甲子)")
  String get display => '$korean($hanja)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pillar &&
          heavenlyStem == other.heavenlyStem &&
          earthlyBranch == other.earthlyBranch;

  @override
  int get hashCode => Object.hash(heavenlyStem, earthlyBranch);

  @override
  String toString() => 'Pillar($korean)';
}

// =============================================================================
// 오행 분포 (五行 分布)
// =============================================================================

/// 오행의 수치 분포
///
/// 사주팔자의 8글자에서 각 오행이 몇 개 있는지를 나타냅니다.
/// 이 분포에 따라 성격, 체질, 궁합 등을 해석합니다.
class FiveElements {
  const FiveElements({
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
  });

  /// 목(木) - 성장, 인, 간담
  final int wood;

  /// 화(火) - 열정, 예, 심소장
  final int fire;

  /// 토(土) - 안정, 신, 비위
  final int earth;

  /// 금(金) - 결단, 의, 폐대장
  final int metal;

  /// 수(水) - 지혜, 지, 신방광
  final int water;

  /// 전체 합계
  int get total => wood + fire + earth + metal + water;

  /// 가장 강한 오행
  FiveElementType get dominant {
    final map = toMap();
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// 가장 약한 오행
  FiveElementType get weakest {
    final map = toMap();
    return map.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  /// 부족한 오행 (0인 것들)
  List<FiveElementType> get missing {
    return toMap()
        .entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList();
  }

  /// 특정 오행의 비율 (0.0 ~ 1.0)
  double ratio(FiveElementType element) {
    if (total == 0) return 0;
    return toMap()[element]! / total;
  }

  /// Map 변환
  Map<FiveElementType, int> toMap() => {
        FiveElementType.wood: wood,
        FiveElementType.fire: fire,
        FiveElementType.earth: earth,
        FiveElementType.metal: metal,
        FiveElementType.water: water,
      };

  /// 균형 점수 (0~100, 높을수록 균형잡힘)
  ///
  /// 완벽 균형(모두 동일)이면 100, 하나에 치우칠수록 낮아짐
  int get balanceScore {
    if (total == 0) return 0;
    final avg = total / 5;
    final deviation =
        [wood, fire, earth, metal, water].fold<double>(0, (sum, val) {
      return sum + (val - avg).abs();
    });
    // 최대 편차 대비 현재 편차의 비율을 100점으로 변환
    final maxDeviation = avg * 8; // 이론적 최대 편차
    return ((1 - deviation / maxDeviation) * 100).round().clamp(0, 100);
  }

  FiveElements copyWith({
    int? wood,
    int? fire,
    int? earth,
    int? metal,
    int? water,
  }) {
    return FiveElements(
      wood: wood ?? this.wood,
      fire: fire ?? this.fire,
      earth: earth ?? this.earth,
      metal: metal ?? this.metal,
      water: water ?? this.water,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiveElements &&
          wood == other.wood &&
          fire == other.fire &&
          earth == other.earth &&
          metal == other.metal &&
          water == other.water;

  @override
  int get hashCode => Object.hash(wood, fire, earth, metal, water);

  @override
  String toString() =>
      'FiveElements(목:$wood 화:$fire 토:$earth 금:$metal 수:$water)';
}

// =============================================================================
// 사주 프로필 (四柱 Profile)
// =============================================================================

/// 사주 프로필 - 한 사람의 완전한 사주 정보
///
/// 네 개의 기둥(연주/월주/일주/시주)과 오행 분포, AI 해석 결과를 포함합니다.
/// 시주는 태어난 시각을 모르는 경우 null이 될 수 있습니다.
class SajuProfile {
  const SajuProfile({
    required this.id,
    required this.userId,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.fiveElements,
    this.dominantElement,
    this.personalityTraits = const [],
    this.aiInterpretation,
    this.isLunarCalendar = false,
    required this.birthDateTime,
    required this.calculatedAt,
  });

  /// 사주 프로필 고유 ID
  final String id;

  /// 소유 사용자 ID
  final String userId;

  // --- 사주 네 기둥 ---

  /// 연주(年柱): 태어난 해의 기둥
  ///
  /// 조상궁, 사회적 성격, 초년운(1~15세)을 나타냅니다.
  final Pillar yearPillar;

  /// 월주(月柱): 태어난 달의 기둥
  ///
  /// 부모궁, 사회적 관계, 청년운(16~30세)을 나타냅니다.
  final Pillar monthPillar;

  /// 일주(日柱): 태어난 날의 기둥
  ///
  /// **사주의 핵심**. 본인궁, 배우자궁.
  /// 일간(日干)은 "나 자신"을 대표하며, 궁합 계산의 기준점입니다.
  final Pillar dayPillar;

  /// 시주(時柱): 태어난 시각의 기둥
  ///
  /// 자녀궁, 말년운(46세~). 태어난 시각을 모르면 null.
  final Pillar? hourPillar;

  // --- 오행 분석 ---

  /// 오행 분포 (사주 8자에서 각 오행의 개수)
  final FiveElements fiveElements;

  /// 주도적 오행 (일간 기준)
  final FiveElementType? dominantElement;

  // --- AI 해석 ---

  /// 성격 특성 키워드 (AI 분석 결과)
  final List<String> personalityTraits;

  /// AI 해석 전문
  final String? aiInterpretation;

  // --- 메타데이터 ---

  /// 음력 기반 계산 여부
  final bool isLunarCalendar;

  /// 입력된 생년월일시
  final DateTime birthDateTime;

  /// 사주 계산 시각
  final DateTime calculatedAt;

  // ===========================================================================
  // 계산 프로퍼티
  // ===========================================================================

  /// 일간(日干) - "나 자신"을 대표하는 천간
  ///
  /// 사주 분석과 궁합 계산에서 가장 중요한 글자입니다.
  String get dayStem => dayPillar.heavenlyStem;

  /// 시주 포함 여부 (삼주 vs 사주)
  bool get hasHourPillar => hourPillar != null;

  /// 모든 기둥을 리스트로
  List<Pillar> get allPillars => [
        yearPillar,
        monthPillar,
        dayPillar,
        ?hourPillar,
      ];

  /// 띠 (연주 지지의 동물)
  String? get zodiacAnimal => yearPillar.animal;

  /// 사주 한줄 요약 (예: "갑자 을축 병인 정묘")
  String get summary {
    final pillars = [
      yearPillar.korean,
      monthPillar.korean,
      dayPillar.korean,
      hourPillar?.korean ?? '??',
    ];
    return pillars.join(' ');
  }

  SajuProfile copyWith({
    String? id,
    String? userId,
    Pillar? yearPillar,
    Pillar? monthPillar,
    Pillar? dayPillar,
    Pillar? hourPillar,
    FiveElements? fiveElements,
    FiveElementType? dominantElement,
    List<String>? personalityTraits,
    String? aiInterpretation,
    bool? isLunarCalendar,
    DateTime? birthDateTime,
    DateTime? calculatedAt,
  }) {
    return SajuProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      yearPillar: yearPillar ?? this.yearPillar,
      monthPillar: monthPillar ?? this.monthPillar,
      dayPillar: dayPillar ?? this.dayPillar,
      hourPillar: hourPillar ?? this.hourPillar,
      fiveElements: fiveElements ?? this.fiveElements,
      dominantElement: dominantElement ?? this.dominantElement,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      isLunarCalendar: isLunarCalendar ?? this.isLunarCalendar,
      birthDateTime: birthDateTime ?? this.birthDateTime,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SajuProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SajuProfile(id: $id, summary: $summary)';
}

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
