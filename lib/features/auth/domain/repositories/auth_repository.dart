import '../entities/user_entity.dart';

/// Auth repository interface (domain layer)
///
/// 소셜 로그인, 로그아웃, 프로필 조회 등 인증 관련 기능.
/// data 레이어에서 구현한다.
abstract class AuthRepository {
  /// Apple 소셜 로그인 (네이티브 SDK, 동기적 결과)
  Future<UserEntity?> signInWithApple();

  /// Kakao 소셜 로그인 (Supabase OAuth, 브라우저 기반)
  /// 반환값: 브라우저 오픈 성공 여부
  /// 실제 세션은 딥링크 콜백으로 비동기 설정됨
  Future<bool> signInWithKakao();

  /// 로그아웃
  Future<void> signOut();

  /// 현재 로그인된 사용자의 프로필 조회
  /// 프로필이 없으면 null (신규 가입 → 온보딩 필요)
  Future<UserEntity?> getCurrentUserProfile();

  /// 프로필 존재 여부 확인
  Future<bool> hasProfile();
}
