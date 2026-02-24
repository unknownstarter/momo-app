/// 입력값 검증 유틸리티
///
/// 프로필, 인증, 사주 입력 등에서 사용하는 공통 검증 함수들입니다.
/// 모든 검증 함수는 유효하면 null, 유효하지 않으면 에러 메시지 String을 반환합니다.
/// (Flutter FormField.validator 패턴과 호환)
library;

/// 입력값 검증 유틸리티 클래스
abstract final class Validators {
  // ===========================================================================
  // 이메일 검증
  // ===========================================================================

  /// 이메일 형식 검증
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해 주세요.';
    }
    // RFC 5322 간소화 버전
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식이 아니에요.';
    }
    return null;
  }

  // ===========================================================================
  // 전화번호 검증 (한국 형식)
  // ===========================================================================

  /// 한국 휴대전화 번호 검증
  ///
  /// 허용 형식:
  /// - 01012345678
  /// - 010-1234-5678
  /// - 010 1234 5678
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해 주세요.';
    }
    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'[\s\-]'), '');
    // 한국 휴대전화: 010, 011, 016, 017, 018, 019로 시작하는 10~11자리
    final phoneRegex = RegExp(r'^01[0-9]\d{7,8}$');
    if (!phoneRegex.hasMatch(digitsOnly)) {
      return '올바른 전화번호 형식이 아니에요. (예: 010-1234-5678)';
    }
    return null;
  }

  /// 전화번호를 표준 형식(010-XXXX-XXXX)으로 변환
  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  /// 전화번호에서 숫자만 추출 (E.164 형식 변환용)
  static String toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.startsWith('+82')) {
      return digits;
    }
    return '+82$digits';
  }

  // ===========================================================================
  // SMS 인증 코드 검증
  // ===========================================================================

  /// SMS 인증 코드 검증 (6자리 숫자)
  static String? smsCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '인증번호를 입력해 주세요.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return '6자리 숫자를 입력해 주세요.';
    }
    return null;
  }

  // ===========================================================================
  // 생년월일 검증
  // ===========================================================================

  /// 생년월일 검증
  ///
  /// [minAge]: 최소 나이 (기본값 18세)
  /// [maxAge]: 최대 나이 (기본값 60세)
  static String? birthDate(
    DateTime? value, {
    int minAge = 18,
    int maxAge = 60,
  }) {
    if (value == null) {
      return '생년월일을 선택해 주세요.';
    }

    final now = DateTime.now();
    final age = _calculateAge(value, now);

    if (age < minAge) {
      return '만 $minAge세 이상만 가입할 수 있어요.';
    }
    if (age > maxAge) {
      return '올바른 생년월일을 입력해 주세요.';
    }
    if (value.isAfter(now)) {
      return '미래 날짜는 입력할 수 없어요.';
    }
    return null;
  }

  /// 생년월일 문자열 검증 (YYYY-MM-DD 형식)
  static String? birthDateString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '생년월일을 입력해 주세요. (예: 1995-03-15)';
    }
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value.trim())) {
      return 'YYYY-MM-DD 형식으로 입력해 주세요.';
    }
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      return '올바른 날짜가 아니에요.';
    }
    return birthDate(parsed);
  }

  // ===========================================================================
  // 생시(태어난 시각) 검증
  // ===========================================================================

  /// 태어난 시각 검증
  ///
  /// 사주 계산에서 시주(時柱)를 결정하는 핵심 정보입니다.
  /// null이면 "시간 모름"으로 처리 가능 (시주 없이 삼주로 분석)
  static String? birthTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      // 시간을 모르는 경우는 허용 (optional)
      return null;
    }
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegex.hasMatch(value.trim())) {
      return 'HH:MM 형식으로 입력해 주세요. (예: 14:30)';
    }
    return null;
  }

  /// 태어난 시각을 시주 계산용 시진(時辰)으로 변환
  ///
  /// 하루를 12시진(2시간 단위)으로 나눕니다.
  /// 자시(子時): 23:00~01:00, 축시(丑時): 01:00~03:00, ...
  static int? toBirthHourIndex(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return null;
    // 자시는 23시~01시이므로 특별 처리
    if (hour == 23 || hour == 0) return 0; // 자시
    return ((hour + 1) ~/ 2); // 1-2→축(1), 3-4→인(2), ...
  }

  // ===========================================================================
  // 프로필 필드 검증
  // ===========================================================================

  /// 이름(닉네임) 검증
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해 주세요.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '이름은 2자 이상 입력해 주세요.';
    }
    if (trimmed.length > 20) {
      return '이름은 20자 이내로 입력해 주세요.';
    }
    // 한글, 영문, 숫자만 허용 (특수문자, 이모지 금지)
    if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(trimmed)) {
      return '이름에 특수문자나 이모지는 사용할 수 없어요.';
    }
    return null;
  }

  /// 자기소개 검증
  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '자기소개를 입력해 주세요.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 10) {
      return '자기소개는 10자 이상 작성해 주세요.';
    }
    if (trimmed.length > 300) {
      return '자기소개는 300자 이내로 작성해 주세요.';
    }
    return null;
  }

  /// 관심사 태그 목록 검증
  static String? interests(List<String>? value) {
    if (value == null || value.isEmpty) {
      return '관심사를 1개 이상 선택해 주세요.';
    }
    if (value.length > 10) {
      return '관심사는 최대 10개까지 선택할 수 있어요.';
    }
    return null;
  }

  // ===========================================================================
  // Private 헬퍼
  // ===========================================================================

  /// 만 나이 계산
  static int _calculateAge(DateTime birthDate, DateTime now) {
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
