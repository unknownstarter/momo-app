/// 매칭 기능 Riverpod Providers
///
/// 매칭 기능의 상태 관리를 담당합니다.
/// DI(의존성 주입)는 core/di/providers.dart에서 처리합니다.
///
/// Provider 구성:
/// - [DailyRecommendations]: 오늘의 추천 프로필 목록 (AsyncNotifier)
/// - [CompatibilityPreview]: 궁합 프리뷰 상태 관리 (AsyncNotifier)
/// - [ReceivedLikes]: 받은 좋아요 목록 (AsyncNotifier)
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/entities/match_profile.dart';
import '../../../saju/domain/entities/saju_entity.dart';

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
