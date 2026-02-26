/// 앱 전역 상수 정의
///
/// 라우트 경로, Supabase 테이블명, 사주 관련 상수, 앱 제한값 등
/// 모든 매직 넘버와 매직 스트링을 이곳에서 관리합니다.
library;

// =============================================================================
// 라우트 경로 상수
// =============================================================================

/// go_router에서 사용하는 경로 상수
abstract final class RoutePaths {
  // --- 인증 플로우 ---
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const phoneVerification = '/phone-verification';

  // --- 메인 탭 (ShellRoute) ---
  static const home = '/home';
  static const matching = '/matching';
  static const chat = '/chat';
  static const profile = '/profile';

  // --- 서브 페이지 ---
  static const sajuAnalysis = '/saju-analysis';
  static const sajuResult = '/saju-result';
  static const matchingProfile = '/matching-profile';
  static const matchDetail = '/matching/:matchId';
  static const chatRoom = '/chat/:roomId';
  static const settings = '/settings';
  static const editProfile = '/profile/edit';
  static const payment = '/payment';
  static const paymentSuccess = '/payment/success';

  // --- 관상 퍼널 ---
  static const gwansangBridge = '/gwansang-bridge';
  static const gwansangPhoto = '/gwansang-photo';
  static const gwansangAnalysis = '/gwansang-analysis';
  static const gwansangResult = '/gwansang-result';

  /// matchDetail 경로에 실제 ID를 삽입
  static String matchDetailPath(String matchId) => '/matching/$matchId';

  /// chatRoom 경로에 실제 ID를 삽입
  static String chatRoomPath(String roomId) => '/chat/$roomId';
}

/// go_router의 name 파라미터로 사용하는 라우트 이름
abstract final class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const phoneVerification = 'phone-verification';
  static const home = 'home';
  static const matching = 'matching';
  static const chat = 'chat';
  static const profile = 'profile';
  static const sajuAnalysis = 'saju-analysis';
  static const sajuResult = 'saju-result';
  static const matchingProfile = 'matching-profile';
  static const matchDetail = 'match-detail';
  static const chatRoom = 'chat-room';
  static const settings = 'settings';
  static const editProfile = 'edit-profile';
  static const payment = 'payment';
  static const paymentSuccess = 'payment-success';
  static const gwansangBridge = 'gwansang-bridge';
  static const gwansangPhoto = 'gwansang-photo';
  static const gwansangAnalysis = 'gwansang-analysis';
  static const gwansangResult = 'gwansang-result';
}

// =============================================================================
// Supabase 테이블명 상수
// =============================================================================

/// Supabase 데이터베이스 테이블명
///
/// RLS(Row Level Security) 정책은 각 테이블에 적용되어 있어야 합니다.
abstract final class SupabaseTables {
  static const profiles = 'profiles';
  static const sajuProfiles = 'saju_profiles';
  static const matches = 'matches';
  static const chatRooms = 'chat_rooms';
  static const chatMessages = 'chat_messages';
  static const likes = 'likes';
  static const blocks = 'blocks';
  static const reports = 'reports';
  static const subscriptions = 'subscriptions';
  static const dailyRecommendations = 'daily_recommendations';
  static const sajuCompatibility = 'saju_compatibility';
  static const userPoints = 'user_points';
  static const pointTransactions = 'point_transactions';
  static const dailyUsage = 'daily_usage';
  static const characterItems = 'character_items';
  static const purchases = 'purchases';
  static const gwansangProfiles = 'gwansang_profiles';
}

/// Supabase Storage 버킷명
abstract final class SupabaseBuckets {
  static const profileImages = 'profile-images';
  static const chatImages = 'chat-images';
  static const sajuCards = 'saju-cards';
  static const gwansangPhotos = 'gwansang-photos';
}

/// Supabase Edge Function 이름
abstract final class SupabaseFunctions {
  static const calculateSaju = 'calculate-saju';
  static const calculateCompatibility = 'calculate-compatibility';
  static const generateSajuInsight = 'generate-saju-insight';
  static const generateMatchStory = 'generate-match-story';
  static const sendSmsVerification = 'send-sms-verification';
  static const verifySmsCode = 'verify-sms-code';
  static const sendLike = 'send-like';
  static const acceptLike = 'accept-like';
  static const purchasePoints = 'purchase-points';
  static const getDailyMatches = 'get-daily-matches';
  static const resetDailyUsage = 'reset-daily-usage';
  static const generateGwansangReading = 'generate-gwansang-reading';
}

// =============================================================================
// 사주(四柱) 관련 상수
// =============================================================================

