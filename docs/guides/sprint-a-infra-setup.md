# Sprint A — 인프라 설정 가이드

> 코드 준비는 완료되었습니다. 아래 체크리스트를 순서대로 진행하면 Auth가 작동합니다.

---

## 1. Apple Developer 설정

### 1-1. App ID에 Sign In with Apple 추가
- [ ] [Apple Developer > Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
- [ ] Bundle ID `com.dropdown.momo`의 App ID 선택
- [ ] Capabilities 탭에서 **Sign In with Apple** 활성화 → Save

### 1-2. Service ID 생성 (Supabase 웹 OAuth용)
- [ ] Identifiers → `+` → **Services IDs** 선택
- [ ] Description: `Momo Login`, Identifier: `com.dropdown.momo.web`
- [ ] 생성 후 **Sign In with Apple** 체크 → Configure
  - **Domains**: `csjdfvxyjnpmbkjbomyf.supabase.co`
  - **Return URLs**: `https://csjdfvxyjnpmbkjbomyf.supabase.co/auth/v1/callback`
- [ ] Save → Continue → Register

### 1-3. Key 생성 (Server-to-Server 인증)
- [ ] Keys → `+` → Key Name: `Momo Auth Key`
- [ ] **Sign In with Apple** 체크 → Configure → Primary App ID: `com.dropdown.momo`
- [ ] Register → **Key ID 기록**, `.p8` 파일 다운로드

### 메모할 값
| 항목 | 값 | 어디서? |
|------|-----|--------|
| **Team ID** | (10자리) | 우측 상단 계정 이름 옆 |
| **Service ID** | `com.dropdown.momo.web` | 위 1-2에서 생성 |
| **Key ID** | (10자리) | 위 1-3에서 생성 |
| **Private Key (.p8)** | 파일 내용 | 위 1-3에서 다운로드 |

---

## 2. Kakao Developers Console 설정

> 카카오 로그인은 Supabase OAuth 브라우저 플로우(`signInWithOAuth`)로 구현되어 있습니다.
> 별도 Kakao SDK 없이 Supabase Dashboard에 REST API 키만 등록하면 작동합니다.

### 2-1. 애플리케이션 생성
- [ ] [Kakao Developers](https://developers.kakao.com) 접속 → 로그인
- [ ] **내 애플리케이션** → **애플리케이션 추가하기**
- [ ] 앱 이름: `Momo`, 사업자명: `Dropdown`

### 2-2. 앱 키 확인
- [ ] 생성된 앱 선택 → **앱 키** 탭
- [ ] **REST API 키** 메모 (Supabase Client ID에 입력)
- [ ] **네이티브 앱 키** 메모 (참고용, 현재 미사용)

### 2-3. 카카오 로그인 활성화 + 동의항목
- [ ] 좌측 메뉴 → **카카오 로그인** → **활성화 설정** → **ON**
- [ ] **동의항목** 탭에서 설정:
  - 닉네임: **필수**
  - 프로필 사진: 선택
  - 카카오계정(이메일): **선택** (필수 권장)
  - 성별: 선택
  - 연령대: 선택

### 2-4. Client Secret 확인
- [ ] 좌측 메뉴 → **앱** → **플랫폼 키** (REST API 키 옆에 클라이언트 시크릿이 함께 표시됨)
- [ ] 또는 **카카오 로그인** → **고급** 탭에서 확인
- [ ] **클라이언트 시크릿** 값 메모

### 2-5. 플랫폼 등록
- [ ] 좌측 메뉴 → **플랫폼** 탭
- [ ] **iOS 플랫폼 등록**: Bundle ID = `com.dropdown.momo`
- [ ] **Android 플랫폼 등록**: 패키지명 = `com.dropdown.momo` + 키해시 등록
  - 키해시 생성: `keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | openssl dgst -sha1 -binary | openssl enc -base64`

### 2-6. Redirect URI 등록
- [ ] 좌측 메뉴 → **카카오 로그인** → **Redirect URI**
- [ ] 추가: `https://csjdfvxyjnpmbkjbomyf.supabase.co/auth/v1/callback`

### 메모할 값
| 항목 | 값 | 어디서? |
|------|-----|--------|
| **REST API 키** | (32자리) | 앱 키 탭 |
| **Client Secret** | (32자리) | 보안 탭에서 생성 |
| **네이티브 앱 키** | (참고용) | 앱 키 탭 |

---

## 3. Supabase Dashboard 설정

### 3-1. Apple Provider 활성화
- [ ] [Supabase Dashboard](https://supabase.com/dashboard/project/csjdfvxyjnpmbkjbomyf/auth/providers)
- [ ] Authentication → Providers → Apple → **Enable**
- [ ] Service ID (Client ID): `com.dropdown.momo.web` (위 1-2)
- [ ] Secret Key: `.p8` 파일 내용을 JWT로 생성하거나 직접 붙여넣기
  - Supabase가 자동 생성 지원: Team ID + Key ID + Private Key 입력
- [ ] Save

### 3-2. Kakao Provider 활성화
- [ ] Authentication → Providers → Kakao → **Enable**
- [ ] Client ID: REST API 키 (위 2-2)
- [ ] Client Secret: Client Secret (위 2-4)
- [ ] Save

### 3-3. Redirect URL 확인
- [ ] Authentication → URL Configuration
- [ ] Redirect URLs에 추가:
  - `com.dropdown.momo://login-callback`
- [ ] Site URL은 프로덕션 URL로 설정 (개발 중에는 기본값 유지)

---

## 4. Flutter 앱 빌드 시 환경 변수

```bash
# 이미 main.dart에 기본값이 있으므로, 커스텀 값이 필요할 때만:
flutter run \
  --dart-define=SUPABASE_URL=https://csjdfvxyjnpmbkjbomyf.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

---

## 4.5 Firebase Phone Auth 설정 (전화번호 인증용)

> 전화번호 인증은 **Firebase Phone Auth**를 사용합니다.
> 로그인은 Supabase Auth (Apple/Kakao), 전화번호 인증만 Firebase로 처리.
> 무료 10,000건/월, 한국 번호 정상 발송, 별도 SMS 서비스 불필요.

### 4.5-1. Firebase 프로젝트 생성
- [ ] [Firebase Console](https://console.firebase.google.com) 접속
- [ ] 프로젝트 추가 → 이름: `momo-app`
- [ ] Google Analytics 활성화 (추후 데이터 분석에 활용)

### 4.5-2. Firebase Authentication 활성화
- [ ] Firebase Console → Authentication → Sign-in method
- [ ] **전화** (Phone) 활성화
- [ ] 테스트 전화번호 추가 (개발용): `+82 10-1234-5678` → OTP: `123456`

### 4.5-3. iOS 앱 등록
- [ ] Firebase Console → 프로젝트 설정 → 앱 추가 → iOS+
- [ ] Bundle ID: `com.dropdown.momo`
- [ ] `GoogleService-Info.plist` 다운로드 → `ios/Runner/` 에 배치
- [ ] Xcode에서 `GoogleService-Info.plist`을 Runner 타겟에 추가
- [ ] URL Schemes에 `REVERSED_CLIENT_ID` 추가 (plist 내 값 참조)
- [ ] APNs 설정은 선택사항 (미설정 시 reCAPTCHA fallback 자동 사용)

### 4.5-4. Android 앱 등록
- [ ] Firebase Console → 프로젝트 설정 → 앱 추가 → Android
- [ ] 패키지명: `com.dropdown.momo`
- [ ] SHA-1 등록: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
- [ ] `google-services.json` 다운로드 → `android/app/` 에 배치

### 4.5-5. Flutter 패키지 추가 (아리 담당)
- [ ] `firebase_core` + `firebase_auth` pubspec.yaml에 추가
- [ ] `flutterfire configure` 실행 (또는 수동 설정)
- [ ] BYPASS-6/7 코드를 Firebase verifyPhoneNumber()로 교체

### 메모할 값
| 항목 | 값 | 어디서? |
|------|-----|--------|
| **GoogleService-Info.plist** | 파일 | Firebase Console → 프로젝트 설정 → iOS 앱 |
| **google-services.json** | 파일 | Firebase Console → 프로젝트 설정 → Android 앱 |
| **테스트 전화번호** | +82 10-1234-5678 / 123456 | Firebase Console → Authentication |

---

## 5. 테스트 절차

### iOS
1. `fvm flutter build ios --no-codesign --debug` — 빌드 성공 확인
2. Xcode에서 Runner.entitlements가 프로젝트에 정상 참조되는지 확인
3. 시뮬레이터/실기기에서 Apple Sign In 버튼 → Apple 로그인 시트 표시 확인
4. 카카오 로그인 버튼 → 브라우저 OAuth 플로우 → 앱으로 리다이렉트 확인

### Android
1. `fvm flutter build apk --debug` — 빌드 성공 확인
2. 에뮬레이터/실기기에서 카카오 로그인 → 브라우저 OAuth → 앱으로 리다이렉트 확인

### SMS 인증 (Firebase Phone Auth)
1. 온보딩 Step 4에서 전화번호 입력 → "인증번호 받기" 클릭
2. 실제 SMS 수신 확인 (Firebase Phone Auth 연동 후)
3. OTP 입력 → 인증 성공 확인
4. `profiles` 테이블에 `phone`, `phone_verified_at` 설정 확인

### 공통
- Supabase Dashboard의 Auth → Users에서 신규 유저 생성 확인
- `profiles` 테이블에 `auth_id`가 정상 매핑되는지 확인
- 로그아웃 후 재로그인 시 세션 유지 확인

---

## 6. 완료 후 BYPASS 제거

Auth 연동이 확인되면 아래 디버그 바이패스를 제거합니다:
- `TODO(PROD)` / `BYPASS-` 키워드로 코드 검색
- 바이패스 목록: `docs/dev-log/2026-02-26-debug-bypass.md` 참조

| BYPASS | 위치 | 설명 |
|--------|------|------|
| BYPASS-1 | auth 관련 | 로그인 바이패스 |
| BYPASS-2~5 | 각 feature | Auth 의존 바이패스 |
| BYPASS-6 | onboarding SMS | SMS 발송 mock → Firebase `verifyPhoneNumber()` |
| BYPASS-7 | onboarding SMS | OTP 검증 mock → Firebase `signInWithCredential()` → Supabase profiles 저장 |
| BYPASS-8 | router | publicPaths 확장 |
