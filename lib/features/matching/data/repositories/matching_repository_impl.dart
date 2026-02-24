/// 매칭 Repository Mock 구현체
///
/// Supabase 연동 전까지 사용되는 Mock 데이터 기반 구현입니다.
/// 실제 서비스에서는 [MatchingRepositoryImpl]로 교체됩니다.
library;

import '../../domain/entities/like_entity.dart';
import '../../domain/entities/match_profile.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../../saju/domain/entities/saju_entity.dart';

// =============================================================================
// Mock 매칭 프로필 데이터
// =============================================================================

/// Mock 추천 프로필 목록 (궁합 점수 내림차순)
const _mockProfiles = <MatchProfile>[
  MatchProfile(
    userId: 'mock-user-001',
    name: '하늘',
    age: 26,
    bio: '바다처럼 깊은 마음을 가진 사람이에요',
    characterName: '물결이',
    characterAssetPath: 'assets/images/characters/mulgyeori_water_default.png',
    elementType: 'water',
    compatibilityScore: 92,
  ),
  MatchProfile(
    userId: 'mock-user-002',
    name: '수아',
    age: 24,
    bio: '밝은 에너지로 주변을 환하게 해요',
    characterName: '불꼬리',
    characterAssetPath: 'assets/images/characters/bulkkori_fire_default.png',
    elementType: 'fire',
    compatibilityScore: 78,
  ),
  MatchProfile(
    userId: 'mock-user-003',
    name: '지은',
    age: 27,
    bio: '함께 성장하는 관계를 꿈꿔요',
    characterName: '나무리',
    characterAssetPath: 'assets/images/characters/namuri_wood_default.png',
    elementType: 'wood',
    compatibilityScore: 65,
  ),
  MatchProfile(
    userId: 'mock-user-004',
    name: '민서',
    age: 25,
    bio: '따뜻하고 안정적인 사람을 만나고 싶어요',
    characterName: '흙순이',
    characterAssetPath: 'assets/images/characters/heuksuni_earth_default.png',
    elementType: 'earth',
    compatibilityScore: 54,
  ),
  MatchProfile(
    userId: 'mock-user-005',
    name: '서현',
    age: 28,
    bio: '결단력 있고 목표가 뚜렷한 편이에요',
    characterName: '쇠동이',
    characterAssetPath: 'assets/images/characters/soedongi_metal_default.png',
    elementType: 'metal',
    compatibilityScore: 45,
  ),
  MatchProfile(
    userId: 'mock-user-006',
    name: '유진',
    age: 25,
    bio: '반짝이는 순간을 소중히 여기는 사람이에요',
    characterName: '황금토끼',
    characterAssetPath: 'assets/images/characters/gold_tokki_default.png',
    elementType: 'metal',
    compatibilityScore: 88,
  ),
  MatchProfile(
    userId: 'mock-user-007',
    name: '다은',
    age: 26,
    bio: '조용하지만 깊은 이야기를 나누고 싶어요',
    characterName: '검은토끼',
    characterAssetPath: 'assets/images/characters/black_tokki_default.png',
    elementType: 'water',
    compatibilityScore: 71,
  ),
];

/// 프로필별 Mock 궁합 강점 데이터
const _mockStrengths = <String, List<String>>{
  'mock-user-001': [
    '수(水) 기운의 깊은 교감으로 서로의 내면을 이해해요',
    '감성적 파장이 맞아 대화가 자연스럽게 흘러요',
    '서로의 부족함을 채워주는 상생 관계예요',
  ],
  'mock-user-002': [
    '화(火) 기운의 열정이 관계에 활력을 불어넣어요',
    '서로의 꿈을 응원하며 함께 성장할 수 있어요',
    '밝은 에너지가 어두운 날에도 빛이 되어줘요',
  ],
  'mock-user-003': [
    '목(木) 기운의 성장 에너지가 관계를 발전시켜요',
    '서로를 존중하는 자세로 건강한 관계를 만들어요',
    '유연한 소통으로 갈등을 지혜롭게 풀어나가요',
  ],
  'mock-user-004': [
    '토(土) 기운의 안정감이 관계의 기반이 되어요',
    '변함없는 마음으로 서로를 지켜줄 수 있어요',
    '실용적인 가치관이 맞아 일상이 편안해요',
  ],
  'mock-user-005': [
    '금(金) 기운의 결단력이 관계에 방향성을 줘요',
    '서로의 원칙을 존중하며 신뢰를 쌓아가요',
    '명확한 소통으로 오해를 줄일 수 있어요',
  ],
  'mock-user-006': [
    '금(金) 기운의 빛나는 직관이 서로를 깊이 이해하게 해요',
    '운명적 끌림이 강해 첫 만남부터 자연스러운 교감이 있어요',
    '서로의 꿈을 비추는 거울 같은 존재가 될 수 있어요',
  ],
  'mock-user-007': [
    '수(水) 기운의 신비로운 매력이 관계에 깊이를 더해요',
    '말보다 마음으로 통하는 교감이 특별해요',
    '서로의 내면을 존중하며 조용히 성장하는 관계예요',
  ],
};

