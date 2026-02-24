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
