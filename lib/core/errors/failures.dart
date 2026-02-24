/// 에러 처리를 위한 Failure 클래스 계층 구조
///
/// Clean Architecture에서 domain 레이어는 외부 예외(Exception)에 직접 의존하지 않습니다.
/// 대신 Failure 객체를 통해 에러를 표현하고, data 레이어에서 Exception → Failure 변환을 담당합니다.
///
/// 사용 패턴:
/// ```dart
/// // Repository에서 Failure 반환
/// Future<Either<Failure, User>> getUser(String id);
///
/// // Riverpod AsyncValue와 함께 사용
/// ref.watch(userProvider).when(
///   data: (user) => UserCard(user),
///   loading: () => LoadingIndicator(),
///   error: (error, stack) => ErrorWidget(error),
/// );
/// ```
library;

// =============================================================================
// Base Failure
// =============================================================================

/// 모든 Failure의 기본 클래스
///
/// [message]: 사용자에게 표시할 수 있는 에러 메시지
/// [code]: 에러 코드 (로깅, 분석용)
/// [originalException]: 원본 예외 (디버깅용, 프로덕션에서는 노출하지 않음)
sealed class Failure implements Exception {
  const Failure({
    required this.message,
    this.code,
    this.originalException,
  });

  final String message;
  final String? code;
  final Object? originalException;

  @override
  String toString() => 'Failure($code): $message';
}

// =============================================================================
// 인프라 레이어 Failure
// =============================================================================

/// 서버/API 관련 실패
///
/// Supabase Edge Function 호출 실패, HTTP 에러 등
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalException,
    this.statusCode,
  });

  /// HTTP 상태 코드 (있는 경우)
  final int? statusCode;

  /// 일반적인 서버 에러
  factory ServerFailure.unknown([Object? exception]) => ServerFailure(
        message: '서버에 일시적인 문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
        code: 'SERVER_UNKNOWN',
        originalException: exception,
      );

  /// 서버 타임아웃
  factory ServerFailure.timeout([Object? exception]) => ServerFailure(
        message: '서버 응답이 지연되고 있어요. 네트워크 상태를 확인해 주세요.',
        code: 'SERVER_TIMEOUT',
        originalException: exception,
      );

  /// 서버 점검 중
  factory ServerFailure.maintenance() => const ServerFailure(
        message: '서비스 점검 중이에요. 잠시 후 다시 방문해 주세요.',
        code: 'SERVER_MAINTENANCE',
        statusCode: 503,
      );
}

/// 로컬 캐시/저장소 관련 실패
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  factory CacheFailure.notFound(String key) => CacheFailure(
        message: '캐시된 데이터를 찾을 수 없어요.',
        code: 'CACHE_NOT_FOUND_$key',
      );

  factory CacheFailure.writeError([Object? exception]) => CacheFailure(
        message: '데이터 저장에 실패했어요.',
        code: 'CACHE_WRITE_ERROR',
        originalException: exception,
      );
}

/// 네트워크 연결 실패
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  factory NetworkFailure.noConnection() => const NetworkFailure(
        message: '인터넷에 연결되어 있지 않아요. 네트워크 상태를 확인해 주세요.',
        code: 'NETWORK_NO_CONNECTION',
      );

  factory NetworkFailure.poorConnection() => const NetworkFailure(
        message: '네트워크 연결이 불안정해요. Wi-Fi나 데이터를 확인해 주세요.',
        code: 'NETWORK_POOR_CONNECTION',
      );
}

// =============================================================================
// 인증(Auth) 관련 Failure
// =============================================================================

/// 인증/로그인 관련 실패
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  /// 로그인 세션 만료
  factory AuthFailure.sessionExpired() => const AuthFailure(
        message: '로그인이 만료되었어요. 다시 로그인해 주세요.',
        code: 'AUTH_SESSION_EXPIRED',
      );

  /// 소셜 로그인 실패
  factory AuthFailure.socialLoginFailed(String provider, [Object? exception]) =>
      AuthFailure(
        message: '$provider 로그인에 실패했어요. 다시 시도해 주세요.',
        code: 'AUTH_SOCIAL_LOGIN_FAILED_$provider',
        originalException: exception,
      );

  /// SMS 인증 실패
  factory AuthFailure.smsVerificationFailed([Object? exception]) =>
      const AuthFailure(
        message: '인증번호가 올바르지 않아요. 다시 확인해 주세요.',
        code: 'AUTH_SMS_VERIFICATION_FAILED',
      );

  /// SMS 발송 실패
  factory AuthFailure.smsSendFailed([Object? exception]) => AuthFailure(
        message: '인증번호 발송에 실패했어요. 전화번호를 확인하고 다시 시도해 주세요.',
        code: 'AUTH_SMS_SEND_FAILED',
        originalException: exception,
      );

  /// 이미 가입된 계정
  factory AuthFailure.accountAlreadyExists(String method) => AuthFailure(
        message: '이미 $method(으)로 가입된 계정이에요.',
        code: 'AUTH_ACCOUNT_EXISTS',
      );

  /// 탈퇴한 계정
  factory AuthFailure.accountDeactivated() => const AuthFailure(
        message: '탈퇴 처리된 계정이에요. 고객센터에 문의해 주세요.',
        code: 'AUTH_ACCOUNT_DEACTIVATED',
      );

  /// 미인증 상태
  factory AuthFailure.unauthenticated() => const AuthFailure(
        message: '로그인이 필요한 기능이에요.',
        code: 'AUTH_UNAUTHENTICATED',
      );
}

