/// 매칭 프로필 도메인 엔티티
///
/// 매칭 추천 목록에서 사용되는 프로필 데이터입니다.
/// 순수 비즈니스 엔티티로, 외부 의존성이 없습니다.
class MatchProfile {
  const MatchProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.bio,
    this.photoUrl,
    required this.characterName,
    this.characterAssetPath,
    required this.elementType,
    required this.compatibilityScore,
    this.animalType,
    this.animalModifier,
    this.animalTypeKorean,
    this.gwansangTraits,
    this.height,
    this.location,
    this.occupation,
    this.bodyType,
    this.religion,
    this.isPhoneVerified = false,
  });

  /// 사용자 고유 ID
  final String userId;

  /// 사용자 이름
  final String name;

  /// 나이
  final int age;

  /// 자기소개
  final String bio;

  /// 프로필 사진 URL (없으면 캐릭터로 표시)
  final String? photoUrl;

  /// 오행이 캐릭터 이름 (예: "나무리", "불꼬리")
  final String characterName;

  /// 캐릭터 에셋 경로 (예: "assets/images/characters/namuri_wood_default.png")
  final String? characterAssetPath;

  /// 오행 타입 문자열 ('wood', 'fire', 'earth', 'metal', 'water')
  final String elementType;

  /// 궁합 점수 (0~100)
  final int compatibilityScore;

  /// 닮은 동물 (관상 분석 완료 시). 예: "cat", "fox"
  final String? animalType;

  /// 동물 수식어 (관상 분석 완료 시). 예: "나른한", "배고픈"
  final String? animalModifier;

  /// 동물 한글명 (관상 분석 완료 시). 예: "고양이", "여우"
  final String? animalTypeKorean;

  /// 관상 traits 5축 (궁합 계산용)
  final Map<String, int>? gwansangTraits;

  // --- 데이팅 프로필 정보 (프로필 상세, 매칭 카드 표시용) ---

  /// 키 (cm)
  final int? height;

  /// 활동 지역
  final String? location;

  /// 직업
  final String? occupation;

  /// 체형
  final String? bodyType;

  /// 종교
  final String? religion;

  /// SMS 전화번호 인증 완료 여부 (진심 마크 뱃지)
  final bool isPhoneVerified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchProfile && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'MatchProfile(name: $name, element: $elementType, score: $compatibilityScore)';
}
