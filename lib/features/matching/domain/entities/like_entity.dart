enum LikeStatus { pending, accepted, rejected, expired }

/// 좋아요
class Like {
  const Like({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.isPremium,
    required this.status,
    required this.sentAt,
    this.respondedAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final bool isPremium;
  final LikeStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  bool get isPending => status == LikeStatus.pending;
  bool get isAccepted => status == LikeStatus.accepted;

  /// 프리미엄 좋아요를 받으면 무료로 수락 가능
  bool get canAcceptFree => isPremium;
}
