import '../../../../core/domain/entities/user_entity.dart';

/// Profile repository interface
abstract class ProfileRepository {
  /// 프로필 생성 (Phase A 온보딩 완료 시 — 사주 기본 정보)
  Future<UserEntity> createProfile({
    required String name,
    required String gender,
    required DateTime birthDate,
    String? birthTime,
  });

  /// 매칭 프로필 완성 (Phase B 온보딩 완료 시)
  Future<UserEntity> completeMatchingProfile({
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
  });

  /// 프로필 이미지를 Storage에 업로드하고 공개 URL 목록을 반환
  Future<List<String>> uploadProfileImages(List<String> localFilePaths);

  /// 프로필 업데이트
  Future<UserEntity> updateProfile(Map<String, dynamic> updates);

  /// 프로필 조회
  Future<UserEntity?> getProfile();
}