/// 천간(天干) - 10개의 하늘 기운
///
/// 양: 갑, 병, 무, 경, 임
/// 음: 을, 정, 기, 신, 계
abstract final class HeavenlyStems {
  static const all = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];

  // 양 천간
  static const yang = ['갑', '병', '무', '경', '임'];
  // 음 천간
  static const yin = ['을', '정', '기', '신', '계'];

  // 한자 매핑
  static const hanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };

  // 오행 매핑
  static const fiveElementMap = {
    '갑': FiveElementType.wood, '을': FiveElementType.wood,
    '병': FiveElementType.fire, '정': FiveElementType.fire,
    '무': FiveElementType.earth, '기': FiveElementType.earth,
    '경': FiveElementType.metal, '신': FiveElementType.metal,
    '임': FiveElementType.water, '계': FiveElementType.water,
  };
}

/// 지지(地支) - 12개의 땅 기운 (12지신)
///
/// 자축인묘진사오미신유술해
abstract final class EarthlyBranches {
  static const all = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

  // 한자 매핑
  static const hanja = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
    '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
  };

  // 12지신 동물
  static const animals = {
    '자': '쥐', '축': '소', '인': '호랑이', '묘': '토끼',
    '진': '용', '사': '뱀', '오': '말', '미': '양',
    '신': '원숭이', '유': '닭', '술': '개', '해': '돼지',
  };

  // 오행 매핑
  static const fiveElementMap = {
    '자': FiveElementType.water, '축': FiveElementType.earth,
    '인': FiveElementType.wood, '묘': FiveElementType.wood,
    '진': FiveElementType.earth, '사': FiveElementType.fire,
    '오': FiveElementType.fire, '미': FiveElementType.earth,
    '신': FiveElementType.metal, '유': FiveElementType.metal,
    '술': FiveElementType.earth, '해': FiveElementType.water,
  };
}

/// 오행(五行) 타입
enum FiveElementType {
  wood('목', '木', '나무'),
  fire('화', '火', '불'),
  earth('토', '土', '흙'),
  metal('금', '金', '쇠'),
  water('수', '水', '물');

  const FiveElementType(this.korean, this.hanja, this.meaning);

  final String korean;
  final String hanja;
  final String meaning;
}

/// 오행 상생상극 관계
///
/// 상생(相生): 서로 살리는 관계 (목→화→토→금→수→목)
/// 상극(相剋): 서로 이기는 관계 (목→토→수→화→금→목)
abstract final class FiveElementRelations {
  // 상생: key가 value를 생함
  static const generating = {
    FiveElementType.wood: FiveElementType.fire,   // 목생화
    FiveElementType.fire: FiveElementType.earth,   // 화생토
    FiveElementType.earth: FiveElementType.metal,  // 토생금
    FiveElementType.metal: FiveElementType.water,  // 금생수
    FiveElementType.water: FiveElementType.wood,   // 수생목
  };

  // 상극: key가 value를 극함
  static const overcoming = {
    FiveElementType.wood: FiveElementType.earth,   // 목극토
    FiveElementType.earth: FiveElementType.water,  // 토극수
    FiveElementType.water: FiveElementType.fire,   // 수극화
    FiveElementType.fire: FiveElementType.metal,   // 화극금
    FiveElementType.metal: FiveElementType.wood,   // 금극목
  };
}

// =============================================================================
// 앱 제한값 및 비즈니스 상수
// =============================================================================

/// 앱 전반의 제한값과 비즈니스 규칙
abstract final class AppLimits {
  // --- 프로필 ---
  static const maxPhotos = 6;
  static const minPhotos = 1;
  static const maxBioLength = 300;
  static const minBioLength = 10;
  static const maxNameLength = 20;
  static const minNameLength = 2;
  static const maxInterests = 10;
  static const minAge = 18;
  static const maxAge = 60;

  // --- 매칭 ---
  static const dailyFreeMatchLimit = 3;
  static const dailyPremiumMatchLimit = 20;
  static const compatibilityScoreMin = 0;
  static const compatibilityScoreMax = 100;

  // --- 채팅 ---
  static const maxMessageLength = 1000;
  static const maxChatImageSizeMb = 10;
  static const chatPageSize = 50; // 한 번에 로드하는 메시지 수

  // --- 사주 ---
  static const freeSajuAnalysisCount = 1; // 무료 사주 분석 횟수
  static const freeCompatibilityCount = 1; // 무료 궁합 분석 횟수

  // --- 결제 ---
  static const trialPeriodDays = 7;

  // --- 좋아요/수락 ---
  static const dailyFreeLikeLimit = 3;
  static const dailyFreeAcceptLimit = 3;

  // --- 포인트 비용 ---
  static const likeCost = 100;
  static const premiumLikeCost = 300;
  static const acceptCost = 100;
  static const compatibilityReportCost = 500;
  static const sajuDetailedReportCost = 500;
  static const icebreakerCost = 100;
  static const characterSkinMinCost = 200;
  static const characterSkinMaxCost = 500;
}

// =============================================================================
// 캐릭터 에셋 경로 상수
// =============================================================================

