/// 매칭 Remote 데이터소스
///
/// Supabase DB 직접 쿼리 + Edge Functions를 통해 매칭 관련 데이터를 처리합니다.
/// - Edge Functions: 배치 궁합 계산, 일일 추천 생성
/// - DB 직접 쿼리: 추천 목록, 좋아요, 사진 열람, 포인트, 일일 사용량
///
/// 반환값은 모두 raw Map으로, Repository 레이어에서 Entity로 변환합니다.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';

// =============================================================================
// 테이블/함수명 상수
// =============================================================================

const _dailyMatchesTable = 'daily_matches';
const _profilesTable = SupabaseTables.profiles;
const _likesTable = SupabaseTables.likes;
const _compatibilityTable = SupabaseTables.sajuCompatibility;
const _userActionsTable = 'user_actions';
const _dailyUsageTable = SupabaseTables.dailyUsage;
const _userPointsTable = SupabaseTables.userPoints;
const _pointTransactionsTable = SupabaseTables.pointTransactions;
const _gwansangProfilesTable = SupabaseTables.gwansangProfiles;

// =============================================================================
// 매칭 Remote 데이터소스
// =============================================================================

/// Supabase 기반 매칭 데이터소스
///
/// [SupabaseHelper]를 통해 Edge Function을 호출하고,
/// [SupabaseClient]를 통해 복잡한 DB 쿼리를 수행합니다.
class MatchingRemoteDatasource {
  const MatchingRemoteDatasource({
    required SupabaseHelper supabaseHelper,
    required SupabaseClient supabaseClient,
  })  : _helper = supabaseHelper,
        _client = supabaseClient;

  final SupabaseHelper _helper;
  final SupabaseClient _client;

  // ===========================================================================
  // Edge Function 호출
  // ===========================================================================

  /// 배치 궁합 계산 트리거
  ///
  /// [userId]에 대해 후보 유저들과의 궁합을 일괄 계산합니다.
  /// Edge Function이 saju_compatibility 테이블에 결과를 저장합니다.
  ///
  /// 반환: Edge Function 응답 (계산된 궁합 수, 에러 등)
  Future<Map<String, dynamic>> triggerBatchCompatibility(String userId) async {
    final response = await _helper.invokeFunction(
      SupabaseFunctions.batchCalculateCompatibility,
      body: {'userId': userId},
      timeout: const Duration(seconds: 60),
    );

    if (response == null) {
      return {'calculated': 0};
    }
    return Map<String, dynamic>.from(response as Map);
  }

  /// 일일 추천 생성 트리거
  ///
  /// [userId]에 대해 오늘의 추천 목록을 생성합니다.
  /// [isInitial]이 true면 온보딩 직후 첫 추천 (5명)을 생성합니다.
  ///
  /// 반환: Edge Function 응답 (생성된 추천 수, 섹션별 분배 등)
  Future<Map<String, dynamic>> triggerDailyRecommendations(
    String userId, {
    bool isInitial = false,
  }) async {
    final response = await _helper.invokeFunction(
      SupabaseFunctions.generateDailyRecommendations,
      body: {
        'userId': userId,
        'isInitial': isInitial,
      },
      timeout: const Duration(seconds: 60),
    );

    if (response == null) {
      return {'generated': 0};
    }
    return Map<String, dynamic>.from(response as Map);
  }

  // ===========================================================================
  // 오늘의 추천 목록 조회
  // ===========================================================================

