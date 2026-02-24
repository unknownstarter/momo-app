import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/domain/entities/user_entity.dart';

/// Phase B 매칭 프로필 완성 상태
class MatchingProfileNotifier extends StateNotifier<AsyncValue<void>> {
  MatchingProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// 매칭 프로필 저장 (Phase B 온보딩 완료 시)
  Future<UserEntity?> saveMatchingProfile({
    required List<String> profileImageUrls,
    required int height,
    required String occupation,
    required String location,
    required String bio,
    required List<String> interests,
    String? mbti,
    DrinkingFrequency? drinking,
    SmokingStatus? smoking,
    String? datingStyle,
    Religion? religion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      final user = await repo.completeMatchingProfile(
        profileImageUrls: profileImageUrls,
        height: height,
        occupation: occupation,
        location: location,
        bio: bio,
        interests: interests,
        mbti: mbti,
        drinking: drinking,
        smoking: smoking,
        datingStyle: datingStyle,
        religion: religion,
      );
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// 매칭 프로필 완성 Provider
final matchingProfileNotifierProvider =
    StateNotifierProvider<MatchingProfileNotifier, AsyncValue<void>>((ref) {
  return MatchingProfileNotifier(ref);
});
