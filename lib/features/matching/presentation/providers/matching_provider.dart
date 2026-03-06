/// 매칭 기능 Riverpod Providers
///
/// 매칭 기능의 상태 관리를 담당합니다.
/// DI(의존성 주입)는 core/di/providers.dart에서 처리합니다.
///
/// Provider 구성:
/// - [DailyRecommendations]: 오늘의 추천 프로필 목록 (AsyncNotifier)
/// - [SectionedRecommendationsNotifier]: 섹션별 추천 (운명/궁합/관상/신규) (AsyncNotifier)
/// - [PhotoRevealNotifier]: 사진 열람 (무료→포인트 차감) (Notifier)
/// - [CompatibilityPreview]: 궁합 프리뷰 상태 관리 (AsyncNotifier)
/// - [ReceivedLikes]: 받은 좋아요 목록 (AsyncNotifier)
/// - [SentLikes]: 보낸 좋아요 목록 (AsyncNotifier)
/// - [ActiveMatches]: 활성 매칭 목록 (AsyncNotifier)
/// - [ReceivedLikesWithProfiles]: 받은 좋아요 + 프로필 (AsyncNotifier)
/// - [matchingTabSegmentProvider]: UI 세그먼트 상태 (StateProvider)
/// - [activeMatchIdsProvider]: 매칭 확정 유저 ID Set
/// - [filteredRecommendationsProvider]: 중복 제거된 추천
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/domain/entities/compatibility_entity.dart';
import '../../../points/presentation/providers/points_provider.dart';
import '../../domain/entities/daily_recommendation.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/match_profile.dart';
import '../../domain/entities/sent_like.dart';

part 'matching_provider.g.dart';

// =============================================================================
// 오늘의 추천 (Daily Recommendations)
// =============================================================================

/// 오늘의 매칭 추천 목록 상태 관리
@riverpod
class DailyRecommendations extends _$DailyRecommendations {
  @override
  Future<List<MatchProfile>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.getDailyRecommendations();
  }

  /// 추천 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchingRepositoryProvider).getDailyRecommendations(),
    );
  }
}

// =============================================================================
// 섹션별 추천 (Sectioned Recommendations)
// =============================================================================

/// 섹션별 추천 Provider
///
/// 홈 화면에서 사용. 앱 진입 시 일일 추천을 확인하고,
/// 없으면 Edge Function으로 생성 후 조회.
///
/// 섹션:
/// - 운명의 매칭 (궁합 85+ 또는 일주 합)
/// - 궁합 매칭 (궁합 점수 상위)
/// - 관상 매칭 (관상 traits 유사도 기반)
/// - 신규 유저 (최근 가입자)
@riverpod
class SectionedRecommendationsNotifier
    extends _$SectionedRecommendationsNotifier {
  @override
  Future<SectionedRecommendations> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    await repo.ensureDailyRecommendations();
    return repo.getSectionedRecommendations();
  }

  /// 추천 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(matchingRepositoryProvider);
      await repo.ensureDailyRecommendations();
      return repo.getSectionedRecommendations();
    });
  }
}

// =============================================================================
// 사진 열람 (Photo Reveal)
// =============================================================================

