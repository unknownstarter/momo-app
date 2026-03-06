/// 매칭 Repository 구현체
///
/// Supabase DB + Edge Functions를 통해 실제 매칭 데이터를 처리합니다.
/// [MatchingRemoteDatasource]가 raw Map을 반환하면,
/// 이 Repository에서 도메인 Entity로 변환합니다.
library;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/compatibility_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/daily_recommendation.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/match_profile.dart';
import '../../domain/entities/sent_like.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../saju/domain/repositories/saju_repository.dart';
import '../datasources/matching_remote_datasource.dart';

// =============================================================================
// 실구현 (Supabase 연동)
// =============================================================================

/// 매칭 Repository 실구현
///
/// [MatchingRemoteDatasource]를 통해 Supabase DB/Edge Functions에 접근하고,
/// raw Map 결과를 도메인 Entity로 변환합니다.
class MatchingRepositoryImpl implements MatchingRepository {
  const MatchingRepositoryImpl({
    required AuthRepository authRepository,
    required SajuRepository sajuRepository,
    required SupabaseHelper supabaseHelper,
    required MatchingRemoteDatasource remoteDatasource,
  })  : _authRepository = authRepository,
        _sajuRepository = sajuRepository,
        _supabaseHelper = supabaseHelper,
        _remoteDatasource = remoteDatasource;

  final AuthRepository _authRepository;
  final SajuRepository _sajuRepository;
  final SupabaseHelper _supabaseHelper;
  final MatchingRemoteDatasource _remoteDatasource;

  // ===========================================================================
  // 현재 유저 ID 헬퍼
  // ===========================================================================

  /// 현재 로그인된 유저의 profiles.id를 반환합니다.
  /// 로그인되어 있지 않거나 프로필이 없으면 예외를 던집니다.
  Future<String> _getCurrentUserId() async {
    final profile = await _authRepository.getCurrentUserProfile();
    if (profile == null) {
      throw Exception(MatchingFailure.sajuRequired().message);
    }
    return profile.id;
  }

  // ===========================================================================
  // 추천 목록
  // ===========================================================================

  @override
  Future<List<MatchProfile>> getDailyRecommendations() async {
    final userId = await _getCurrentUserId();
    final rawList = await _remoteDatasource.fetchDailyRecommendations(userId);

    if (rawList.isEmpty) return [];

    return rawList
        .map(_mapToMatchProfile)
        .toList()
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
  }

  @override
  Future<SectionedRecommendations> getSectionedRecommendations() async {
    final userId = await _getCurrentUserId();
    final rawList = await _remoteDatasource.fetchDailyRecommendations(userId);

    if (rawList.isEmpty) return const SectionedRecommendations();

    final destinyMatches = <MatchProfile>[];
    final compatibilityMatches = <MatchProfile>[];
    final gwansangMatches = <MatchProfile>[];
    final newUserMatches = <MatchProfile>[];

    for (final raw in rawList) {
      final profile = _mapToMatchProfile(raw);
      final section = raw['section'] as String? ?? 'compatibility';

      switch (section) {
        case 'destiny':
          destinyMatches.add(profile);
        case 'gwansang':
          gwansangMatches.add(profile);
        case 'new_user':
          newUserMatches.add(profile);
        case 'compatibility':
        default:
          compatibilityMatches.add(profile);
      }
    }

    return SectionedRecommendations(
      destinyMatches: destinyMatches,
      compatibilityMatches: compatibilityMatches,
      gwansangMatches: gwansangMatches,
      newUserMatches: newUserMatches,
    );
  }

  // ===========================================================================
  // 궁합 프리뷰
  // ===========================================================================

