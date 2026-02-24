---
name: flutter-developer
description: 사주 데이팅 앱의 Flutter 개발자 — Clean Architecture, Riverpod, go_router, Supabase SDK, RevenueCat
---

# Flutter Developer (Clean Architecture Specialist) — 사주 데이팅 앱

## 1. Feature-First Clean Architecture

### 프로젝트 구조
```
lib/
├── main.dart
├── app.dart                        # MaterialApp.router 진입점
├── bootstrap.dart                  # 초기화 로직 (Supabase, RevenueCat 등)
│
├── core/                           # 공통 모듈 (feature 간 공유)
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── saju_constants.dart     # 천간, 지지, 오행 상수
│   ├── error/
│   │   ├── failures.dart           # Failure 클래스 (도메인 에러)
│   │   └── exceptions.dart         # Exception 클래스 (인프라 에러)
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── date_extensions.dart
│   │   └── string_extensions.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── validators.dart
│   │   └── date_utils.dart
│   └── widgets/                    # 공용 위젯
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       ├── empty_state_widget.dart
│       ├── cached_profile_image.dart
│       └── ohang_chart.dart        # 오행 차트 위젯
│
├── features/                       # 기능별 모듈
│   ├── auth/                       # 인증
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── auth_user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_kakao.dart
│   │   │       ├── sign_in_with_apple.dart
│   │   │       ├── sign_in_with_google.dart
│   │   │       ├── verify_phone.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── phone_verification_screen.dart
│   │       └── widgets/
│   │           ├── social_login_button.dart
│   │           └── phone_input_field.dart
│   │
│   ├── onboarding/                 # 온보딩
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── onboarding_provider.dart
│   │       ├── screens/
│   │       │   ├── birth_input_screen.dart
│   │       │   ├── saju_result_screen.dart
│   │       │   ├── profile_setup_screen.dart
│   │       │   └── preference_screen.dart
│   │       └── widgets/...
│   │
│   ├── saju/                       # 사주 분석
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── saju_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── saju_profile_model.dart
│   │   │   │   └── compatibility_model.dart
│   │   │   └── repositories/
│   │   │       └── saju_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── saju_profile.dart
│   │   │   │   ├── ohang_distribution.dart
│   │   │   │   └── compatibility_result.dart
│   │   │   ├── repositories/
│   │   │   │   └── saju_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_saju_analysis.dart
│   │   │       ├── get_compatibility.dart
│   │   │       └── get_daily_fortune.dart
│   │   └── presentation/
│   │       ├── providers/...
│   │       ├── screens/
│   │       │   ├── saju_detail_screen.dart
│   │       │   ├── compatibility_screen.dart
│   │       │   └── daily_fortune_screen.dart
│   │       └── widgets/
│   │           ├── ohang_radar_chart.dart
│   │           ├── saju_pillar_card.dart
│   │           ├── compatibility_gauge.dart
│   │           └── fortune_card.dart
│   │
│   ├── matching/                   # 매칭
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/
│   │       ├── providers/...
│   │       ├── screens/
│   │       │   ├── matching_screen.dart
│   │       │   └── match_success_screen.dart
│   │       └── widgets/
│   │           ├── profile_card.dart
│   │           ├── swipe_card_stack.dart
│   │           └── compatibility_badge.dart
│   │
│   ├── chat/                       # 채팅
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   │
│   ├── profile/                    # 프로필 관리
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   │
│   └── subscription/              # 구독/결제
│       ├── data/...
│       ├── domain/...
│       └── presentation/...
│
└── router/
    ├── app_router.dart             # go_router 설정
    ├── route_names.dart            # 라우트 이름 상수
    └── auth_redirect.dart          # 인증 리다이렉트 로직
```

### Clean Architecture 레이어 규칙

