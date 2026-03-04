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

### 2-4. Client Secret 발급
- [ ] 좌측 메뉴 → **카카오 로그인** → **보안** 탭
- [ ] **Client Secret** → **코드 생성** → 생성된 시크릿 메모
- [ ] 활성화 상태: **사용함**

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

## 4.5 CoolSMS + Supabase Send SMS Hook 설정 (SMS 인증용)

> SMS 인증은 **Supabase Phone Auth + Send SMS Hook + CoolSMS** 방식입니다.
> OTP 생성/검증은 Supabase가 자동 처리, SMS 발송만 CoolSMS(한국 010 번호)로 위임.
> Twilio 해외번호 스팸 위험 없음.

### 4.5-1. CoolSMS 계정 생성
- [ ] [CoolSMS Console](https://coolsms.co.kr) 가입
- [ ] API Key + API Secret 발급 (대시보드 → 개발/연동 → API Key 관리)
- [ ] 발신번호 등록 (대시보드 → 문자보내기 → 발신번호 관리 → 010-XXXX-XXXX 등록)

### 4.5-2. Supabase Phone Provider 활성화
- [ ] [Supabase Dashboard](https://supabase.com/dashboard/project/csjdfvxyjnpmbkjbomyf/auth/providers) → Authentication → Providers
- [ ] **Phone** 활성화
- [ ] SMS OTP Expiration: **300** (5분) 으로 설정 권장

### 4.5-3. Edge Function 배포 + Send SMS Hook 연결
- [ ] `send-sms-hook` Edge Function 배포: `supabase functions deploy send-sms-hook`
- [ ] Supabase 시크릿 등록:
  ```bash
  supabase secrets set COOLSMS_API_KEY=your_api_key
  supabase secrets set COOLSMS_API_SECRET=your_api_secret
  supabase secrets set COOLSMS_SENDER=01012345678
  ```
- [ ] [Supabase Dashboard](https://supabase.com/dashboard/project/csjdfvxyjnpmbkjbomyf/auth/hooks) → Authentication → Hooks
- [ ] **Send SMS** Hook 활성화
- [ ] Hook Type: **HTTP** 선택
- [ ] URL: Edge Function URL (`https://csjdfvxyjnpmbkjbomyf.supabase.co/functions/v1/send-sms-hook`)
- [ ] Secret 설정 (webhook 검증용, `v1,whsec_<base64-secret>` 형식)

### 메모할 값
| 항목 | 값 | 어디서? |
|------|-----|--------|
| **CoolSMS API Key** | - | CoolSMS 대시보드 → 개발/연동 |
| **CoolSMS API Secret** | - | CoolSMS 대시보드 → 개발/연동 |
| **발신번호** | 010-XXXX-XXXX | CoolSMS → 발신번호 관리 |
| **SMS Hook Secret** | v1,whsec_xxx | 직접 생성 (base64 랜덤) |

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

### SMS 인증
1. 온보딩 Step 4에서 전화번호 입력 → "인증번호 받기" 클릭
2. 실제 SMS 수신 확인 (CoolSMS + Send SMS Hook 연동 후)
3. OTP 입력 → 인증 성공 확인
4. Supabase Dashboard → Auth → Users에서 `phone` 필드 업데이트 확인
5. `profiles` 테이블에 `phone_verified_at` 설정 확인

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
| BYPASS-6 | onboarding SMS | SMS 발송 mock → `supabase.auth.updateUser(phone:)` + Send SMS Hook → CoolSMS |
| BYPASS-7 | onboarding SMS | OTP 검증 mock → `supabase.auth.verifyOTP()` (Supabase 자동) |
| BYPASS-8 | router | publicPaths 확장 |