  /// 오늘의 추천 목록 조회 (daily_matches + profiles + gwansang_profiles)
  ///
  /// daily_matches에서 오늘 날짜의 추천을 가져오고,
  /// 추천 대상 프로필 + 관상 데이터를 배치 조회하여 합칩니다.
  ///
  /// 반환: 각 추천에 대한 raw Map 리스트
  ///   - daily_matches 필드: id, section, is_viewed, photo_revealed, recommended_id, compatibility_id
  ///   - profiles 필드: name, birth_date, gender, bio, profile_images, dominant_element, ...
  ///   - gwansang 필드: animal_type, animal_modifier, animal_type_korean, traits
  ///   - compatibility 필드: total_score, five_element_score, ...
  Future<List<Map<String, dynamic>>> fetchDailyRecommendations(
    String userId,
  ) async {
    // 1. 오늘의 daily_matches 조회
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final dailyMatches = await _client
        .from(_dailyMatchesTable)
        .select()
        .eq('user_id', userId)
        .eq('match_date', today)
        .order('created_at');

    if (dailyMatches.isEmpty) return [];

    // 2. 추천 대상 프로필 ID 추출
    final recommendedIds = dailyMatches
        .map((m) => m['recommended_id'] as String)
        .toSet()
        .toList();

    // 3. 프로필 배치 조회
    final profiles = await _client
        .from(_profilesTable)
        .select(
          'id, name, birth_date, gender, bio, profile_images, '
          'dominant_element, character_type, height, location, occupation, '
          'body_type, religion, is_phone_verified, animal_type',
        )
        .inFilter('id', recommendedIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profiles) {
      profileMap[p['id'] as String] = Map<String, dynamic>.from(p);
    }

    // 4. 관상 프로필 배치 조회 (있는 경우만)
    final gwansangProfiles = await _client
        .from(_gwansangProfilesTable)
        .select(
          'user_id, animal_type, animal_modifier, animal_type_korean, traits',
        )
        .inFilter('user_id', recommendedIds);

    final gwansangMap = <String, Map<String, dynamic>>{};
    for (final g in gwansangProfiles) {
      gwansangMap[g['user_id'] as String] = Map<String, dynamic>.from(g);
    }

    // 5. 궁합 점수 배치 조회 (compatibility_id가 있는 경우)
    final compatibilityIds = dailyMatches
        .where((m) => m['compatibility_id'] != null)
        .map((m) => m['compatibility_id'] as String)
        .toSet()
        .toList();

    final compatMap = <String, Map<String, dynamic>>{};
    if (compatibilityIds.isNotEmpty) {
      final compatRows = await _client
          .from(_compatibilityTable)
          .select()
          .inFilter('id', compatibilityIds);

      for (final c in compatRows) {
        compatMap[c['id'] as String] = Map<String, dynamic>.from(c);
      }
    }

    // 6. 결합: daily_match + profile + gwansang + compatibility
    final results = <Map<String, dynamic>>[];
    for (final match in dailyMatches) {
      final recommendedId = match['recommended_id'] as String;
      final compatId = match['compatibility_id'] as String?;

      results.add({
        // daily_matches 필드
        'match_id': match['id'],
        'section': match['section'] ?? 'compatibility',
        'is_viewed': match['is_viewed'] ?? false,
        'photo_revealed': match['photo_revealed'] ?? false,
        'match_date': match['match_date'],
        // 프로필 필드
        ...?profileMap[recommendedId],
        // 관상 필드 (prefix 붙여서 충돌 방지)
        if (gwansangMap.containsKey(recommendedId)) ...{
          'gwansang_animal_type':
              gwansangMap[recommendedId]!['animal_type'],
          'gwansang_animal_modifier':
              gwansangMap[recommendedId]!['animal_modifier'],
          'gwansang_animal_type_korean':
              gwansangMap[recommendedId]!['animal_type_korean'],
          'gwansang_traits': gwansangMap[recommendedId]!['traits'],
        },
        // 궁합 필드
        if (compatId != null && compatMap.containsKey(compatId)) ...{
          'compatibility_score':
              compatMap[compatId]!['total_score'] ?? 0,
          'five_element_score':
              compatMap[compatId]!['five_element_score'],
          'overall_analysis':
              compatMap[compatId]!['overall_analysis'],
          'strengths': compatMap[compatId]!['strengths'],
          'challenges': compatMap[compatId]!['challenges'],
          'advice': compatMap[compatId]!['advice'],
          'ai_story': compatMap[compatId]!['ai_story'],
        },
      });
    }

    return results;
  }

  // ===========================================================================
  // 궁합 점수
  // ===========================================================================

  /// 두 유저 간 궁합 점수 조회 (saju_compatibility 캐시)
  ///
  /// [userId]와 [partnerId] 간의 캐시된 궁합 결과를 반환합니다.
  /// 아직 계산되지 않았으면 null을 반환합니다.
  Future<Map<String, dynamic>?> fetchCompatibilityScore(
    String userId,
    String partnerId,
  ) async {
    final response = await _client
        .from(_compatibilityTable)
        .select()
        .eq('user_id', userId)
        .eq('partner_id', partnerId)
        .maybeSingle();

    return response;
  }

  // ===========================================================================
  // 사진 열람
  // ===========================================================================

  /// 사진 열람 기록
  ///
  /// 1. user_actions에 photo_reveal 기록 INSERT
  /// 2. daily_matches의 photo_revealed를 true로 UPDATE
  Future<void> recordPhotoReveal(
    String userId,
    String targetUserId,
    int pointsSpent,
  ) async {
    // 1. user_actions에 기록
    await _client.from(_userActionsTable).insert({
      'user_id': userId,
      'target_user_id': targetUserId,
      'action_type': 'photo_reveal',
      'points_spent': pointsSpent,
    });

    // 2. daily_matches의 photo_revealed 업데이트
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client
        .from(_dailyMatchesTable)
        .update({'photo_revealed': true})
        .eq('user_id', userId)
        .eq('recommended_id', targetUserId)
        .eq('match_date', today);
  }

  // ===========================================================================
  // 좋아요 관리
  // ===========================================================================