  @override
  Future<Compatibility> getCompatibilityPreview(String partnerId) async {
    final userId = await _getCurrentUserId();

    // 1. DB 캐시에서 먼저 조회
    final cached = await _remoteDatasource.fetchCompatibilityScore(
      userId,
      partnerId,
    );

    if (cached != null) {
      return _mapToCompatibility(cached, userId, partnerId);
    }

    // 2. 캐시 없으면 Edge Function으로 실시간 계산
    final mySaju = await _sajuRepository.getSajuForCompatibility(userId);
    final partnerSaju =
        await _sajuRepository.getSajuForCompatibility(partnerId);
    if (mySaju == null || partnerSaju == null) {
      throw Exception(MatchingFailure.sajuRequired().message);
    }

    final body = <String, dynamic>{
      'mySaju': mySaju,
      'partnerSaju': partnerSaju,
    };
    final response = await _supabaseHelper.invokeFunction(
      SupabaseFunctions.calculateCompatibility,
      body: body,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception('궁합 계산 결과가 비어있습니다.');
    }

    final map = Map<String, dynamic>.from(response);
    final calculatedAt = DateTime.tryParse(
          map['calculatedAt'] as String? ?? '',
        ) ??
        DateTime.now();
    return Compatibility(
      id: 'compat-$partnerId-${calculatedAt.millisecondsSinceEpoch}',
      userId: userId,
      partnerId: partnerId,
      score: (map['score'] as num?)?.toInt() ?? 0,
      fiveElementScore: (map['fiveElementScore'] as num?)?.toInt(),
      dayPillarScore: (map['dayPillarScore'] as num?)?.toInt(),
      overallAnalysis: map['overallAnalysis'] as String?,
      strengths: List<String>.from(map['strengths'] ?? []),
      challenges: List<String>.from(map['challenges'] ?? []),
      advice: map['advice'] as String?,
      aiStory: map['aiStory'] as String?,
      calculatedAt: calculatedAt,
    );
  }

  // ===========================================================================
  // 좋아요
  // ===========================================================================

  @override
  Future<void> sendLike(String receiverId, {bool isPremium = false}) async {
    final userId = await _getCurrentUserId();
    await _remoteDatasource.sendLike(
      userId,
      receiverId,
      isPremium: isPremium,
    );
  }

  @override
  Future<void> acceptLike(String likeId) async {
    await _remoteDatasource.acceptLike(likeId);
  }

  @override
  Future<void> rejectLike(String likeId) async {
    await _remoteDatasource.rejectLike(likeId);
  }