/// 오행 마스코트 캐릭터 에셋 경로
///
/// 모든 캐릭터 에셋은 이곳에서 관리합니다.
/// 절대 presentation 레이어에서 직접 문자열로 참조하지 마세요.
abstract final class CharacterAssets {
  // --- 기본(default) 에셋 ---
  static const namuriWoodDefault =
      'assets/images/characters/namuri_wood_default.png';
  static const bulkkoriFireDefault =
      'assets/images/characters/bulkkori_fire_default.png';
  static const heuksuniEarthDefault =
      'assets/images/characters/heuksuni_earth_default.png';
  static const soedongiMetalDefault =
      'assets/images/characters/soedongi_metal_default.png';
  static const mulgyeoriWaterDefault =
      'assets/images/characters/mulgyeori_water_default.png';

  // --- 표정(expressions) ---
  static const namuriWoodExpressions =
      'assets/images/characters/namuri_wood_expressions.png';
  static const bulkkoriFireExpressions =
      'assets/images/characters/bulkkori_fire_expressions.png';
  static const heuksuniEarthExpressions =
      'assets/images/characters/heuksuni_earth_expressions.png';
  static const soedongiMetalExpressions =
      'assets/images/characters/soedongi_metal_expressions.png';
  static const mulgyeoriWaterExpressions =
      'assets/images/characters/mulgyeori_water_expressions.png';

  // --- 포즈(poses) ---
  static const namuriWoodPoses =
      'assets/images/characters/namuri_wood_poses.png';
  static const bulkkoriFirePoses =
      'assets/images/characters/bulkkori_fire_poses.png';
  static const heuksuniEarthPoses =
      'assets/images/characters/heuksuni_earth_poses.png';
  static const soedongiMetalPoses =
      'assets/images/characters/soedongi_metal_poses.png';
  static const mulgyeoriWaterPoses =
      'assets/images/characters/mulgyeori_water_poses.png';

  // --- 턴어라운드(turnaround) ---
  static const namuriWoodTurnaround =
      'assets/images/characters/namuri_wood_turnaround.png';
  static const bulkkoriFireTurnaround =
      'assets/images/characters/bulkkori_fire_turnaround.png';
  static const heuksuniEarthTurnaround =
      'assets/images/characters/heuksuni_earth_turnaround.png';
  static const soedongiMetalTurnaround =
      'assets/images/characters/soedongi_metal_turnaround.png';
  static const mulgyeoriWaterTurnaround =
      'assets/images/characters/mulgyeori_water_turnaround.png';

  // --- 보너스 캐릭터 ---
  static const goldTokkiDefault =
      'assets/images/characters/gold_tokki_default.png';
  static const blackTokkiDefault =
      'assets/images/characters/black_tokki_default.png';
  static const namuriGirlfriendDefault =
      'assets/images/characters/namuri_girlfriend_default.png';

  // --- 오행별 기본 에셋 조회 ---

  /// FiveElementType → 기본 에셋 경로
  static String defaultFor(FiveElementType element) => switch (element) {
        FiveElementType.wood => namuriWoodDefault,
        FiveElementType.fire => bulkkoriFireDefault,
        FiveElementType.earth => heuksuniEarthDefault,
        FiveElementType.metal => soedongiMetalDefault,
        FiveElementType.water => mulgyeoriWaterDefault,
      };

  /// FiveElementType → 캐릭터 이름
  static String nameFor(FiveElementType element) => switch (element) {
        FiveElementType.wood => '나무리',
        FiveElementType.fire => '불꼬리',
        FiveElementType.earth => '흙순이',
        FiveElementType.metal => '쇠동이',
        FiveElementType.water => '물결이',
      };

  /// 오행 문자열(wood/목/木) → 기본 에셋 경로
  static String defaultForString(String element) => switch (element) {
        '목' || '木' || 'wood' => namuriWoodDefault,
        '화' || '火' || 'fire' => bulkkoriFireDefault,
        '토' || '土' || 'earth' => heuksuniEarthDefault,
        '금' || '金' || 'metal' => soedongiMetalDefault,
        '수' || '水' || 'water' => mulgyeoriWaterDefault,
        _ => namuriWoodDefault,
      };

  /// 오행 문자열(wood/목/木) → 캐릭터 이름
  static String nameForString(String element) => switch (element) {
        '목' || '木' || 'wood' => '나무리',
        '화' || '火' || 'fire' => '불꼬리',
        '토' || '土' || 'earth' => '흙순이',
        '금' || '金' || 'metal' => '쇠동이',
        '수' || '水' || 'water' => '물결이',
        _ => '나무리',
      };
}

/// RevenueCat 상품 ID
abstract final class RevenueCatProducts {
  // TODO: RevenueCat 대시보드에서 설정한 실제 ID로 교체
  static const monthlySubscription = 'saju_premium_monthly';
  static const yearlySubscription = 'saju_premium_yearly';
  static const superMatch = 'saju_super_match';
  static const detailedCompatibility = 'saju_detailed_compatibility';

  // Entitlement ID
  static const premiumEntitlement = 'premium';
}
