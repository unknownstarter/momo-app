import '../../../auth/domain/entities/user_entity.dart';

/// Profile repository interface
abstract class ProfileRepository {
  /// 프로필 생성 (온보딩 완료 시)
  Future<UserEntity> createProfile({
    required String name,
    required String gender,
    required DateTime birthDate,
    String? birthTime,
    String? bio,
    List<String> interests,
    List<String> profileImageUrls,
  });

  /// 프로필 업데이트
  Future<UserEntity> updateProfile(Map<String, dynamic> updates);

  /// 프로필 조회
  Future<UserEntity?> getProfile();
}
