import '../entities/user_entity.dart';

/// Auth repository interface (domain layer)
///
/// 소셜 로그인, 로그아웃, 프로필 조회 등 인증 관련 기능.
/// data 레이어에서 구현한다.
abstract class AuthRepository {
  /// Apple 소셜 로그인
  Future<UserEntity?> signInWithApple();

  /// Google 소셜 로그인
  Future<UserEntity?> signInWithGoogle();

  /// 로그아웃
  Future<void> signOut();

  /// 현재 로그인된 사용자의 프로필 조회
  /// 프로필이 없으면 null (신규 가입 → 온보딩 필요)
  Future<UserEntity?> getCurrentUserProfile();

  /// 프로필 존재 여부 확인
  Future<bool> hasProfile();
}