#### Domain Layer (가장 안쪽 — 의존성 없음)
```dart
// 엔티티: 순수 Dart 클래스, 외부 의존성 없음
@freezed
class SajuProfile with _$SajuProfile {
  const factory SajuProfile({
    required String userId,
    required String dayHeavenly,
    required String dayEarthly,
    required OhangDistribution ohangDistribution,
    required String personalitySummary,
    required String loveStyle,
    required List<String> personalityKeywords,
    required String dayMasterType,
    required String dayMasterElement,
  }) = _SajuProfile;
}

// Repository 인터페이스: 구현 없음, 계약만 정의
abstract class SajuRepository {
  Future<Either<Failure, SajuProfile>> getSajuAnalysis({
    required DateTime birthDate,
    String? birthTime,
    required String birthCalendar,
  });

  Future<Either<Failure, CompatibilityResult>> getCompatibility({
    required String targetUserId,
  });

  Future<Either<Failure, DailyFortune>> getDailyFortune();
}

// UseCase: 비즈니스 로직 단위
class GetSajuAnalysis {
  final SajuRepository repository;
  const GetSajuAnalysis(this.repository);

  Future<Either<Failure, SajuProfile>> call(GetSajuAnalysisParams params) {
    return repository.getSajuAnalysis(
      birthDate: params.birthDate,
      birthTime: params.birthTime,
      birthCalendar: params.birthCalendar,
    );
  }
}
```

#### Data Layer (외부 의존성 담당)
```dart
// Model: Entity를 상속하며 JSON 직렬화 추가
@freezed
class SajuProfileModel with _$SajuProfileModel {
  const factory SajuProfileModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'day_heavenly') required String dayHeavenly,
    @JsonKey(name: 'day_earthly') required String dayEarthly,
    @JsonKey(name: 'wood_ratio') required int woodRatio,
    @JsonKey(name: 'fire_ratio') required int fireRatio,
    @JsonKey(name: 'earth_ratio') required int earthRatio,
    @JsonKey(name: 'metal_ratio') required int metalRatio,
    @JsonKey(name: 'water_ratio') required int waterRatio,
    @JsonKey(name: 'personality_summary') required String personalitySummary,
    @JsonKey(name: 'love_style') required String loveStyle,
    @JsonKey(name: 'personality_keywords') required List<String> personalityKeywords,
    @JsonKey(name: 'day_master_type') required String dayMasterType,
    @JsonKey(name: 'day_master_element') required String dayMasterElement,
  }) = _SajuProfileModel;

  factory SajuProfileModel.fromJson(Map<String, dynamic> json) =>
      _$SajuProfileModelFromJson(json);
}

extension SajuProfileModelX on SajuProfileModel {
  SajuProfile toEntity() => SajuProfile(
    userId: userId,
    dayHeavenly: dayHeavenly,
    dayEarthly: dayEarthly,
    ohangDistribution: OhangDistribution(
      wood: woodRatio,
      fire: fireRatio,
      earth: earthRatio,
      metal: metalRatio,
      water: waterRatio,
    ),
    personalitySummary: personalitySummary,
    loveStyle: loveStyle,
    personalityKeywords: personalityKeywords,
    dayMasterType: dayMasterType,
    dayMasterElement: dayMasterElement,
  );
}

// DataSource: Supabase와 직접 통신
class SajuRemoteDataSource {
  final SupabaseClient _client;
  const SajuRemoteDataSource(this._client);

  Future<SajuProfileModel> getSajuAnalysis({
    required DateTime birthDate,
    String? birthTime,
    required String birthCalendar,
  }) async {
    final response = await _client.functions.invoke(
      'saju-analysis',
      body: {
        'birth_date': birthDate.toIso8601String(),
        'birth_time': birthTime,
        'birth_calendar': birthCalendar,
      },
    );

    if (response.status != 200) {
      throw ServerException(response.data['error'] ?? 'Unknown error');
    }

    return SajuProfileModel.fromJson(response.data['saju']);
  }
}

// Repository 구현
class SajuRepositoryImpl implements SajuRepository {
  final SajuRemoteDataSource remoteDataSource;
  const SajuRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, SajuProfile>> getSajuAnalysis({
    required DateTime birthDate,
    String? birthTime,
    required String birthCalendar,
  }) async {
    try {
      final model = await remoteDataSource.getSajuAnalysis(
        birthDate: birthDate,
        birthTime: birthTime,
        birthCalendar: birthCalendar,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
```

#### Presentation Layer (UI + 상태 관리)
```dart
// Provider: Riverpod으로 상태 관리
// (Presentation → Domain만 의존)
```

---

## 2. Riverpod 2.x 패턴

