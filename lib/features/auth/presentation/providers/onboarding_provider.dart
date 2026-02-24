import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/user_entity.dart';

part 'onboarding_provider.g.dart';

/// 온보딩 데이터를 Supabase에 저장하는 노티파이어
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  FutureOr<UserEntity?> build() => null;

  /// 온보딩 폼 데이터를 프로필로 저장
  Future<UserEntity> saveOnboardingData(Map<String, dynamic> formData) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.createProfile(
        name: formData['name'] as String,
        gender: formData['gender'] == '남성' ? 'male' : 'female',
        birthDate: DateTime.parse(formData['birthDate'] as String),
        birthTime: formData['birthHour'] as String?,
      );
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
