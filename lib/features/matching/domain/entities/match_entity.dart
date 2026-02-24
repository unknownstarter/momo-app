/// 매칭 성사
class Match {
  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.likeId,
    this.compatibilityId,
    required this.matchedAt,
    this.unmatchedAt,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final String? likeId;
  final String? compatibilityId;
  final DateTime matchedAt;
  final DateTime? unmatchedAt;

  bool get isActive => unmatchedAt == null;

  /// 상대방 ID 반환
  String partnerId(String myId) => myId == user1Id ? user2Id : user1Id;
}
