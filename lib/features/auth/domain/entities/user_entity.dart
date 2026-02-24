/// 사용자 엔티티
///
/// 인증 및 프로필 정보를 담는 핵심 도메인 엔티티입니다.
/// Clean Architecture 원칙에 따라 domain 레이어에 위치하며,
/// 어떤 외부 라이브러리에도 의존하지 않습니다.
///
/// freezed를 사용할 예정이지만, build_runner 실행 전이므로
/// 수동으로 불변 클래스를 구현합니다.
/// TODO: freezed 어노테이션 추가 후 build_runner 실행
library;

/// 성별
enum Gender {
  male('남성'),
  female('여성');

  const Gender(this.label);
  final String label;
}

/// 사용자 프로필 완성도 상태
enum ProfileCompletionStatus {
  /// 기본 정보만 입력 (소셜 로그인 직후)
  basicInfoOnly,

  /// 사주 정보 입력 완료
  sajuInfoCompleted,

  /// 프로필 사진 업로드 완료
  photosUploaded,

  /// 자기소개 작성 완료
  bioCompleted,

  /// 모든 정보 완료 (매칭 가능 상태)
  fullyCompleted,
}

/// 사용자 엔티티
///
/// 앱의 핵심 도메인 모델입니다.
/// 인증 정보, 프로필 정보, 사주 연동 정보를 포함합니다.
class UserEntity {
  const UserEntity({
    required this.id,
    this.email,
    this.phone,
    required this.name,
    required this.birthDate,
    this.birthTime,
    required this.gender,
    this.sajuProfileId,
    this.profileImageUrls = const [],
    this.bio,
    this.interests = const [],
    this.height,
    this.location,
    this.occupation,
    this.isPremium = false,
    required this.createdAt,
    required this.lastActiveAt,
    this.deletedAt,
  });

  // --- 인증 정보 ---

  /// 고유 사용자 ID (Supabase Auth UID)
  final String id;

  /// 이메일 주소 (소셜 로그인에서 획득, nullable)
  final String? email;

  /// 전화번호 (SMS 인증 완료 시, E.164 형식)
  final String? phone;

  // --- 기본 프로필 ---

  /// 이름 (닉네임)
  final String name;

  /// 생년월일 (사주 계산의 기본 입력)
  final DateTime birthDate;

  /// 태어난 시각 (HH:MM 형식, null이면 시주 없이 분석)
  ///
  /// 사주의 시주(時柱)를 결정하는 핵심 정보입니다.
  /// 모르는 경우 null로 두고 삼주(三柱)만으로 분석합니다.
  final String? birthTime;

  /// 성별
  final Gender gender;

  // --- 사주 연동 ---

  /// 사주 프로필 ID (saju_profiles 테이블 FK)
  ///
  /// null이면 아직 사주 분석을 하지 않은 상태입니다.
  /// 사주 분석 완료 후 ID가 설정됩니다.
  final String? sajuProfileId;

  // --- 프로필 상세 ---

  /// 프로필 사진 URL 목록 (최대 6장)
  ///
  /// 첫 번째 사진이 대표 사진으로 사용됩니다.
  final List<String> profileImageUrls;

  /// 자기소개 (10~300자)
  final String? bio;

  /// 관심사/취미 태그 (최대 10개)
  final List<String> interests;

  /// 키 (cm, optional)
  final int? height;

  /// 활동 지역 (예: '서울 강남구')
  final String? location;

  /// 직업
  final String? occupation;

  // --- 구독 상태 ---

  /// 프리미엄 구독 여부
  final bool isPremium;

  // --- 타임스탬프 ---

  /// 계정 생성일
  final DateTime createdAt;

  /// 마지막 활동 시각 (온라인 상태 판단용)
  final DateTime lastActiveAt;

  /// 탈퇴일 (soft delete)
  final DateTime? deletedAt;

  // ===========================================================================
  // 계산 프로퍼티
  // ===========================================================================

  /// 만 나이
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 대표 프로필 사진 URL
  String? get primaryPhotoUrl =>
      profileImageUrls.isNotEmpty ? profileImageUrls.first : null;

  /// 사주 분석 완료 여부
  bool get hasSajuProfile => sajuProfileId != null;

  /// 계정 활성 상태 (탈퇴하지 않았는지)
  bool get isActive => deletedAt == null;

  /// 프로필 완성도 상태
  ProfileCompletionStatus get completionStatus {
    if (profileImageUrls.isNotEmpty &&
        bio != null &&
        bio!.isNotEmpty &&
        hasSajuProfile) {
      return ProfileCompletionStatus.fullyCompleted;
    }
    if (bio != null && bio!.isNotEmpty) {
      return ProfileCompletionStatus.bioCompleted;
    }
    if (profileImageUrls.isNotEmpty) {
      return ProfileCompletionStatus.photosUploaded;
    }
    if (hasSajuProfile) {
      return ProfileCompletionStatus.sajuInfoCompleted;
    }
    return ProfileCompletionStatus.basicInfoOnly;
  }

  /// 프로필 완성도 퍼센트 (0~100)
  int get completionPercent {
    int score = 0;
    if (name.isNotEmpty) score += 15;
    if (phone != null) score += 10;
    if (hasSajuProfile) score += 25;
    if (profileImageUrls.isNotEmpty) score += 20;
    if (bio != null && bio!.isNotEmpty) score += 15;
    if (interests.isNotEmpty) score += 10;
    if (location != null) score += 5;
    return score.clamp(0, 100);
  }

  /// 매칭 가능 여부 (프로필이 충분히 완성되었는지)
  bool get isMatchable =>
      completionStatus == ProfileCompletionStatus.fullyCompleted &&
      isActive;

  // ===========================================================================
  // copyWith
  // ===========================================================================

  /// 불변 객체의 일부 필드를 변경한 새 인스턴스 반환
  UserEntity copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    DateTime? birthDate,
    String? birthTime,
    Gender? gender,
    String? sajuProfileId,
    List<String>? profileImageUrls,
    String? bio,
    List<String>? interests,
    int? height,
    String? location,
    String? occupation,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? deletedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      gender: gender ?? this.gender,
      sajuProfileId: sajuProfileId ?? this.sajuProfileId,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      height: height ?? this.height,
      location: location ?? this.location,
      occupation: occupation ?? this.occupation,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // ===========================================================================
  // Equality & toString
  // ===========================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, name: $name, age: $age)';
}