/// 프로필별 Mock 궁합 도전 과제 데이터
const _mockChallenges = <String, List<String>>{
  'mock-user-001': [
    '감정이 깊어 때로는 서로의 기분에 영향을 많이 받을 수 있어요',
    '내성적인 면이 겹쳐 새로운 도전에 소극적일 수 있어요',
    '서로의 감정 표현 방식이 달라 오해가 생길 수 있어요',
  ],
  'mock-user-002': [
    '서로의 에너지가 강해 가끔 충돌이 있을 수 있어요',
    '급한 성격이 겹쳐 인내심을 기르면 좋겠어요',
    '독립적인 성향이 강해 함께하는 시간 조율이 필요해요',
  ],
  'mock-user-003': [
    '서로에게 기대하는 바가 달라 조율이 필요해요',
    '가치관의 차이가 때로는 갈등의 원인이 될 수 있어요',
    '속도감이 달라 서로의 페이스를 맞추는 노력이 필요해요',
  ],
  'mock-user-004': [
    '안정을 추구하다 새로운 시도를 놓칠 수 있어요',
    '변화에 대한 두려움이 관계 발전을 늦출 수 있어요',
    '서로의 루틴을 존중하면서도 새로움을 찾아보세요',
  ],
  'mock-user-005': [
    '고집이 강한 면이 만나면 타협이 어려울 수 있어요',
    '감정 표현에 서툴러 상대가 서운할 수 있어요',
    '목표 지향적 성향이 겹쳐 관계에 소홀할 수 있어요',
  ],
  'mock-user-006': [
    '서로의 이상이 높아 현실과의 괴리를 느낄 수 있어요',
    '완벽주의적 성향이 겹쳐 작은 것에 예민해질 수 있어요',
    '빛나는 순간만 추구하다 일상의 소중함을 놓칠 수 있어요',
  ],
  'mock-user-007': [
    '조용한 성격이 겹쳐 서로의 마음을 확인하기 어려울 수 있어요',
    '내면으로 감정을 삭이면 오해가 쌓일 수 있어요',
    '변화를 두려워해 관계가 정체될 수 있어요',
  ],
};

// =============================================================================
// Mock Repository 구현
// =============================================================================

/// Mock 매칭 Repository
///
/// 하드코딩된 데이터를 반환하며, 네트워크 지연을 시뮬레이션합니다.
class MockMatchingRepository implements MatchingRepository {
  @override
  Future<List<MatchProfile>> getDailyRecommendations() async {
    // 네트워크 지연 시뮬레이션
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _mockProfiles;
  }

  @override
  Future<Compatibility> getCompatibilityPreview(String partnerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // 해당 프로필 찾기
    final profile = _mockProfiles.firstWhere(
      (p) => p.userId == partnerId,
      orElse: () => _mockProfiles.first,
    );

    final strengths = _mockStrengths[partnerId] ??
        _mockStrengths[_mockProfiles.first.userId]!;
    final challenges = _mockChallenges[partnerId] ??
        _mockChallenges[_mockProfiles.first.userId]!;

    return Compatibility(
      id: 'compat-$partnerId',
      userId: 'current-user',
      partnerId: partnerId,
      score: profile.compatibilityScore,
      fiveElementScore: (profile.compatibilityScore * 0.9).round(),
      dayPillarScore: (profile.compatibilityScore * 1.1).round().clamp(0, 100),
      overallAnalysis:
          '${profile.name}님과의 궁합은 ${profile.compatibilityScore}점으로, '
          '${profile.elementType == 'water' ? '수(水)' : profile.elementType == 'fire' ? '화(火)' : profile.elementType == 'wood' ? '목(木)' : profile.elementType == 'earth' ? '토(土)' : '금(金)'}'
          ' 기운이 서로의 기운과 조화를 이루고 있어요.',
      strengths: strengths,
      challenges: challenges,
      advice:
          '서로의 다른 점을 인정하고 존중하면, 더없이 좋은 관계로 발전할 수 있어요. '
          '가끔은 상대의 입장에서 생각해보는 시간을 가져보세요.',
      aiStory:
          '운명의 실이 두 사람을 이어주고 있어요. '
          '${profile.name}님의 ${profile.elementType == 'water' ? '깊고 맑은 수(水)' : profile.elementType == 'fire' ? '뜨겁고 밝은 화(火)' : profile.elementType == 'wood' ? '성장하는 목(木)' : profile.elementType == 'earth' ? '든든한 토(土)' : '빛나는 금(金)'}'
          ' 기운이 당신의 사주와 아름다운 조화를 만들어내고 있답니다.',
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendLike(String receiverId, {bool isPremium = false}) async {
    // 네트워크 지연 시뮬레이션
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Mock: 실제 저장 없이 성공 반환
  }

  @override
  Future<void> acceptLike(String likeId) async {
    // 네트워크 지연 시뮬레이션
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Mock: 실제 처리 없이 성공 반환
  }

  @override
  Future<List<Like>> getReceivedLikes() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    return [
      Like(
        id: 'like-001',
        senderId: 'mock-user-001',
        receiverId: 'current-user',
        isPremium: true,
        status: LikeStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Like(
        id: 'like-002',
        senderId: 'mock-user-002',
        receiverId: 'current-user',
        isPremium: false,
        status: LikeStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
