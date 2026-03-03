import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';

/// Auth remote datasource — Supabase Auth + profiles 테이블
class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Apple Sign In → Supabase Auth (네이티브 SDK → signInWithIdToken)
  Future<AuthResponse> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthFailure.socialLoginFailed('Apple');
      }

      return await _auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure.socialLoginFailed('Apple', e);
    }
  }

  /// Kakao Sign In → Supabase OAuth (브라우저 기반, PKCE 플로우)
  ///
  /// 브라우저에서 카카오 로그인 완료 후 딥링크로 앱 복귀 시
  /// Supabase SDK가 자동으로 세션을 설정합니다.
  /// 반환값: 브라우저 오픈 성공 여부
  Future<bool> signInWithKakao() async {
    try {
      return await _auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: 'com.nworld.momo://login-callback',
      );
    } catch (e) {
      throw AuthFailure.socialLoginFailed('Kakao', e);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// profiles 테이블에서 현재 유저 프로필 조회
  ///
  /// 프로필이 없으면 null 반환. 네트워크/서버 에러는 throw.
  Future<Map<String, dynamic>?> fetchProfile(String authId) async {
    return await _client
        .from(SupabaseTables.profiles)
        .select()
        .eq('auth_id', authId)
        .maybeSingle();
  }

  /// 현재 세션의 auth user
  User? get currentUser => _auth.currentUser;
}