### Provider 구조
```dart
// providers.dart — feature별 provider 정의 파일

// DataSource Provider
@riverpod
SajuRemoteDataSource sajuRemoteDataSource(Ref ref) {
  return SajuRemoteDataSource(ref.watch(supabaseClientProvider));
}

// Repository Provider
@riverpod
SajuRepository sajuRepository(Ref ref) {
  return SajuRepositoryImpl(ref.watch(sajuRemoteDataSourceProvider));
}

// UseCase Provider
@riverpod
GetSajuAnalysis getSajuAnalysis(Ref ref) {
  return GetSajuAnalysis(ref.watch(sajuRepositoryProvider));
}
```

### AsyncValue 패턴
```dart
// ★ 핵심 패턴: AsyncNotifier + code generation

@riverpod
class SajuAnalysis extends _$SajuAnalysis {
  @override
  FutureOr<SajuProfile?> build() => null; // 초기 상태: null

  Future<void> analyze({
    required DateTime birthDate,
    String? birthTime,
    required String birthCalendar,
  }) async {
    state = const AsyncLoading();

    final result = await ref.read(getSajuAnalysisProvider).call(
      GetSajuAnalysisParams(
        birthDate: birthDate,
        birthTime: birthTime,
        birthCalendar: birthCalendar,
      ),
    );

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (sajuProfile) => AsyncData(sajuProfile),
    );
  }
}

// UI에서 사용
class SajuResultScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sajuState = ref.watch(sajuAnalysisProvider);

    return sajuState.when(
      data: (profile) {
        if (profile == null) return const SajuInputForm();
        return SajuResultCard(profile: profile);
      },
      loading: () => const SajuLoadingAnimation(),
      error: (error, stack) => AppErrorWidget(
        message: _getErrorMessage(error),
        onRetry: () => ref.invalidate(sajuAnalysisProvider),
      ),
    );
  }
}
```

### 전역 Provider
```dart
// core/providers/supabase_provider.dart
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
}

@riverpod
User? currentUser(Ref ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
}
```

### Provider 선택 가이드
| 상황 | Provider 유형 | 이유 |
|-----|-------------|------|
| 단순 의존성 주입 | `@riverpod function` | DataSource, Repository, UseCase |
| 서버 데이터 조회 | `@riverpod FutureOr<T>` | API 호출, DB 조회 |
| 실시간 데이터 | `@riverpod Stream<T>` | 채팅 메시지, Auth 상태 |
| 복잡한 상태 관리 | `@riverpod class extends _$` | 폼 입력, 다단계 프로세스 |
| 앱 전체 상태 | `@Riverpod(keepAlive: true)` | Auth, Supabase 클라이언트 |

---

## 3. go_router 네비게이션

### 라우터 설정
```dart
// router/app_router.dart
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');

      // 비로그인 → 로그인 페이지로
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';

      // 로그인 상태인데 auth 페이지 → 홈으로
      if (isLoggedIn && isAuthRoute) return '/';

      // 프로필 미완성 → 온보딩으로
      final profile = ref.read(currentProfileProvider);
      if (isLoggedIn && profile != null && !profile.isProfileComplete && !isOnboarding) {
        return '/onboarding/birth-input';
      }

      return null; // 리다이렉트 없음
    },
    routes: [
      // Auth
      GoRoute(
        path: '/auth/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/phone-verify',
        name: RouteNames.phoneVerify,
        builder: (context, state) => const PhoneVerificationScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding/birth-input',
        name: RouteNames.birthInput,
        builder: (context, state) => const BirthInputScreen(),
      ),
      GoRoute(
        path: '/onboarding/saju-result',
        name: RouteNames.sajuResult,
        builder: (context, state) => const SajuResultScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile-setup',
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/preferences',
        name: RouteNames.preferences,
        builder: (context, state) => const PreferenceScreen(),
      ),

      // Main (ShellRoute with Bottom Nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 홈/추천
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: RouteNames.home,
                builder: (context, state) => const MatchingScreen(),
              ),
            ],
          ),
          // 탐색
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: RouteNames.explore,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          // 채팅
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                name: RouteNames.chatList,
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    name: RouteNames.chatRoom,
                    builder: (context, state) => ChatRoomScreen(
                      roomId: state.pathParameters['roomId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 사주
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saju',
                name: RouteNames.sajuHome,
                builder: (context, state) => const SajuDetailScreen(),
              ),
            ],
          ),
          // 프로필
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.profileEdit,
                    builder: (context, state) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.settings,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // 모달/풀스크린 라우트 (bottom nav 위에 표시)
      GoRoute(
        path: '/match-success/:matchId',
        name: RouteNames.matchSuccess,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: MatchSuccessScreen(
            matchId: state.pathParameters['matchId']!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(scale: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/compatibility/:targetUserId',
        name: RouteNames.compatibility,
        builder: (context, state) => CompatibilityScreen(
          targetUserId: state.pathParameters['targetUserId']!,
        ),
      ),
      GoRoute(
        path: '/paywall',
        name: RouteNames.paywall,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: PaywallScreen(),
        ),
      ),
    ],
  );
}
```