  @override
  Future<List<Like>> getReceivedLikes() async {
    final userId = await _getCurrentUserId();
    final rawList = await _remoteDatasource.fetchReceivedLikes(userId);

    return rawList.map((raw) {
      return Like(
        id: raw['like_id'] as String? ?? '',
        senderId: raw['id'] as String? ?? '',
        receiverId: userId,
        isPremium: raw['is_premium'] as bool? ?? false,
        status: LikeStatus.pending,
        sentAt: DateTime.tryParse(raw['sent_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<List<SentLike>> getSentLikes() async {
    final userId = await _getCurrentUserId();
    final rawList = await _remoteDatasource.fetchSentLikes(userId);

    return rawList.map((raw) {
      final receiverId = raw['id'] as String? ?? '';
      final statusStr = raw['status'] as String? ?? 'pending';
      final status = _parseLikeStatus(statusStr);

      final like = Like(
        id: raw['like_id'] as String? ?? '',
        senderId: userId,
        receiverId: receiverId,
        isPremium: raw['is_premium'] as bool? ?? false,
        status: status,
        sentAt: DateTime.tryParse(raw['sent_at'] as String? ?? '') ??
            DateTime.now(),
        respondedAt: raw['responded_at'] != null
            ? DateTime.tryParse(raw['responded_at'] as String)
            : null,
      );

      final profile = _mapToMatchProfile(raw);

      return SentLike(like: like, profile: profile);
    }).toList();
  }

  @override
  Future<List<Match>> getActiveMatches() async {
    // TODO: active matches 쿼리 추가 시 실구현 전환
    // 현재 datasource에 fetchActiveMatches가 없으므로 빈 리스트 반환
    return [];
  }

  @override
  Future<List<({Like like, MatchProfile profile})>>
      getReceivedLikesWithProfiles() async {
    final userId = await _getCurrentUserId();
    final rawList = await _remoteDatasource.fetchReceivedLikes(userId);

    return rawList.map((raw) {
      final like = Like(
        id: raw['like_id'] as String? ?? '',
        senderId: raw['id'] as String? ?? '',
        receiverId: userId,
        isPremium: raw['is_premium'] as bool? ?? false,
        status: LikeStatus.pending,
        sentAt: DateTime.tryParse(raw['sent_at'] as String? ?? '') ??
            DateTime.now(),
      );

      final profile = _mapToMatchProfile(raw);

      return (like: like, profile: profile);
    }).toList();
  }

  // ===========================================================================
  // 배치 궁합 / 일일 추천 트리거
  // ===========================================================================

  @override
  Future<void> triggerBatchCompatibility() async {
    final userId = await _getCurrentUserId();
    await _remoteDatasource.triggerBatchCompatibility(userId);
  }

  @override
  Future<void> ensureDailyRecommendations({bool isInitial = false}) async {
    final userId = await _getCurrentUserId();
    await _remoteDatasource.triggerDailyRecommendations(
      userId,
      isInitial: isInitial,
    );
  }

  // ===========================================================================
  // 사진 열람
  // ===========================================================================

  @override
  Future<void> revealPhoto(
    String targetUserId, {
    required int pointsSpent,
  }) async {
    final userId = await _getCurrentUserId();
    await _remoteDatasource.recordPhotoReveal(userId, targetUserId, pointsSpent);
  }

  // ===========================================================================
  // Map → Entity 변환 헬퍼
  // ===========================================================================

  /// raw Map → MatchProfile 변환
  ///
  /// daily_matches + profiles + gwansang + compatibility가 결합된 맵에서
  /// MatchProfile 도메인 엔티티를 생성합니다.
  MatchProfile _mapToMatchProfile(Map<String, dynamic> raw) {
    final userId = (raw['recommended_id'] as String?) ??
        (raw['id'] as String?) ??
        '';
    final name = raw['name'] as String? ?? '익명';
    final birthDateStr = raw['birth_date'] as String?;
    final age = _calculateAge(birthDateStr);
    final bio = raw['bio'] as String? ?? '';
    final dominantElement = raw['dominant_element'] as String? ?? 'wood';
    final characterType = raw['character_type'] as String?;

    // 프로필 이미지
    final profileImages = raw['profile_images'];
    String? photoUrl;
    if (profileImages is List && profileImages.isNotEmpty) {
      photoUrl = profileImages.first as String?;
    }

    // 캐릭터 에셋
    final characterAssetPath =
        CharacterAssets.defaultForString(characterType ?? dominantElement);
    final characterName =
        CharacterAssets.nameForString(characterType ?? dominantElement);

    // 관상 데이터
    final animalType = raw['gwansang_animal_type'] as String? ??
        raw['animal_type'] as String?;
    final animalModifier = raw['gwansang_animal_modifier'] as String?;
    final animalTypeKorean = raw['gwansang_animal_type_korean'] as String?;

    Map<String, int>? gwansangTraits;
    final rawTraits = raw['gwansang_traits'];
    if (rawTraits is Map) {
      gwansangTraits = <String, int>{};
      for (final entry in rawTraits.entries) {
        gwansangTraits[entry.key.toString()] =
            (entry.value as num?)?.toInt() ?? 0;
      }
    }

    // 궁합 점수
    final compatibilityScore =
        (raw['compatibility_score'] as num?)?.toInt() ?? 0;

    return MatchProfile(
      userId: userId,
      name: name,
      age: age,
      bio: bio,
      photoUrl: photoUrl,
      characterName: characterName,
      characterAssetPath: characterAssetPath,
      elementType: dominantElement,
      compatibilityScore: compatibilityScore,
      animalType: animalType,
      animalModifier: animalModifier,
      animalTypeKorean: animalTypeKorean,
      gwansangTraits: gwansangTraits,
      height: (raw['height'] as num?)?.toInt(),
      location: raw['location'] as String?,
      occupation: raw['occupation'] as String?,
      bodyType: raw['body_type'] as String?,
      religion: raw['religion'] as String?,
      isPhoneVerified: raw['is_phone_verified'] as bool? ?? false,
    );
  }

  /// raw Map → Compatibility 변환
  Compatibility _mapToCompatibility(
    Map<String, dynamic> raw,
    String userId,
    String partnerId,
  ) {
    final calculatedAt = DateTime.tryParse(
          raw['calculated_at'] as String? ??
              raw['created_at'] as String? ??
              '',
        ) ??
        DateTime.now();

    // strengths/challenges는 List<dynamic> 또는 null일 수 있음
    final rawStrengths = raw['strengths'];
    final strengths = rawStrengths is List
        ? rawStrengths.map((e) => e.toString()).toList()
        : <String>[];

    final rawChallenges = raw['challenges'];
    final challenges = rawChallenges is List
        ? rawChallenges.map((e) => e.toString()).toList()
        : <String>[];

    return Compatibility(
      id: raw['id'] as String? ??
          'compat-$partnerId-${calculatedAt.millisecondsSinceEpoch}',
      userId: userId,
      partnerId: partnerId,
      score: (raw['total_score'] as num?)?.toInt() ??
          (raw['score'] as num?)?.toInt() ??
          0,
      fiveElementScore: (raw['five_element_score'] as num?)?.toInt(),
      dayPillarScore: (raw['day_pillar_score'] as num?)?.toInt(),
      overallAnalysis: raw['overall_analysis'] as String?,
      strengths: strengths,
      challenges: challenges,
      advice: raw['advice'] as String?,
      aiStory: raw['ai_story'] as String?,
      calculatedAt: calculatedAt,
    );
  }

  /// 생년월일 문자열에서 만 나이 계산
  int _calculateAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return 0;
    final birthDate = DateTime.tryParse(birthDateStr);
    if (birthDate == null) return 0;

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.clamp(0, 150);
  }

  /// 문자열 → LikeStatus 변환
  LikeStatus _parseLikeStatus(String status) {
    return switch (status) {
      'pending' => LikeStatus.pending,
      'accepted' => LikeStatus.accepted,
      'rejected' => LikeStatus.rejected,
      'expired' => LikeStatus.expired,
      _ => LikeStatus.pending,
    };
  }
}

// =============================================================================
// @deprecated Mock Repository (Task 12에서 제거 예정)
// =============================================================================

/// @deprecated Mock 매칭 Repository — 실구현으로 전환 완료
///
/// 하드코딩된 데이터를 반환합니다.
/// Task 12 (Final Integration & Cleanup)에서 제거됩니다.
@Deprecated('실구현으로 전환 완료. Task 12에서 제거 예정')
class MockMatchingRepository implements MatchingRepository {
  @override
  Future<List<MatchProfile>> getDailyRecommendations() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return [];
  }

  @override
  Future<Compatibility> getCompatibilityPreview(String partnerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return Compatibility(
      id: 'mock-compat-$partnerId',
      userId: 'mock-user',
      partnerId: partnerId,
      score: 75,
      strengths: ['Mock 강점'],
      challenges: ['Mock 도전'],
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendLike(String receiverId, {bool isPremium = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> acceptLike(String likeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> rejectLike(String likeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Like>> getReceivedLikes() async {
    return [];
  }

  @override
  Future<List<SentLike>> getSentLikes() async {
    return [];
  }

  @override
  Future<List<Match>> getActiveMatches() async {
    return [];
  }

  @override
  Future<List<({Like like, MatchProfile profile})>>
      getReceivedLikesWithProfiles() async {
    return [];
  }

  @override
  Future<void> triggerBatchCompatibility() async {}

  @override
  Future<void> ensureDailyRecommendations({bool isInitial = false}) async {}

  @override
  Future<SectionedRecommendations> getSectionedRecommendations() async {
    return const SectionedRecommendations();
  }

  @override
  Future<void> revealPhoto(
    String targetUserId, {
    required int pointsSpent,
  }) async {}
}
