/// 포인트/좋아요 Riverpod Providers
///
/// 포인트 잔액, 일일 무료 사용량, 좋아요 전송 로직을 담당합니다.
///
/// Provider 구성:
/// - [UserPointsNotifier]: 포인트 잔액 상태 관리 (Mock: 500P 시작)
/// - [DailyUsageNotifier]: 일일 무료 좋아요/수락 사용량
/// - [SendLikeNotifier]: 좋아요 전송 비즈니스 로직 (무료→포인트 차감 순서)
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/point_entity.dart';

part 'points_provider.g.dart';

// =============================================================================
// 포인트 잔액 (UserPoints)
// =============================================================================

/// 포인트 잔액 Provider (Mock: 500P로 시작)
///
/// 상태:
/// - [UserPoints]: 현재 포인트 잔액, 총 획득, 총 사용
///
/// 주요 메서드:
/// - [spend]: 포인트 차감
/// - [earn]: 포인트 충전
@riverpod
class UserPointsNotifier extends _$UserPointsNotifier {
  @override
  UserPoints build() {
    return const UserPoints(
      userId: 'mock-user',
      balance: 500,
      totalEarned: 500,
      totalSpent: 0,
    );
  }

  /// 포인트 차감
  ///
  /// [amount]만큼 포인트를 차감합니다.
  /// 사전에 [UserPoints.canAfford]로 잔액을 확인해야 합니다.
  void spend(int amount) {
    final current = state;
    state = current.copyWith(
      balance: current.balance - amount,
      totalSpent: current.totalSpent + amount,
    );
  }

  /// 포인트 충전
  ///
  /// [amount]만큼 포인트를 충전합니다.
  void earn(int amount) {
    final current = state;
    state = current.copyWith(
      balance: current.balance + amount,
      totalEarned: current.totalEarned + amount,
    );
  }
}

// =============================================================================
// 일일 무료 사용량 (DailyUsage)
// =============================================================================

/// 일일 무료 사용량 Provider
///
/// 하루에 무료로 사용할 수 있는 좋아요/수락 횟수를 추적합니다.
/// 매일 자정에 리셋됩니다 (서버 사이드, 현재는 앱 재시작 시).
///
/// 상태:
/// - [DailyUsage]: 오늘의 무료 좋아요/수락 사용 횟수
///
/// 주요 메서드:
/// - [useFreeLike]: 무료 좋아요 1회 사용
/// - [useFreeAccept]: 무료 수락 1회 사용
@riverpod
class DailyUsageNotifier extends _$DailyUsageNotifier {
  @override
  DailyUsage build() {
    return DailyUsage(
      userId: 'mock-user',
      date: DateTime.now(),
      freeLikesUsed: 0,
      freeAcceptsUsed: 0,
    );
  }

  /// 무료 좋아요 1회 사용
  void useFreeLike() {
    final current = state;
    state = DailyUsage(
      userId: current.userId,
      date: current.date,
      freeLikesUsed: current.freeLikesUsed + 1,
      freeAcceptsUsed: current.freeAcceptsUsed,
    );
  }

  /// 무료 수락 1회 사용
  void useFreeAccept() {
    final current = state;
    state = DailyUsage(
      userId: current.userId,
      date: current.date,
      freeLikesUsed: current.freeLikesUsed,
      freeAcceptsUsed: current.freeAcceptsUsed + 1,
    );
  }
}

// =============================================================================
// 좋아요 전송 (SendLike)
// =============================================================================

/// 좋아요 전송 로직 Provider
///
/// 좋아요 전송 시 다음 순서로 처리합니다:
/// 1. 무료 좋아요 남아있으면 → 무료 사용
/// 2. 무료 소진 시 → 포인트 차감 (일반: 100P, 프리미엄: 300P)
/// 3. 포인트 부족 시 → 에러
///
/// 상태:
/// - `AsyncData(null)`: 대기 중
/// - `AsyncLoading`: 전송 중
/// - `AsyncError`: 전송 실패 (포인트 부족 등)
@riverpod
class SendLikeNotifier extends _$SendLikeNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 좋아요 전송
  ///
  /// [receiverId]: 좋아요를 받을 사용자 ID
  /// [isPremium]: 프리미엄 좋아요 여부 (상대에게 즉시 노출)
  ///
  /// 반환값: 전송 성공 여부
  Future<bool> sendLike(String receiverId, {bool isPremium = false}) async {
    final dailyUsage = ref.read(dailyUsageNotifierProvider);
    final userPoints = ref.read(userPointsNotifierProvider);

    // 1단계: 무료 좋아요 확인 (프리미엄이 아닐 때만)
    if (!isPremium && dailyUsage.hasFreeLikes) {
      state = const AsyncLoading();
      try {
        await ref
            .read(matchingRepositoryProvider)
            .sendLike(receiverId, isPremium: isPremium);
        ref.read(dailyUsageNotifierProvider.notifier).useFreeLike();
        state = const AsyncData(null);
        return true;
      } catch (e, st) {
        state = AsyncError(e, st);
        return false;
      }
    }

    // 2단계: 포인트 확인
    final cost = isPremium ? AppLimits.premiumLikeCost : AppLimits.likeCost;
    if (!userPoints.canAfford(cost)) {
      state = AsyncError(
        '포인트가 부족해요 (${cost}P 필요)',
        StackTrace.current,
      );
      return false;
    }

    // 3단계: 포인트 차감 후 좋아요 전송
    state = const AsyncLoading();
    try {
      await ref
          .read(matchingRepositoryProvider)
          .sendLike(receiverId, isPremium: isPremium);
      ref.read(userPointsNotifierProvider.notifier).spend(cost);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