/// 사진 열람 Provider
///
/// 무료 한도(3회/일) 확인 → 포인트 차감 순서로 사진 열람 처리.
///
/// 상태:
/// - `AsyncData(null)`: 대기 중
/// - `AsyncLoading`: 열람 처리 중
/// - `AsyncError`: 열람 실패 (포인트 부족 등)
@riverpod
class PhotoRevealNotifier extends _$PhotoRevealNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 사진 열람 (무료 → 포인트 차감)
  ///
  /// [targetUserId]: 사진을 열람할 대상 유저 ID
  ///
  /// 반환값: 열람 성공 여부
  /// - true: 열람 성공 (무료 또는 포인트 차감)
  /// - false: 열람 실패 (포인트 부족 등)
  Future<bool> revealPhoto(String targetUserId) async {
    final dailyUsage = ref.read(dailyUsageNotifierProvider);
    final userPoints = ref.read(userPointsNotifierProvider);

    // 1단계: 무료 한도 확인
    if (dailyUsage.hasFreePhotoReveals) {
      state = const AsyncLoading();
      try {
        await ref.read(matchingRepositoryProvider).revealPhoto(
              targetUserId,
              pointsSpent: 0,
            );
        ref.read(dailyUsageNotifierProvider.notifier).useFreePhotoReveal();
        state = const AsyncData(null);
        return true;
      } catch (e, st) {
        state = AsyncError(e, st);
        return false;
      }
    }

    // 2단계: 포인트 확인
    const cost = AppLimits.photoRevealCost;
    if (!userPoints.canAfford(cost)) {
      state = AsyncError(
        '포인트가 부족해요 (${cost}P 필요)',
        StackTrace.current,
      );
      return false;
    }

    // 3단계: 포인트 차감 후 열람
    state = const AsyncLoading();
    try {
      await ref.read(matchingRepositoryProvider).revealPhoto(
            targetUserId,
            pointsSpent: cost,
          );
      ref.read(userPointsNotifierProvider.notifier).spend(cost);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// =============================================================================
// 궁합 프리뷰 (Compatibility Preview)
// =============================================================================

/// 궁합 프리뷰 상태 관리
@riverpod
class CompatibilityPreview extends _$CompatibilityPreview {
  @override
  Future<Compatibility?> build() async {
    return null;
  }

  /// 상대방과의 궁합 프리뷰 로드
  Future<void> loadPreview(String partnerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(matchingRepositoryProvider)
          .getCompatibilityPreview(partnerId),
    );
  }

  /// 프리뷰 초기화
  void reset() {
    state = const AsyncData(null);
  }
}

// =============================================================================
// 받은 좋아요 (Received Likes)
// =============================================================================

/// 받은 좋아요 목록 상태 관리
@riverpod
class ReceivedLikes extends _$ReceivedLikes {
  @override
  Future<List<Like>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.getReceivedLikes();
  }

  /// 좋아요 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchingRepositoryProvider).getReceivedLikes(),
    );
  }
}

// =============================================================================
// 보낸 좋아요 (Sent Likes)
// =============================================================================

/// 보낸 좋아요 목록 상태 관리
@riverpod
class SentLikes extends _$SentLikes {
  @override
  Future<List<SentLike>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.getSentLikes();
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchingRepositoryProvider).getSentLikes(),
    );
  }
}

// =============================================================================
// 활성 매칭 (Active Matches)
// =============================================================================

/// 활성 매칭 목록 상태 관리
@riverpod
class ActiveMatches extends _$ActiveMatches {
  @override
  Future<List<Match>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.getActiveMatches();
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchingRepositoryProvider).getActiveMatches(),
    );
  }
}

// =============================================================================
// 받은 좋아요 + 프로필 (Received Likes With Profiles)
// =============================================================================

/// 받은 좋아요 + 프로필 정보 함께 관리
@riverpod
class ReceivedLikesWithProfiles extends _$ReceivedLikesWithProfiles {
  @override
  Future<List<({Like like, MatchProfile profile})>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.getReceivedLikesWithProfiles();
  }

  /// 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchingRepositoryProvider).getReceivedLikesWithProfiles(),
    );
  }
}

// =============================================================================
// 파생 Provider들 (중복 제거, 세그먼트 상태 등)
// =============================================================================

/// 매칭 탭 세그먼트 인덱스 (0: 추천, 1: 보낸, 2: 받은)
final matchingTabSegmentProvider = StateProvider<int>((ref) => 0);

/// 매칭 확정 유저 ID Set — 추천/보낸/받은에서 중복 제거에 사용
final activeMatchIdsProvider = Provider<Set<String>>((ref) {
  final matches = ref.watch(activeMatchesProvider).valueOrNull ?? [];
  return matches
      .where((m) => m.isActive)
      .expand((m) => [m.user1Id, m.user2Id])
      .toSet();
});

/// 중복 제거된 추천 목록
///
/// 보낸 좋아요 + 받은 좋아요 + 활성 매칭 유저를 추천에서 제거
final filteredRecommendationsProvider =
    Provider<AsyncValue<List<MatchProfile>>>((ref) {
  final recommendations = ref.watch(dailyRecommendationsProvider);
  final sentLikes = ref.watch(sentLikesProvider).valueOrNull ?? [];
  final receivedLikes = ref.watch(receivedLikesProvider).valueOrNull ?? [];
  final matchIds = ref.watch(activeMatchIdsProvider);

  return recommendations.whenData((profiles) {
    final sentUserIds = sentLikes.map((s) => s.profile.userId).toSet();
    final receivedUserIds = receivedLikes.map((l) => l.senderId).toSet();
    final excludeIds = {...sentUserIds, ...receivedUserIds, ...matchIds};

    return profiles
        .where((p) => !excludeIds.contains(p.userId))
        .toList();
  });
});
