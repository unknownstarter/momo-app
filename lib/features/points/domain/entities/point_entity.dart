import 'package:momo_app/core/constants/app_constants.dart';

/// 포인트 잔액
class UserPoints {
  const UserPoints({
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
  });

  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;

  bool canAfford(int cost) => balance >= cost;

  UserPoints copyWith({int? balance, int? totalEarned, int? totalSpent}) {
    return UserPoints(
      userId: userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}

/// 포인트 거래 타입
enum PointTransactionType {
  purchase,
  likeSent,
  premiumLikeSent,
  accept,
  compatibilityReport,
  characterSkin,
  sajuReport,
  icebreaker,
  dailyResetBonus,
  refund,
}

/// 포인트 거래 내역
class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.targetId,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final PointTransactionType type;
  final int amount; // + earn, - spend
  final String? targetId;
  final String? description;
  final DateTime createdAt;

  bool get isEarning => amount > 0;
  bool get isSpending => amount < 0;
}

/// 일일 무료 사용량
class DailyUsage {
  const DailyUsage({
    required this.userId,
    required this.date,
    required this.freeLikesUsed,
    required this.freeAcceptsUsed,
    this.freePhotoRevealsUsed = 0,
  });

  final String userId;
  final DateTime date;
  final int freeLikesUsed;
  final int freeAcceptsUsed;
  final int freePhotoRevealsUsed;

  bool get hasFreeLikes => freeLikesUsed < AppLimits.dailyFreeLikeLimit;
  bool get hasFreeAccepts => freeAcceptsUsed < AppLimits.dailyFreeAcceptLimit;
  bool get hasFreePhotoReveals =>
      freePhotoRevealsUsed < AppLimits.dailyFreePhotoRevealLimit;
  int get remainingFreeLikes => AppLimits.dailyFreeLikeLimit - freeLikesUsed;
  int get remainingFreeAccepts =>
      AppLimits.dailyFreeAcceptLimit - freeAcceptsUsed;
  int get remainingFreePhotoReveals =>
      AppLimits.dailyFreePhotoRevealLimit - freePhotoRevealsUsed;
}