### Deep Link 설정
```dart
// iOS: Info.plist
// <key>CFBundleURLTypes</key>
// <array>
//   <dict>
//     <key>CFBundleURLSchemes</key>
//     <array><string>sajuapp</string></array>
//   </dict>
// </array>

// Android: AndroidManifest.xml
// <intent-filter>
//   <action android:name="android.intent.action.VIEW" />
//   <category android:name="android.intent.category.DEFAULT" />
//   <category android:name="android.intent.category.BROWSABLE" />
//   <data android:scheme="sajuapp" />
// </intent-filter>
```

---

## 4. Freezed + json_serializable

### 코드 생성 워크플로우
```bash
# 코드 생성 실행
dart run build_runner build --delete-conflicting-outputs

# 감시 모드 (개발 중)
dart run build_runner watch --delete-conflicting-outputs
```

### Freezed 패턴
```dart
// 엔티티 정의
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String nickname,
    required String gender,
    required DateTime birthDate,
    String? birthTime,
    String? bio,
    @Default(false) bool isProfileComplete,
    @Default(false) bool isVerified,
    @Default('free') String subscriptionTier,
    required DateTime createdAt,
  }) = _Profile;
}

// API 모델 (JSON 직렬화 포함)
@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String nickname,
    required String gender,
    @JsonKey(name: 'birth_date') required String birthDateStr,
    @JsonKey(name: 'birth_time') String? birthTime,
    String? bio,
    @JsonKey(name: 'is_profile_complete') @Default(false) bool isProfileComplete,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'subscription_tier') @Default('free') String subscriptionTier,
    @JsonKey(name: 'created_at') required String createdAtStr,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

// Union 타입 (상태 표현에 유용)
@freezed
sealed class MatchAction with _$MatchAction {
  const factory MatchAction.like() = _Like;
  const factory MatchAction.pass() = _Pass;
  const factory MatchAction.superLike() = _SuperLike;
}
```

---

## 5. Supabase Flutter SDK 패턴

### 초기화
```dart
// bootstrap.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // RevenueCat 초기화
  await Purchases.configure(
    PurchasesConfiguration(
      Platform.isIOS
        ? const String.fromEnvironment('RC_IOS_KEY')
        : const String.fromEnvironment('RC_ANDROID_KEY'),
    ),
  );

  runApp(const ProviderScope(child: App()));
}
```

### CRUD 패턴
```dart
// SELECT
final profiles = await supabase
    .from('profiles')
    .select('*, profile_photos(*)')
    .eq('is_active', true)
    .order('last_active_at', ascending: false)
    .limit(20);

// INSERT
await supabase.from('matches').insert({
  'user_id': currentUserId,
  'target_id': targetUserId,
  'action': 'like',
});

// UPDATE
await supabase
    .from('profiles')
    .update({'bio': newBio, 'updated_at': DateTime.now().toIso8601String()})
    .eq('id', currentUserId);

// DELETE
await supabase
    .from('profile_photos')
    .delete()
    .eq('id', photoId)
    .eq('user_id', currentUserId);

// RPC (저장 프로시저 호출)
final result = await supabase.rpc('get_nearby_users', params: {
  'user_lat': latitude,
  'user_lon': longitude,
  'radius_km': 50,
});
```

### Edge Function 호출
```dart
final response = await supabase.functions.invoke(
  'saju-analysis',
  body: {
    'birth_date': birthDate.toIso8601String(),
    'birth_time': birthTime,
    'birth_calendar': 'solar',
  },
);

if (response.status == 200) {
  final data = response.data as Map<String, dynamic>;
  return SajuProfileModel.fromJson(data['saju']);
} else {
  throw ServerException(response.data['error'] ?? 'Edge Function error');
}
```

