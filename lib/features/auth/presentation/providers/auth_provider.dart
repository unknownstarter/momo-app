import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/user_entity.dart';

part 'auth_provider.g.dart';

/// 현재 로그인 유저의 프로필 (async)
@riverpod
Future<UserEntity?> currentUserProfile(Ref ref) async {
  // auth state가 바뀌면 다시 조회
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getCurrentUserProfile();
}

/// 프로필 존재 여부 (온보딩 완료 판별)
@riverpod
Future<bool> hasProfile(Ref ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).hasProfile();
}

/// Auth 액션 노티파이어 (로그인/로그아웃)
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  /// Apple 로그인 (네이티브 SDK — 동기적 결과)
  Future<UserEntity?> signInWithApple() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithApple();
      state = const AsyncData(null);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Kakao 로그인 (Supabase OAuth — 브라우저 오픈 후 딥링크 콜백)
  ///
  /// 브라우저가 열리면 true 반환. 실제 세션은 앱 복귀 시 자동 설정.
  /// authStateProvider가 세션 변경을 감지하면 라우터가 자동 리다이렉트.
  Future<bool> signInWithKakao() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final launched = await repo.signInWithKakao();
      state = const AsyncData(null);
      return launched;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