  /// 좋아요 전송 (likes UPSERT)
  ///
  /// 중복 방지: sender_id + receiver_id unique constraint.
  /// [isPremium]이 true면 프리미엄 좋아요 (눈에 띄는 표시).
  Future<void> sendLike(
    String senderId,
    String receiverId, {
    bool isPremium = false,
  }) async {
    await _client.from(_likesTable).upsert(
      {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'is_premium': isPremium,
        'status': 'pending',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'sender_id,receiver_id',
    );

    // user_actions에도 기록
    await _client.from(_userActionsTable).insert({
      'user_id': senderId,
      'target_user_id': receiverId,
      'action_type': isPremium ? 'premium_like' : 'like',
      'points_spent': isPremium ? AppLimits.premiumLikeCost : AppLimits.likeCost,
    });
  }

  /// 좋아요 수락
  ///
  /// likes 상태를 'accepted'로 변경하고 responded_at을 기록합니다.
  Future<void> acceptLike(String likeId) async {
    await _client.from(_likesTable).update({
      'status': 'accepted',
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', likeId);
  }

  /// 좋아요 거절
  ///
  /// likes 상태를 'rejected'로 변경하고 responded_at을 기록합니다.
  Future<void> rejectLike(String likeId) async {
    await _client.from(_likesTable).update({
      'status': 'rejected',
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', likeId);
  }

  /// 받은 좋아요 조회 (pending 상태만)
  ///
  /// likes JOIN profiles (sender 정보)를 가져옵니다.
  /// 반환: like 정보 + sender 프로필 맵 리스트
  Future<List<Map<String, dynamic>>> fetchReceivedLikes(String userId) async {
    // 1. 받은 좋아요 (pending) 조회
    final likes = await _client
        .from(_likesTable)
        .select()
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('sent_at', ascending: false);

    if (likes.isEmpty) return [];

    // 2. sender 프로필 배치 조회
    final senderIds =
        likes.map((l) => l['sender_id'] as String).toSet().toList();

    final senderProfiles = await _client
        .from(_profilesTable)
        .select(
          'id, name, birth_date, gender, bio, profile_images, '
          'dominant_element, character_type, height, location, occupation, '
          'body_type, religion, is_phone_verified, animal_type',
        )
        .inFilter('id', senderIds);

    final senderMap = <String, Map<String, dynamic>>{};
    for (final p in senderProfiles) {
      senderMap[p['id'] as String] = Map<String, dynamic>.from(p);
    }

    // 3. 결합
    return likes.map((like) {
      final senderId = like['sender_id'] as String;
      return {
        'like_id': like['id'],
        'is_premium': like['is_premium'] ?? false,
        'sent_at': like['sent_at'],
        ...?senderMap[senderId],
      };
    }).toList();
  }

  /// 보낸 좋아요 조회
  ///
  /// likes JOIN profiles (receiver 정보)를 가져옵니다.
  Future<List<Map<String, dynamic>>> fetchSentLikes(String userId) async {
    // 1. 보낸 좋아요 조회
    final likes = await _client
        .from(_likesTable)
        .select()
        .eq('sender_id', userId)
        .order('sent_at', ascending: false);

    if (likes.isEmpty) return [];

    // 2. receiver 프로필 배치 조회
    final receiverIds =
        likes.map((l) => l['receiver_id'] as String).toSet().toList();

    final receiverProfiles = await _client
        .from(_profilesTable)
        .select(
          'id, name, birth_date, gender, bio, profile_images, '
          'dominant_element, character_type, height, location, occupation, '
          'body_type, religion, is_phone_verified, animal_type',
        )
        .inFilter('id', receiverIds);

    final receiverMap = <String, Map<String, dynamic>>{};
    for (final p in receiverProfiles) {
      receiverMap[p['id'] as String] = Map<String, dynamic>.from(p);
    }

    // 3. 결합
    return likes.map((like) {
      final receiverId = like['receiver_id'] as String;
      return {
        'like_id': like['id'],
        'is_premium': like['is_premium'] ?? false,
        'status': like['status'],
        'sent_at': like['sent_at'],
        'responded_at': like['responded_at'],
        ...?receiverMap[receiverId],
      };
    }).toList();
  }

  // ===========================================================================
  // 일일 무료 사용량 (daily_usage)
  // ===========================================================================

  /// 오늘의 일일 사용량 조회 또는 생성
  ///
  /// daily_usage에서 오늘 날짜 레코드를 조회합니다.
  /// 없으면 새로 생성(INSERT)하여 반환합니다.
  ///
  /// 반환 Map 필드: id, user_id, usage_date,
  ///   free_likes_used, free_accepts_used, free_photo_reveals_used
  Future<Map<String, dynamic>> fetchOrCreateDailyUsage(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 오늘 레코드 조회
    final existing = await _client
        .from(_dailyUsageTable)
        .select()
        .eq('user_id', userId)
        .eq('usage_date', today)
        .maybeSingle();

    if (existing != null) {
      return Map<String, dynamic>.from(existing);
    }

    // 없으면 새로 생성 (upsert로 race condition 방지)
    final newRow = await _client
        .from(_dailyUsageTable)
        .upsert(
          {
            'user_id': userId,
            'usage_date': today,
            'free_likes_used': 0,
            'free_accepts_used': 0,
            'free_photo_reveals_used': 0,
          },
          onConflict: 'user_id,usage_date',
        )
        .select()
        .single();

    return Map<String, dynamic>.from(newRow);
  }

  /// 일일 무료 사용량 증가
  ///
  /// [usageId]: daily_usage 레코드 ID
  /// [like], [accept], [photoReveal]: 어느 항목을 +1 할지 지정
  Future<void> incrementDailyUsage(
    String usageId, {
    bool like = false,
    bool accept = false,
    bool photoReveal = false,
  }) async {
    // 현재값 조회
    final current = await _client
        .from(_dailyUsageTable)
        .select()
        .eq('id', usageId)
        .single();

    final updates = <String, dynamic>{};
    if (like) {
      updates['free_likes_used'] =
          (current['free_likes_used'] as int? ?? 0) + 1;
    }
    if (accept) {
      updates['free_accepts_used'] =
          (current['free_accepts_used'] as int? ?? 0) + 1;
    }
    if (photoReveal) {
      updates['free_photo_reveals_used'] =
          (current['free_photo_reveals_used'] as int? ?? 0) + 1;
    }

    if (updates.isNotEmpty) {
      await _client
          .from(_dailyUsageTable)
          .update(updates)
          .eq('id', usageId);
    }
  }

  // ===========================================================================
  // 포인트 관리
  // ===========================================================================

  /// 포인트 차감 + 거래 기록
  ///
  /// 1. user_points에서 balance 차감 + total_spent 증가
  /// 2. point_transactions에 거래 기록 INSERT
  ///
  /// [type]: 거래 유형 (like_sent, premium_like_sent, accept,
  ///         photo_reveal, compatibility_report 등)
  /// [targetId]: 대상 유저 ID (있는 경우)
  Future<void> spendPoints(
    String userId,
    int amount,
    String type, {
    String? targetId,
  }) async {
    // 1. 현재 포인트 잔액 조회
    final pointsRow = await _client
        .from(_userPointsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (pointsRow == null) {
      // 포인트 레코드가 없으면 생성 (초기 잔액 0)
      await _client.from(_userPointsTable).insert({
        'user_id': userId,
        'balance': 0,
        'total_earned': 0,
        'total_spent': amount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      final currentBalance = pointsRow['balance'] as int? ?? 0;
      final currentSpent = pointsRow['total_spent'] as int? ?? 0;

      await _client.from(_userPointsTable).update({
        'balance': currentBalance - amount,
        'total_spent': currentSpent + amount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId);
    }

    // 2. 거래 기록 INSERT
    final txData = <String, dynamic>{
      'user_id': userId,
      'type': type,
      'amount': -amount, // 차감이므로 음수
      'description': _transactionDescription(type, amount),
    };
    if (targetId != null) {
      txData['target_id'] = targetId;
    }
    await _client.from(_pointTransactionsTable).insert(txData);
  }

  /// 거래 유형에 따른 설명 텍스트 생성
  String _transactionDescription(String type, int amount) {
    return switch (type) {
      'like_sent' => '좋아요 전송 (-$amount P)',
      'premium_like_sent' => '프리미엄 좋아요 전송 (-$amount P)',
      'accept' => '좋아요 수락 (-$amount P)',
      'photo_reveal' => '사진 열람 (-$amount P)',
      'compatibility_report' => '상세 궁합 리포트 (-$amount P)',
      'saju_report' => '상세 사주 리포트 (-$amount P)',
      'icebreaker' => '아이스브레이커 (-$amount P)',
      _ => '포인트 사용 (-$amount P)',
    };
  }

  // ===========================================================================
  // 유틸리티
  // ===========================================================================

  /// daily_matches의 is_viewed를 true로 업데이트
  Future<void> markAsViewed(String matchId) async {
    await _client
        .from(_dailyMatchesTable)
        .update({'is_viewed': true})
        .eq('id', matchId);
  }

  /// 유저 포인트 잔액 조회
  ///
  /// 반환: 포인트 잔액 (레코드가 없으면 0)
  Future<int> fetchPointBalance(String userId) async {
    final row = await _client
        .from(_userPointsTable)
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();

    return (row?['balance'] as int?) ?? 0;
  }
}
