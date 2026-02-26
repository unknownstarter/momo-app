/// 동물상(動物相) 분류 및 궁합 매트릭스
///
/// 관상 분석을 통해 부여되는 10종 동물상 타입.
/// 각 동물상은 오행(五行)과 연결되어 사주와 시너지를 이룬다.
library;

import '../../../../core/constants/app_constants.dart';

/// 동물상 10종 분류
///
/// 관상 분석을 통해 부여되는 동물상 타입.
/// 각 동물상은 오행(五行)과 연결되어 사주와 시너지를 이룬다.
enum AnimalType {
  cat(
    korean: '고양이',
    label: '도도한 고양이상',
    emoji: '🐱',
    element: FiveElementType.wood,
    description: '다가오면 도망가고, 멀어지면 다가오는 밀당의 제왕',
  ),
  dog(
    korean: '강아지',
    label: '충직한 강아지상',
    emoji: '🐶',
    element: FiveElementType.fire,
    description: '한번 마음 주면 끝까지, 사랑 앞에 솔직한 타입',
  ),
  fox(
    korean: '여우',
    label: '영리한 여우상',
    emoji: '🦊',
    element: FiveElementType.fire,
    description: '본능적으로 분위기를 읽는 타고난 소셜 천재',
  ),
  wolf(
    korean: '늑대',
    label: '자유로운 늑대상',
    emoji: '🐺',
    element: FiveElementType.water,
    description: '속박을 싫어하고, 깊은 눈빛으로 상대를 사로잡는 타입',
  ),
  deer(
    korean: '사슴',
    label: '순수한 사슴상',
    emoji: '🦌',
    element: FiveElementType.wood,
    description: '맑은 눈망울로 모든 걸 녹여버리는 천연 매력가',
  ),
  rabbit(
    korean: '토끼',
    label: '사랑스러운 토끼상',
    emoji: '🐰',
    element: FiveElementType.earth,
    description: '귀여움이 무기, 보호본능을 자극하는 타입',
  ),
  bear(
    korean: '곰',
    label: '든든한 곰상',
    emoji: '🐻',
    element: FiveElementType.earth,
    description: '말은 없지만 행동으로 보여주는 묵직한 존재감',
  ),
  snake(
    korean: '뱀',
    label: '신비로운 뱀상',
    emoji: '🐍',
    element: FiveElementType.water,
    description: '쉽게 읽히지 않는 미스터리, 한번 빠지면 헤어나올 수 없는 매력',
  ),
  tiger(
    korean: '호랑이',
    label: '카리스마 호랑이상',
    emoji: '🐯',
    element: FiveElementType.metal,
    description: '있는 것만으로도 존재감 폭발, 타고난 리더상',
  ),
  crane(
    korean: '학',
    label: '고고한 학상',
    emoji: '🦢',
    element: FiveElementType.metal,
    description: '우아함의 끝판왕, 범접할 수 없는 고급 아우라',
  );

  const AnimalType({
    required this.korean,
    required this.label,
    required this.emoji,
    required this.element,
    required this.description,
  });

  /// 한글 이름 (예: "고양이")
  final String korean;

  /// 동물상 레이블 (예: "도도한 고양이상")
  final String label;

  /// 이모지 아이콘
  final String emoji;

  /// 연결된 오행 타입
  final FiveElementType element;

  /// 한줄 설명
  final String description;

  /// JSON 직렬화용 — 문자열에서 AnimalType으로 변환
  static AnimalType fromString(String value) {
    return AnimalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnimalType.cat,
    );
  }
}

// =============================================================================
// 동물상 궁합 매트릭스
// =============================================================================

/// 동물상 궁합 매트릭스
///
/// 찰떡궁합(5), 밀당궁합(4), 보통궁합(3), 위험한 궁합(2) 등
/// 정의되지 않은 조합은 기본 3(보통궁합)을 반환합니다.
abstract final class AnimalCompatibility {
  static const Map<(AnimalType, AnimalType), int> matrix = {
    // 찰떡궁합 (5)
    (AnimalType.cat, AnimalType.dog): 5,
    (AnimalType.fox, AnimalType.bear): 5,
    (AnimalType.wolf, AnimalType.deer): 5,
    (AnimalType.rabbit, AnimalType.tiger): 5,
    (AnimalType.snake, AnimalType.crane): 5,

    // 밀당궁합 (4)
    (AnimalType.cat, AnimalType.wolf): 4,
    (AnimalType.fox, AnimalType.snake): 4,
    (AnimalType.tiger, AnimalType.wolf): 4,

    // 위험한 궁합 (2)
    (AnimalType.cat, AnimalType.cat): 2,
    (AnimalType.tiger, AnimalType.tiger): 2,
    (AnimalType.wolf, AnimalType.rabbit): 2,
  };

  /// 두 동물상의 궁합 점수 (기본값 3)
  static int score(AnimalType a, AnimalType b) {
    return matrix[(a, b)] ?? matrix[(b, a)] ?? 3;
  }

  /// 궁합 등급 텍스트
  static String grade(int score) => switch (score) {
    5 => '찰떡궁합',
    4 => '밀당궁합',
    3 => '보통궁합',
    2 => '위험한 궁합',
    _ => '보통궁합',
  };
}