---

## 6. 소셜 로그인 구현

### 카카오 로그인
```dart
// pubspec.yaml: kakao_flutter_sdk: ^1.9.0

Future<AuthResponse> signInWithKakao() async {
  // 카카오 SDK로 토큰 획득
  final OAuthToken token;
  if (await isKakaoTalkInstalled()) {
    token = await UserApi.instance.loginWithKakaoTalk();
  } else {
    token = await UserApi.instance.loginWithKakaoAccount();
  }

  // Supabase에 카카오 토큰으로 로그인
  final response = await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.kakao,
    idToken: token.idToken!,
    accessToken: token.accessToken,
  );

  return response;
}
```

### Apple 로그인
```dart
// pubspec.yaml: sign_in_with_apple: ^6.0.0

Future<AuthResponse> signInWithApple() async {
  final response = await supabase.auth.signInWithApple();
  return response;
  // Supabase가 Apple Sign In을 네이티브로 지원
}
```

### Google 로그인
```dart
// pubspec.yaml: google_sign_in: ^6.2.0

Future<AuthResponse> signInWithGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  );

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) throw const AuthException('Google sign in cancelled');

  final googleAuth = await googleUser.authentication;

  final response = await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: googleAuth.idToken!,
    accessToken: googleAuth.accessToken,
  );

  return response;
}
```

### 전화번호 인증
```dart
// 인증번호 발송
Future<void> sendOtp(String phoneNumber) async {
  await supabase.auth.signInWithOtp(
    phone: phoneNumber, // '+821012345678' 형식
  );
}

// 인증번호 확인
Future<AuthResponse> verifyOtp(String phoneNumber, String otpCode) async {
  final response = await supabase.auth.verifyOTP(
    phone: phoneNumber,
    token: otpCode,
    type: OtpType.sms,
  );
  return response;
}
```

---

## 7. RevenueCat 인앱결제

### 설정
```dart
// bootstrap.dart에서 초기화 후
// 로그인 시 RevenueCat 사용자 ID 설정
Future<void> configureRevenueCat(String userId) async {
  await Purchases.logIn(userId);
}
```

### 상품 조회 & 구매
```dart
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  FutureOr<CustomerInfo?> build() async {
    return await Purchases.getCustomerInfo();
  }

  Future<List<Package>> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  Future<void> purchase(Package package) async {
    state = const AsyncLoading();
    try {
      final result = await Purchases.purchasePackage(package);
      state = AsyncData(result.customerInfo);
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }

  Future<void> restore() async {
    state = const AsyncLoading();
    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(info);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  bool isPremium(CustomerInfo? info) {
    return info?.entitlements.active.containsKey('premium') ?? false;
  }

  bool isVip(CustomerInfo? info) {
    return info?.entitlements.active.containsKey('vip') ?? false;
  }
}
```

### 페이월 UI 패턴
```dart
class PaywallScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Package>>(
      future: ref.read(subscriptionNotifierProvider.notifier).getOfferings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingWidget();

        final packages = snapshot.data!;

        return Column(
          children: [
            // 혜택 설명
            const PaywallBenefits(),

            // 요금제 카드들
            ...packages.map((pkg) => PricingCard(
              package: pkg,
              onTap: () => ref
                  .read(subscriptionNotifierProvider.notifier)
                  .purchase(pkg),
            )),

            // 구매 복원
            TextButton(
              onPressed: () => ref
                  .read(subscriptionNotifierProvider.notifier)
                  .restore(),
              child: const Text('구매 복원'),
            ),

            // 법적 문구
            const LegalText(),
          ],
        );
      },
    );
  }
}
```

---

## 8. 이미지 핸들링

### 사진 선택 & 크롭
```dart
// pubspec.yaml: image_picker: ^1.0.0, image_cropper: ^5.0.0

Future<File?> pickAndCropImage({required ImageSource source}) async {
  final ImagePicker picker = ImagePicker();

  // 1. 사진 선택
  final XFile? pickedFile = await picker.pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1500,
    imageQuality: 85,
  );
  if (pickedFile == null) return null;

  // 2. 크롭 (4:5 비율)
  final CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: '사진 편집',
        toolbarColor: AppColors.brandPrimary,
        activeControlsWidgetColor: AppColors.brandPrimary,
      ),
      IOSUiSettings(title: '사진 편집'),
    ],
  );

  if (croppedFile == null) return null;
  return File(croppedFile.path);
}
```

