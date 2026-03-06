/// 매칭 Repository 인터페이스
///
/// 매칭 기능의 데이터 접근을 추상화합니다.
/// 도메인 레이어는 이 인터페이스에만 의존하며,
/// 실제 구현은 data 레이어에서 제공합니다.
library;

import '../../../../core/domain/entities/compatibility_entity.dart';
import '../entities/daily_recommendation.dart';
import '../entities/like_entity.dart';
import '../entities/match_entity.dart';
import '../entities/match_profile.dart';
import '../entities/sent_like.dart';

abstract class MatchingRepository {
  /// 오늘의 매칭 추천 목록 조회
  ///
  /// 사주 궁합 기반으로 추천된 프로필 목록을 반환합니다.
  /// 궁합 점수 내림차순으로 정렬됩니다.
  Future<List<MatchProfile>> getDailyRecommendations();

  /// 상대방과의 궁합 프리뷰 조회
  ///
  /// [partnerId]에 해당하는 사용자와의 궁합을 간략히 분석합니다.
  /// 프리미엄 상세 분석과 달리 기본 점수와 강점/약점만 포함됩니다.
  Future<Compatibility> getCompatibilityPreview(String partnerId);

  /// 좋아요 보내기
  ///
  /// [receiverId]에게 좋아요를 보냅니다.
  /// [isPremium]이 true이면 프리미엄 좋아요 (상대에게 즉시 노출).
  Future<void> sendLike(String receiverId, {bool isPremium = false});

  /// 좋아요 수락
  ///
  /// [likeId]에 해당하는 좋아요를 수락하여 매칭을 성사시킵니다.
  Future<void> acceptLike(String likeId);

  /// 좋아요 거절
  ///
  /// [likeId]에 해당하는 좋아요를 거절합니다.
  Future<void> rejectLike(String likeId);

  /// 받은 좋아요 목록 조회
  ///
  /// 현재 사용자가 받은 좋아요 중 아직 응답하지 않은 것들을 반환합니다.
  Future<List<Like>> getReceivedLikes();

  /// 보낸 좋아요 목록 조회 (프로필 포함)
  ///
  /// 내가 보낸 좋아요와 대상 프로필 정보를 함께 반환합니다.
  Future<List<SentLike>> getSentLikes();

  /// 활성 매칭 목록 조회
  ///
  /// 상호 좋아요가 성사된 활성 매칭 목록을 반환합니다.
  Future<List<Match>> getActiveMatches();

  /// 받은 좋아요 + 프로필 정보 함께 조회
  ///
  /// 받은 좋아요 목록과 해당 유저의 프로필을 함께 반환합니다.
  Future<List<({Like like, MatchProfile profile})>> getReceivedLikesWithProfiles();

  /// 배치 궁합 계산 트리거
  ///
  /// 현재 유저에 대해 후보 유저들과의 궁합을 일괄 계산합니다.
  /// Edge Function이 saju_compatibility 테이블에 결과를 저장합니다.
  Future<void> triggerBatchCompatibility();

  /// 일일 추천 생성 (필요 시)
  ///
  /// 오늘의 추천 목록이 없으면 생성합니다.
  /// [isInitial]이 true면 온보딩 직후 첫 추천 (5명)을 생성합니다.
  Future<void> ensureDailyRecommendations({bool isInitial = false});

  /// 섹션별 일일 추천 조회
  ///
  /// 운명의 매칭, 궁합 매칭, 관상 매칭, 신규 유저 등
  /// 섹션별로 분류된 추천 목록을 반환합니다.
  Future<SectionedRecommendations> getSectionedRecommendations();

  /// 사진 열람
  ///
  /// [targetUserId]의 사진을 열람 처리하고 포인트를 차감합니다.
  Future<void> revealPhoto(String targetUserId, {required int pointsSpent});
}
