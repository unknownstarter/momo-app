import '../../domain/entities/user_entity.dart';

/// UserEntity ↔ Supabase JSON 변환 모델 (DTO)
class UserModel {
  const UserModel._();

  /// Supabase profiles 테이블 JSON → UserEntity
  static UserEntity fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      birthTime: json['birth_time'] as String?,
      gender: json['gender'] == 'male' ? Gender.male : Gender.female,
      sajuProfileId: json['saju_profile_id'] as String?,
      profileImageUrls: List<String>.from(json['profile_images'] ?? []),
      bio: json['bio'] as String?,
      interests: List<String>.from(json['interests'] ?? []),
      height: json['height'] as int?,
      location: json['location'] as String?,
      occupation: json['occupation'] as String?,
      mbti: json['mbti'] as String?,
      drinking: DrinkingFrequency.fromString(json['drinking'] as String?),
      smoking: SmokingStatus.fromString(json['smoking'] as String?),
      datingStyle: json['dating_style'] as String?,
      religion: Religion.fromString(json['religion'] as String?),
      isSelfieVerified: json['is_selfie_verified'] as bool? ?? false,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// UserEntity → Supabase profiles 테이블 JSON
  static Map<String, dynamic> toJson(UserEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'birth_date': entity.birthDate.toIso8601String().split('T').first,
      'birth_time': entity.birthTime,
      'gender': entity.gender == Gender.male ? 'male' : 'female',
      'profile_images': entity.profileImageUrls,
      'bio': entity.bio,
      'interests': entity.interests,
      'height': entity.height,
      'location': entity.location,
      'occupation': entity.occupation,
      'mbti': entity.mbti,
      'drinking': entity.drinking?.name,
      'smoking': entity.smoking?.name,
      'dating_style': entity.datingStyle,
      'religion': entity.religion?.name,
      'is_selfie_verified': entity.isSelfieVerified,
      'is_profile_complete': entity.isProfileComplete,
      'is_premium': entity.isPremium,
    };
  }
}