### Supabase Storage 업로드
```dart
Future<String> uploadProfilePhoto(File file, String userId, int order) async {
  final ext = file.path.split('.').last;
  final path = '$userId/${order}_${DateTime.now().millisecondsSinceEpoch}.$ext';

  await supabase.storage
      .from('profile-photos')
      .upload(path, file, fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ));

  // Public URL 반환
  return supabase.storage
      .from('profile-photos')
      .getPublicUrl(path);
}
```

### 이미지 캐싱
```dart
// pubspec.yaml: cached_network_image: ^3.3.0

class CachedProfileImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedProfileImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Supabase Image Transform으로 적절한 크기 요청
    final optimizedUrl = '$imageUrl?width=${(width ?? 400).toInt()}'
        '&height=${(height ?? 500).toInt()}&resize=cover';

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => const ShimmerPlaceholder(),
      errorWidget: (context, url, error) => const Icon(Icons.person),
      memCacheWidth: (width ?? 400).toInt(),
    );
  }
}
```

---

## 9. 채팅 구현

### Realtime 구독
```dart
@riverpod
class ChatMessages extends _$ChatMessages {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<Message>> build(String roomId) async {
    // 초기 메시지 로드
    final messages = await _fetchMessages(roomId);

    // Realtime 구독
    _channel = ref.read(supabaseClientProvider)
        .channel('chat:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final newMessage = MessageModel.fromJson(payload.newRecord);
            state = AsyncData([
              ...state.valueOrNull ?? [],
              newMessage.toEntity(),
            ]);
          },
        )
        .subscribe();

    // 정리
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return messages;
  }

  Future<List<Message>> _fetchMessages(String roomId) async {
    final data = await ref.read(supabaseClientProvider)
        .from('messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(50);

    return (data as List)
        .map((json) => MessageModel.fromJson(json).toEntity())
        .toList();
  }

  Future<void> sendMessage(String content) async {
    final userId = ref.read(currentUserProvider)!.id;
    final roomId = this.roomId;

    await ref.read(supabaseClientProvider).from('messages').insert({
      'room_id': roomId,
      'sender_id': userId,
      'content': content,
      'message_type': 'text',
    });
  }

  Future<void> loadMoreMessages() async {
    final currentMessages = state.valueOrNull ?? [];
    if (currentMessages.isEmpty) return;

    final oldestMessage = currentMessages.first;
    final olderMessages = await ref.read(supabaseClientProvider)
        .from('messages')
        .select()
        .eq('room_id', roomId)
        .lt('created_at', oldestMessage.createdAt.toIso8601String())
        .order('created_at', ascending: false)
        .limit(30);

    final parsed = (olderMessages as List)
        .map((json) => MessageModel.fromJson(json).toEntity())
        .toList()
        .reversed
        .toList();

    state = AsyncData([...parsed, ...currentMessages]);
  }
}
```

---

## 10. 성능 최적화

### 위젯 리빌드 최소화
```dart
// 1. const 생성자 적극 활용
const AppButton(text: 'Submit');

// 2. Consumer 범위 최소화
// BAD: 전체 화면이 리빌드
class BadScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider); // 전체 리빌드
    return Column(children: [
      const HeavyWidget(),
      Text('$count'),
    ]);
  }
}

// GOOD: 필요한 부분만 Consumer로 감싸기
class GoodScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(children: [
      const HeavyWidget(), // 리빌드 안 됨
      Consumer(builder: (context, ref, child) {
        final count = ref.watch(counterProvider);
        return Text('$count');
      }),
    ]);
  }
}

// 3. select로 필요한 값만 감시
final nickname = ref.watch(
  profileProvider.select((p) => p.valueOrNull?.nickname),
);
```

### 리스트 성능
```dart
// ListView.builder (lazy rendering)
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageBubble(message: messages[index]);
  },
);

// 리스트 아이템에 key 필수
MessageBubble(
  key: ValueKey(message.id),
  message: message,
);
```

