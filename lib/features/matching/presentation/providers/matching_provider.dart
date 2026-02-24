/// 매칭 기능 Riverpod Providers
///
/// 매칭 기능의 DI(의존성 주입)와 상태 관리를 담당합니다.
///
/// Provider 구성:
/// - [matchingRepositoryProvider]: Mock Repository 인스턴스
/// - [DailyRecommendations]: 오늘의 추천 프로필 목록 (AsyncNotifier)
/// - [CompatibilityPreview]: 궁합 프리뷰 상태 관리 (AsyncNotifier)
/// - [ReceivedLikes]: 받은 좋아요 목록 (AsyncNotifier)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/match_profile_model.dart';
import '../../data/repositories/matching_repository_impl.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../../saju/domain/entities/saju_entity.dart';

part 'matching_provider.g.dart';

// =============================================================================
// Repository Provider
// =============================================================================

/// 매칭 Repository Provider
///
/// 현재는 Mock 구현체를 반환합니다.
/// Supabase 연동 후 실제 구현체로 교체합니다.
@riverpod
MatchingRepository matchingRepository(Ref ref) {
  return MockMatchingRepository();
}

// =============================================================================
// 오늘의 추천 (Daily Recommendations)
// =============================================================================

/// 오늘의 매칭 추천 목록 상태 관리
///
/// 상태:
/// - `AsyncLoading`: 추천 목록 로딩 중
/// - `AsyncData([...])`: 추천 목록 로드 완료
/// - `AsyncError`: 로드 실패
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
// 궁합 프리뷰 (Compatibility Preview)
// =============================================================================

/// 궁합 프리뷰 상태 관리
///
/// 특정 상대와의 궁합을 조회합니다.
/// 초기 상태는 null이며, [loadPreview] 호출 시 데이터를 로드합니다.
///
/// 상태:
/// - `AsyncData(null)`: 아직 조회하지 않음
/// - `AsyncLoading`: 궁합 분석 중
/// - `AsyncData(compatibility)`: 분석 완료
/// - `AsyncError`: 분석 실패
@riverpod
class CompatibilityPreview extends _$CompatibilityPreview {
  @override
  Future<Compatibility?> build() async {
    return null;
  }

  /// 상대방과의 궁합 프리뷰 로드
  ///
  /// [partnerId]: 궁합을 조회할 상대 사용자 ID
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
///
/// 현재 사용자가 받은 pending 상태의 좋아요 목록을 관리합니다.
///
/// 상태:
/// - `AsyncLoading`: 목록 로딩 중
/// - `AsyncData([...])`: 로드 완료
/// - `AsyncError`: 로드 실패
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
