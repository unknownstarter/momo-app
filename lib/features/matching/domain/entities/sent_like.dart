import 'like_entity.dart';
import 'match_profile.dart';

/// 보낸 좋아요 복합 엔티티
///
/// Like 정보와 대상 프로필을 함께 들고 있어
/// "보낸" 탭에서 한 번에 렌더링할 수 있다.
class SentLike {
  const SentLike({
    required this.like,
    required this.profile,
  });

  final Like like;
  final MatchProfile profile;

  String get status => like.status.name;
  bool get isPending => like.isPending;
  bool get isAccepted => like.isAccepted;
}