### 이미지 최적화
```dart
// 1. 적절한 크기로 요청 (Supabase Image Transform)
// 2. CachedNetworkImage 사용
// 3. memCacheWidth/memCacheHeight 설정
// 4. precacheImage로 미리 로드
precacheImage(
  CachedNetworkImageProvider(nextCardImageUrl),
  context,
);
```

---

## 11. 에러 핸들링 패턴

### Failure 계층
```dart
// core/error/failures.dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.auth(String message) = AuthFailure;
  const factory Failure.notFound(String message) = NotFoundFailure;
  const factory Failure.permission(String message) = PermissionFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}

extension FailureX on Failure {
  String get userMessage => switch (this) {
    ServerFailure(:final message) => '서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요.',
    NetworkFailure() => '인터넷 연결을 확인해주세요.',
    AuthFailure() => '로그인이 필요해요.',
    NotFoundFailure() => '요청하신 정보를 찾을 수 없어요.',
    PermissionFailure() => '접근 권한이 없어요.',
    UnexpectedFailure(:final message) => '예상치 못한 오류가 발생했어요.',
  };
}
```

### Either 패턴 (dartz)
```dart
// pubspec.yaml: dartz: ^0.10.1

// Repository에서 Either 반환
Future<Either<Failure, Profile>> getProfile(String userId) async {
  try {
    final data = await remoteDataSource.getProfile(userId);
    return Right(data.toEntity());
  } on SocketException {
    return const Left(Failure.network('No internet'));
  } on PostgrestException catch (e) {
    return Left(Failure.server(e.message));
  } catch (e) {
    return Left(Failure.unexpected(e.toString()));
  }
}

// Provider에서 처리
state = result.fold(
  (failure) => AsyncError(failure, StackTrace.current),
  (data) => AsyncData(data),
);
```

---

## 12. 테스팅 패턴

### 각 레이어별 테스트
```dart
// Domain Layer — Unit Test
test('GetSajuAnalysis should return SajuProfile', () async {
  when(mockRepository.getSajuAnalysis(
    birthDate: any(named: 'birthDate'),
    birthTime: any(named: 'birthTime'),
    birthCalendar: any(named: 'birthCalendar'),
  )).thenAnswer((_) async => Right(tSajuProfile));

  final result = await usecase(tParams);

  expect(result, Right(tSajuProfile));
  verify(mockRepository.getSajuAnalysis(
    birthDate: tParams.birthDate,
    birthTime: tParams.birthTime,
    birthCalendar: tParams.birthCalendar,
  ));
});

// Data Layer — Unit Test
test('SajuRemoteDataSource should call Edge Function', () async {
  when(mockSupabase.functions.invoke('saju-analysis', body: any(named: 'body')))
      .thenAnswer((_) async => FunctionResponse(
        status: 200,
        data: tSajuResponseJson,
      ));

  final result = await dataSource.getSajuAnalysis(
    birthDate: tBirthDate,
    birthTime: '午',
    birthCalendar: 'solar',
  );

  expect(result, isA<SajuProfileModel>());
});

// Presentation Layer — Widget Test
testWidgets('SajuResultScreen shows chart when data loaded', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sajuAnalysisProvider.overrideWith(
          () => MockSajuAnalysis()..state = AsyncData(tSajuProfile),
        ),
      ],
      child: const MaterialApp(home: SajuResultScreen()),
    ),
  );

  expect(find.byType(OhangRadarChart), findsOneWidget);
  expect(find.text(tSajuProfile.personalitySummary), findsOneWidget);
});
```

### pubspec.yaml 핵심 의존성
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Code Generation
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # Supabase
  supabase_flutter: ^2.5.0

  # Payments
  purchases_flutter: ^8.0.0

  # Auth
  kakao_flutter_sdk: ^1.9.0
  sign_in_with_apple: ^6.0.0
  google_sign_in: ^6.2.0

  # UI
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0
  image_cropper: ^5.0.0
  fl_chart: ^0.68.0          # 오행 차트
  lottie: ^3.1.0              # 애니메이션

  # Util
  dartz: ^0.10.1              # Either, functional
  intl: ^0.19.0               # 날짜 포맷
  share_plus: ^9.0.0          # SNS 공유
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0
  mocktail: ^1.0.0
```