// =============================================================================
// 비즈니스 도메인 Failure
// =============================================================================

/// 사주 계산/분석 관련 실패
class SajuCalculationFailure extends Failure {
  const SajuCalculationFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  /// 잘못된 생년월일시
  factory SajuCalculationFailure.invalidBirthInfo() =>
      const SajuCalculationFailure(
        message: '생년월일시 정보가 올바르지 않아요. 다시 확인해 주세요.',
        code: 'SAJU_INVALID_BIRTH_INFO',
      );

  /// 만세력 범위 초과 (너무 오래된 날짜 등)
  factory SajuCalculationFailure.outOfRange() =>
      const SajuCalculationFailure(
        message: '지원하지 않는 날짜 범위예요.',
        code: 'SAJU_OUT_OF_RANGE',
      );

  /// AI 해석 실패
  factory SajuCalculationFailure.aiInterpretationFailed(
          [Object? exception]) =>
      SajuCalculationFailure(
        message: '사주 해석 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
        code: 'SAJU_AI_INTERPRETATION_FAILED',
        originalException: exception,
      );
}

/// 매칭 관련 실패
class MatchingFailure extends Failure {
  const MatchingFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  /// 일일 매칭 한도 초과
  factory MatchingFailure.dailyLimitReached() => const MatchingFailure(
        message: '오늘의 매칭 추천을 모두 확인했어요. 내일 새로운 인연을 만나보세요!',
        code: 'MATCHING_DAILY_LIMIT',
      );

  /// 매칭 대상 없음
  factory MatchingFailure.noMatchesAvailable() => const MatchingFailure(
        message: '현재 조건에 맞는 매칭 대상이 없어요. 조건을 조정해 보시겠어요?',
        code: 'MATCHING_NO_MATCHES',
      );

  /// 프로필 미완성으로 매칭 불가
  factory MatchingFailure.profileIncomplete() => const MatchingFailure(
        message: '프로필을 완성해야 매칭을 시작할 수 있어요.',
        code: 'MATCHING_PROFILE_INCOMPLETE',
      );

  /// 사주 정보 미입력
  factory MatchingFailure.sajuRequired() => const MatchingFailure(
        message: '사주 정보를 입력해야 궁합 매칭을 받을 수 있어요.',
        code: 'MATCHING_SAJU_REQUIRED',
      );
}

/// 결제 관련 실패
class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    super.code,
    super.originalException,
  });

  /// 결제 취소 (사용자가 취소)
  factory PaymentFailure.cancelled() => const PaymentFailure(
        message: '결제가 취소되었어요.',
        code: 'PAYMENT_CANCELLED',
      );

  /// 결제 처리 실패
  factory PaymentFailure.processingFailed([Object? exception]) =>
      PaymentFailure(
        message: '결제 처리 중 문제가 발생했어요. 다시 시도해 주세요.',
        code: 'PAYMENT_PROCESSING_FAILED',
        originalException: exception,
      );

  /// 구독 복원 실패
  factory PaymentFailure.restoreFailed([Object? exception]) => PaymentFailure(
        message: '구독 복원에 실패했어요. 이전에 구독한 계정으로 로그인되어 있는지 확인해 주세요.',
        code: 'PAYMENT_RESTORE_FAILED',
        originalException: exception,
      );

  /// 이미 프리미엄 구독 중
  factory PaymentFailure.alreadySubscribed() => const PaymentFailure(
        message: '이미 프리미엄 회원이시네요!',
        code: 'PAYMENT_ALREADY_SUBSCRIBED',
      );
}

// =============================================================================
// Failure 확장 메서드
// =============================================================================

/// Failure에 대한 유틸리티 확장
extension FailureX on Failure {
  /// 사용자에게 표시하기에 안전한 메시지인지 확인
  bool get isUserFacing => message.isNotEmpty;

  /// 재시도 가능한 에러인지 판단
  bool get isRetryable {
    return this is ServerFailure || this is NetworkFailure;
  }

  /// 로그인이 필요한 에러인지 판단
  bool get requiresAuth {
    return this is AuthFailure &&
        (code == 'AUTH_SESSION_EXPIRED' || code == 'AUTH_UNAUTHENTICATED');
  }
}
