import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';

/// Auth remote datasource — Supabase Auth + profiles 테이블
class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Apple Sign In → Supabase Auth
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

  /// Google Sign In → Supabase Auth
  Future<AuthResponse> signInWithGoogle() async {
    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      // Client ID 미설정 시 네이티브 크래시 방지
      if (iosClientId.isEmpty && webClientId.isEmpty) {
        throw AuthFailure.socialLoginFailed(
          'Google',
          'Google OAuth Client ID가 설정되지 않았습니다. '
          '--dart-define으로 GOOGLE_IOS_CLIENT_ID를 전달하세요.',
        );
      }

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthFailure.socialLoginFailed('Google');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw AuthFailure.socialLoginFailed('Google');
      }

      return await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure.socialLoginFailed('Google', e);
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
