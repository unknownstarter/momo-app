# Momo 인증/검증 백엔드 아키텍처 설계서

> **작성일**: 2026-03-03
> **작성**: 아리 (Backend Developer)
> **요청**: 노아님
> **상태**: 설계 완료 — 구현 승인 대기

---

## 목차

1. [전체 아키텍처 개요](#1-전체-아키텍처-개요)
2. [카카오 로그인 통합](#2-카카오-로그인-통합)
3. [SMS 전화번호 인증](#3-sms-전화번호-인증)
4. [데이터베이스 스키마 변경](#4-데이터베이스-스키마-변경)
5. [본인인증 배지 시스템](#5-본인인증-배지-시스템)
6. [Edge Functions 설계](#6-edge-functions-설계)
7. [보안 및 컴플라이언스](#7-보안-및-컴플라이언스)
8. [Flutter 코드 변경 요약](#8-flutter-코드-변경-요약)
9. [구현 로드맵](#9-구현-로드맵)

---

## 1. 전체 아키텍처 개요

### 1.1 인증 플로우 전체 그림

```
┌─────────────────────────────────────────────────────────────────┐
│                         사용자 여정                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌───────────┐ │
│  │ 로그인    │───>│ 온보딩    │───>│ SMS 인증  │───>│ 운명 분석  │ │
│  │ Apple/   │    │ 이름/성별/ │    │ 전화번호  │    │ 사주+관상  │ │
│  │ Kakao    │    │ 생년월일   │    │ 본인확인  │    │           │ │
│  └──────────┘    └──────────┘    └──────────┘    └───────────┘ │
│       │                               │                         │
│       ▼                               ▼                         │
│  Supabase Auth               phone_verifications 테이블         │
│  (JWT 발급)                   profiles.phone 업데이트            │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    선택적 본인인증 (추후)                    │  │
│  │  PASS/KCB → identity_verifications 테이블 → 배지 표시       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 변경 요약

| 항목 | Before | After |
|------|--------|-------|
| 소셜 로그인 | Apple + Google | Apple + **Kakao** |
| 전화번호 인증 | 없음 | SMS OTP (**Firebase Phone Auth** — 인증만, 로그인은 Supabase) |
| 본인인증 | 없음 | PASS 연동 (추후) |
| profiles 컬럼 | 기본 + 사주 | + 상세 프로필 필드 추가 |

---

## 2. 카카오 로그인 통합

### 2.1 방식 비교 및 결정

| 방식 | 장점 | 단점 | **판정** |
|------|------|------|---------|
| **A. Supabase 네이티브 OIDC** | 설정 간단, Supabase Auth가 관리 | Kakao가 Supabase 기본 Provider 목록에 없음 | X |
| **B. Custom OIDC Provider** | Supabase의 Custom OIDC 기능 활용 | Kakao OIDC 설정이 불안정할 수 있음 | △ |
| **C. kakao_flutter_sdk + signInWithIdToken** | 안정적, 한국 시장 검증됨, 카카오 공식 SDK | 클라이언트에서 카카오 SDK 의존 | **채택** |

**결정: 방식 C — `kakao_flutter_sdk`로 카카오 로그인 → ID Token 획득 → Supabase `signInWithIdToken(provider: OAuthProvider.kakao)`**

> Supabase GoTrue v2.132.0+부터 `OAuthProvider.kakao`가 공식 지원됩니다.
> Supabase Dashboard > Authentication > Providers > Kakao에서 설정 가능.

### 2.2 카카오 개발자 콘솔 설정

```
1. https://developers.kakao.com 접속
2. 애플리케이션 추가하기
3. 앱 키 확인:
   - REST API 키 (Supabase에 등록할 Client ID)
   - Native 앱 키 (Flutter SDK에 사용)

4. 카카오 로그인 > 활성화: ON
5. 동의항목 설정:
   - 닉네임: 필수
   - 프로필 사진: 선택
   - 카카오계정(이메일): 선택 (필수 동의로 변경 권장)
   - 성별: 선택
   - 연령대: 선택
   - 전화번호: 별도 비즈앱 심사 필요 (SMS 인증으로 대체)

6. 플랫폼 등록:
   - iOS: Bundle ID = com.dropdown.momo
   - Android: 패키지명 = com.dropdown.momo + 키해시 등록

7. Redirect URI 설정:
   - https://ejngitwtzecqbhbqfnsc.supabase.co/auth/v1/callback
```

### 2.3 Supabase Dashboard 설정

```
Authentication > Providers > Kakao

- Enabled: ON
- Client ID: {카카오 REST API 키}
- Client Secret: {카카오 REST API 시크릿}
- Redirect URL: https://ejngitwtzecqbhbqfnsc.supabase.co/auth/v1/callback
```

### 2.4 카카오에서 획득 가능한 사용자 데이터

| 필드 | 획득 가능 | 조건 |
|------|----------|------|
| 닉네임 | O | 기본 동의 |
| 프로필 사진 | O | 선택 동의 |
| 이메일 | O | 선택 동의 (사업자 필요 시 필수 가능) |
| 성별 | O | 선택 동의 |
| 연령대 | O | 선택 동의 |
| 생년월일 | O | 선택 동의 |
| 전화번호 | X (비즈앱 심사) | → SMS 인증으로 대체 |
| CI (연계정보) | X (비즈앱 심사) | → PASS 인증으로 대체 |

### 2.5 Flutter 토큰 교환 플로우

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│   Flutter   │     │   Kakao    │     │  Supabase  │
│   Client    │     │   Server   │     │   Auth     │
└──────┬─────┘     └──────┬─────┘     └──────┬─────┘
       │                   │                   │
       │ 1. 카카오 로그인   │                   │
       │ ────────────────> │                   │
       │                   │                   │
       │ 2. Access Token   │                   │
       │   + ID Token      │                   │
       │ <──────────────── │                   │
       │                   │                   │
       │ 3. signInWithIdToken(                 │
       │    provider: kakao,                   │
       │    idToken: kakaoIdToken)             │
       │ ─────────────────────────────────────>│
       │                   │                   │
       │ 4. Supabase JWT   │                   │
       │ <─────────────────────────────────────│
       │                   │                   │
```

### 2.6 Flutter 코드: AuthRemoteDatasource 카카오 추가

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

/// Kakao Sign In → Supabase Auth
Future<AuthResponse> signInWithKakao() async {
  try {
    // 1. 카카오톡 설치 여부에 따라 로그인 방식 분기
    kakao.OAuthToken oauthToken;
    if (await kakao.isKakaoTalkInstalled()) {
      oauthToken = await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      oauthToken = await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    final idToken = oauthToken.idToken;
    if (idToken == null) {
      throw AuthFailure.socialLoginFailed('Kakao', 'ID Token을 받지 못했습니다.');
    }

    // 2. Supabase Auth에 ID Token 전달
    return await _auth.signInWithIdToken(
      provider: OAuthProvider.kakao,
      idToken: idToken,
      accessToken: oauthToken.accessToken,
    );
  } on AuthFailure {
    rethrow;
  } catch (e) {
    throw AuthFailure.socialLoginFailed('Kakao', e);
  }
}
```

### 2.7 pubspec.yaml 변경

```yaml
# 제거
# google_sign_in: ^6.2.2

# 추가
kakao_flutter_sdk_user: ^1.9.6
```

### 2.8 iOS 설정 (Info.plist)

```xml
<!-- ios/Runner/Info.plist 추가 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaoplus</string>
</array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao{NATIVE_APP_KEY}</string>
    </array>
  </dict>
</array>
```

### 2.9 main.dart 초기화

```dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  kakao.KakaoSdk.init(nativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'));

  // ... Supabase 초기화 등
}
```

---

## 3. SMS 전화번호 인증

### 3.1 방식 비교 (2026-03-04 최종 결정)

| 방식 | 장점 | 단점 | 한국 시장 | 비용 | **판정** |
|------|------|------|----------|------|---------|
| A. Supabase Phone Auth + Twilio | 설정 간단 | **해외번호 → 한국 스팸 차단 위험** | X (스팸) | 건당 ~$0.05 | X |
| ~~B. Edge Function 2개 + CoolSMS (초기안)~~ | 한국 최적화 | Edge Function 2개 + 커스텀 테이블 + OTP 직접 관리 | O | 건당 ~20원 | X (과잉) |
| ~~C. Supabase Phone Auth + Send SMS Hook + CoolSMS~~ | OTP 자동 관리 + 한국 010 발송 | CoolSMS 계정 필요 + Supabase Phone Provider 설정 복잡 | O | 건당 ~20원 | X (Supabase Phone Provider 설정 장벽) |
| D. Edge Function + NHN Cloud | 대규모 지원 | 설정 복잡 | O | 건당 ~20원 | X |
| **E. Firebase Phone Auth** | **무료 10K/월, 한국 정상 발송, 별도 SMS 서비스 불필요, Firebase 에코시스템(Analytics/FCM) 활용** | Firebase 의존성 추가 | **O** | **무료 (10K/월)** | **✅ 채택** |

**최종 결정: 방식 E — Firebase Phone Auth (인증만, 로그인은 Supabase)**

핵심 이유:
1. **무료 10,000건/월** — CoolSMS 건당 과금 불필요
2. **별도 SMS 서비스 가입 불필요** — Firebase Console에서 Phone Auth 토글만 켜면 끝
3. **한국 번호 정상 발송** — Twilio 해외번호 스팸 위험 없음
4. **Firebase 에코시스템 활용** — 추후 Analytics, FCM 등에도 사용
5. **로그인/인증 분리** — 로그인은 Supabase Auth (Apple/Kakao), 전화번호 인증만 Firebase
6. Supabase Phone Provider 설정 장벽 해결 (SMS 제공자 선택 문제 없음)

### 3.2 SMS 인증 플로우 (Firebase Phone Auth)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Flutter  │     │ Firebase │     │ Supabase │
│  Client   │     │   Auth   │     │    DB    │
└─────┬────┘     └────┬─────┘     └────┬─────┘
      │                │                │
      │ 1. verifyPhone │                │
      │   (E.164)      │                │
      │ ──────────────>│                │
      │                │                │
      │ 2. SMS 발송    │                │
      │   (Firebase    │                │
      │    자동 처리)   │                │
      │                │                │
      │ 3. codeSent    │                │
      │   (verifyId)   │                │
      │ <──────────────│                │
      │                │                │
      │ 4. signIn      │                │
      │  WithCredential│                │
      │   (OTP 검증)   │                │
      │ ──────────────>│                │
      │                │                │
      │ 5. 인증 성공    │                │
      │ <──────────────│                │
      │                │                │
      │ 6. profiles    │                │
      │   .update()    │                │
      │ ──────────────────────────────>│
      │                │                │
      │ 7. Firebase    │                │
      │   signOut()    │                │
      │ ──────────────>│                │
```

**Flutter 코드 (Sprint A 실연동 시):**
```dart
// Step 1: Firebase Phone Auth — OTP 발송
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: PhoneUtils.toE164(phoneNumber),
  verificationCompleted: (PhoneAuthCredential credential) async {
    // Android 자동 인증 (optional)
    await FirebaseAuth.instance.signInWithCredential(credential);
  },
  verificationFailed: (FirebaseAuthException e) {
    // 에러 처리
  },
  codeSent: (String verificationId, int? resendToken) {
    // verificationId 저장 → OTP 입력 UI 표시
    _verificationId = verificationId;
  },
  codeAutoRetrievalTimeout: (String verificationId) {
    _verificationId = verificationId;
  },
);

// Step 2: OTP 검증
final credential = PhoneAuthProvider.credential(
  verificationId: _verificationId,
  smsCode: otpCode,
);
await FirebaseAuth.instance.signInWithCredential(credential);

// Step 3: profiles 테이블에 phone 저장
await supabase.from('profiles').update({
  'phone': PhoneUtils.toE164(phoneNumber),
  'phone_verified_at': DateTime.now().toIso8601String(),
  'verification_level': 'phone',
}).eq('id', userId);

// Step 4: Firebase 로그아웃 (인증만 사용, 로그인은 Supabase)
await FirebaseAuth.instance.signOut();
```

### 3.3 전화번호 저장 정책

```
입력: 010-1234-5678 또는 01012345678
정규화: +821012345678 (E.164 형식)
저장: auth.users.phone = '+821012345678' (Supabase Auth 자동)
      profiles.phone = '+821012345678' (앱에서 별도 업데이트)
```

### 3.4 레이트 리밋 (Supabase 내장)

Supabase Phone Auth 기본 정책:
- 같은 번호 재발송: **60초** 최소 간격 (Supabase 내장)
- OTP 유효 시간: **1시간** (Supabase Dashboard에서 5분으로 조정 권장)
- 추가 레이트 리밋: Supabase Dashboard → Auth → Rate Limits에서 설정

---

## 4. 데이터베이스 스키마 변경

### 4.1 마이그레이션 SQL

```sql
-- ============================================================
-- 20260303000001_auth_profile_enhancement.sql
-- 인증/검증/프로필 확장 마이그레이션
-- ============================================================

-- ============================================================
-- 1. pgcrypto 확장 (OTP 해싱용) — Supabase에 이미 설치됨
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 2. profiles 테이블 — 신규 컬럼 추가
-- ============================================================

-- 2-1. 전화번호 인증 관련
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone_verified_at timestamptz,
  ADD COLUMN IF NOT EXISTS verification_level text NOT NULL DEFAULT 'none'
    CHECK (verification_level IN ('none', 'phone', 'identity'));

-- 2-2. 상세 프로필 필드
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS self_introduction text
    CHECK (char_length(self_introduction) <= 1000),
  ADD COLUMN IF NOT EXISTS height_cm smallint
    CHECK (height_cm IS NULL OR (height_cm BETWEEN 100 AND 250)),
  ADD COLUMN IF NOT EXISTS body_type text
    CHECK (body_type IS NULL OR body_type IN (
      'slim', 'slender', 'average', 'muscular', 'chubby', 'curvy'
    )),
  ADD COLUMN IF NOT EXISTS region_sido text,
  ADD COLUMN IF NOT EXISTS region_sigungu text,
  ADD COLUMN IF NOT EXISTS hobbies text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS ideal_type text
    CHECK (char_length(ideal_type) <= 300),
  ADD COLUMN IF NOT EXISTS identity_verified_at timestamptz;

-- 2-3. 기존 height 컬럼이 있으므로 height_cm으로 데이터 이전
-- (기존 height int → 새 height_cm smallint 마이그레이션)
UPDATE public.profiles
SET height_cm = height::smallint
WHERE height IS NOT NULL AND height_cm IS NULL;

-- 2-4. 전화번호 유니크 인덱스 (하나의 번호 = 하나의 계정)
-- 기존 phone 컬럼은 이미 존재 (20260225000002 마이그레이션)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_phone_unique
  ON public.profiles(phone)
  WHERE phone IS NOT NULL AND deleted_at IS NULL;

-- 2-5. 지역 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_profiles_region
  ON public.profiles(region_sido, region_sigungu)
  WHERE is_matchable = true AND deleted_at IS NULL;

-- 2-6. 인증 레벨 인덱스
CREATE INDEX IF NOT EXISTS idx_profiles_verification
  ON public.profiles(verification_level)
  WHERE verification_level != 'none';

-- ============================================================
-- 3. phone_verifications 테이블 — SMS OTP 관리
-- ============================================================
CREATE TABLE IF NOT EXISTS public.phone_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  phone_e164 text NOT NULL,               -- E.164 형식 (+821012345678)
  code_hash text NOT NULL,                -- SHA256(code + salt)
  salt text NOT NULL,                     -- 코드별 고유 솔트
  attempts smallint NOT NULL DEFAULT 0,   -- 검증 시도 횟수
  max_attempts smallint NOT NULL DEFAULT 5,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'expired', 'blocked')),
  ip_address inet,                        -- 요청 IP (레이트 리밋용)
  expires_at timestamptz NOT NULL,        -- OTP 만료 시각
  verified_at timestamptz,                -- 검증 성공 시각
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_phone_verif_user ON public.phone_verifications(user_id, created_at DESC);
CREATE INDEX idx_phone_verif_phone ON public.phone_verifications(phone_e164, created_at DESC);
CREATE INDEX idx_phone_verif_ip ON public.phone_verifications(ip_address, created_at DESC);

-- RLS 활성화
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;

-- phone_verifications는 Edge Function(service_role)에서만 접근
-- 일반 유저는 직접 접근 불가 (보안)
-- 본인 것만 SELECT 허용 (상태 확인용)
CREATE POLICY "phone_verif_select_own" ON public.phone_verifications
  FOR SELECT USING (user_id = public.current_profile_id());

-- INSERT/UPDATE/DELETE는 service_role(Edge Function)에서만 가능
-- 클라이언트에서 직접 조작 불가

-- ============================================================
-- 4. identity_verifications 테이블 — 본인인증 기록 (Phase 2)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.identity_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('pass', 'kcb', 'nice')),
  ci text,                                -- 연계정보 (암호화 저장)
  di text,                                -- 중복확인정보 (암호화 저장)
  verified_name text,                     -- 인증된 실명 (암호화 저장)
  verified_birth_date date,               -- 인증된 생년월일
  verified_gender text CHECK (verified_gender IN ('male', 'female')),
  verified_phone text,                    -- 인증된 전화번호 (E.164)
  verification_result jsonb,              -- 원본 응답 (암호화 저장)
  status text NOT NULL DEFAULT 'verified'
    CHECK (status IN ('verified', 'revoked', 'expired')),
  verified_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,                 -- 인증 만료일 (보통 1년)
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_identity_verif_ci
  ON public.identity_verifications(ci)
  WHERE ci IS NOT NULL AND status = 'verified';

CREATE INDEX idx_identity_verif_user
  ON public.identity_verifications(user_id, created_at DESC);

ALTER TABLE public.identity_verifications ENABLE ROW LEVEL SECURITY;

-- 본인 것만 SELECT
CREATE POLICY "identity_verif_select_own" ON public.identity_verifications
  FOR SELECT USING (user_id = public.current_profile_id());

-- ============================================================
-- 5. sms_rate_limits 뷰 — 레이트 리밋 조회용
-- ============================================================
CREATE OR REPLACE VIEW public.sms_rate_limit_check AS
SELECT
  phone_e164,
  ip_address,
  user_id,
  COUNT(*) FILTER (WHERE created_at > now() - interval '24 hours') AS daily_count,
  MAX(created_at) AS last_sent_at,
  COUNT(*) FILTER (
    WHERE status = 'blocked'
    AND created_at > now() - interval '30 minutes'
  ) AS recent_blocks
FROM public.phone_verifications
GROUP BY phone_e164, ip_address, user_id;

-- ============================================================
-- 6. 트리거 업데이트: is_matchable에 전화번호 인증 조건 추가
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_update_matchable()
RETURNS trigger AS $$
BEGIN
  -- is_saju_complete 업데이트
  NEW.is_saju_complete := (NEW.saju_profile_id IS NOT NULL);

  NEW.is_matchable := (
    NEW.is_saju_complete = true
    AND NEW.is_profile_complete = true
    AND cardinality(COALESCE(NEW.profile_images, '{}')) >= 2
    AND NEW.occupation IS NOT NULL
    AND NEW.location IS NOT NULL
    AND NEW.height IS NOT NULL
    AND NEW.bio IS NOT NULL
    AND NEW.phone IS NOT NULL            -- 전화번호 인증 필수
    AND NEW.phone_verified_at IS NOT NULL -- 인증 완료 확인
    AND NEW.deleted_at IS NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 재생성 (기존 트리거 교체)
DROP TRIGGER IF EXISTS trg_update_matchable ON public.profiles;
CREATE TRIGGER trg_update_matchable
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_matchable();

-- ============================================================
-- 7. profiles 테이블 RLS 업데이트 — 신규 컬럼 보호
-- ============================================================

-- 전화번호는 본인만 조회 가능 (매칭 상대에게 노출 안 됨)
-- 기존 profiles_select_own_or_matchable 정책에서
-- 매칭 상대 조회 시 phone 컬럼이 보이지 않도록 뷰 또는 함수로 감싸는 것을 권장
-- → 당장은 클라이언트에서 phone 필드를 표시하지 않는 것으로 처리

-- ============================================================
-- 8. 한국 지역(시도+시군구) 참조 데이터 (간소화)
-- ============================================================
-- 실제로는 별도 regions 테이블을 만들 수 있지만,
-- 클라이언트에서 하드코딩하는 것이 더 빠르고 간단함.
-- 필요 시 아래 테이블 생성:

-- CREATE TABLE IF NOT EXISTS public.regions (
--   id serial PRIMARY KEY,
--   sido text NOT NULL,
--   sigungu text NOT NULL,
--   UNIQUE(sido, sigungu)
-- );
-- INSERT INTO public.regions (sido, sigungu) VALUES
--   ('서울', '강남구'), ('서울', '서초구'), ...;

-- ============================================================
-- 9. Supabase 테이블명 상수 추가 알림
-- ============================================================
-- app_constants.dart의 SupabaseTables에 추가 필요:
-- static const phoneVerifications = 'phone_verifications';
-- static const identityVerifications = 'identity_verifications';
```

### 4.2 profiles 테이블 최종 스키마 (변경 후)

```
profiles
├── id                    uuid PK
├── auth_id               uuid UNIQUE NOT NULL → auth.users(id)
├── name                  text NOT NULL
├── birth_date            date NOT NULL
├── birth_time            time
├── gender                text NOT NULL ('male'|'female')
├── email                 text
├── phone                 text                    -- E.164 형식
├── phone_verified_at     timestamptz             -- 전화번호 인증 시각
├── verification_level    text DEFAULT 'none'     -- none|phone|identity
├── profile_images        text[] DEFAULT '{}'
├── bio                   text
├── self_introduction     text (max 1000)         -- NEW: 상세 자기소개
├── interests             text[] DEFAULT '{}'
├── hobbies               text[] DEFAULT '{}'     -- NEW: 취미 태그
├── ideal_type            text (max 300)          -- NEW: 이상형
├── height                int                     -- 기존 유지 (호환)
├── height_cm             smallint                -- NEW: 명시적 cm
├── body_type             text                    -- NEW: 체형
├── location              text                    -- 기존 유지 (호환)
├── region_sido           text                    -- NEW: 시도
├── region_sigungu        text                    -- NEW: 시군구
├── occupation            text
├── religion              text
├── mbti                  text
├── drinking              text
├── smoking               text
├── dating_style          text
├── dominant_element      text
├── character_type        text
├── saju_profile_id       uuid → saju_profiles(id)
├── is_selfie_verified    boolean DEFAULT false
├── is_profile_complete   boolean DEFAULT false
├── is_saju_complete      boolean DEFAULT false
├── is_matchable          boolean DEFAULT false
├── is_premium            boolean DEFAULT false
├── point_balance         int DEFAULT 0
├── identity_verified_at  timestamptz             -- NEW: 본인인증 시각
├── created_at            timestamptz
├── last_active_at        timestamptz
└── deleted_at            timestamptz
```

---

## 5. 본인인증 배지 시스템 (Phase 2)

### 5.1 한국 본인인증 서비스 비교

| 서비스 | 특징 | 비용 | SDK | **적합도** |
|--------|------|------|-----|-----------|
| **PASS** | 통신3사 공동, 점유율 1위 | 건당 ~100원 | REST API | **최적** |
| **KCB** | 오래된 업체, 안정적 | 건당 ~80원 | REST API | 적합 |
| **NICE** | 신용정보 기반 | 건당 ~100원 | REST API | 적합 |

**결정: PASS 인증 (Phase 2에서 구현)**

### 5.2 인증 레벨 & 배지 체계

```
┌─────────────────────────────────────────────┐
│              인증 레벨 (verification_level)    │
├─────────────────────────────────────────────┤
│                                             │
│  none      → 배지 없음                       │
│  phone     → 📱 전화번호 인증 완료 (기본)      │
│  identity  → 🛡️ 본인인증 완료 (프리미엄)      │
│                                             │
└─────────────────────────────────────────────┘
```

### 5.3 매칭 카드에서의 배지 표시

```dart
/// 매칭 카드 배지 위젯
Widget buildVerificationBadge(String verificationLevel) {
  return switch (verificationLevel) {
    'identity' => _Badge(
      icon: Icons.verified_user,
      label: '본인인증',
      color: Color(0xFF4CAF50),       // 초록
    ),
    'phone' => _Badge(
      icon: Icons.phone_android,
      label: '번호인증',
      color: Color(0xFF89B0CB),       // 쪽빛 하늘
    ),
    _ => SizedBox.shrink(),           // 배지 없음
  };
}
```

### 5.4 본인인증 플로우 (Phase 2)

```
1. 프로필 > "본인인증 하기" 버튼
2. Edge Function → PASS API 호출 → 인증 URL 반환
3. WebView에서 PASS 인증 진행 (통신사 인증)
4. 콜백 → Edge Function → CI/DI 수신
5. identity_verifications 테이블에 저장
6. profiles.verification_level = 'identity' 업데이트
7. 매칭 카드에 배지 표시
```

---

## 6. Edge Functions 설계

> **변경 (2026-03-03)**: SMS 인증을 Supabase Phone Auth로 전환했으므로,
> `send-sms-verification`과 `verify-sms-code` Edge Function은 **더 이상 필요하지 않습니다.**
> 아래는 기존 설계를 아카이브 목적으로 유지합니다. (접기 가능)

<details>
<summary>📦 아카이브: 기존 CoolSMS Edge Function 설계 (사용하지 않음)</summary>

### 6.1 `send-sms-verification` — SMS 발송 (❌ 폐기 → Supabase `updateUser` 대체)

```typescript
// supabase/functions/send-sms-verification/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHash, randomBytes } from 'node:crypto';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// CoolSMS API
const COOLSMS_API_KEY = Deno.env.get('COOLSMS_API_KEY')!;
const COOLSMS_API_SECRET = Deno.env.get('COOLSMS_API_SECRET')!;
const COOLSMS_SENDER = Deno.env.get('COOLSMS_SENDER')!; // 발신번호

interface SendRequest {
  phone: string; // 010-1234-5678 또는 01012345678
}

// 전화번호 → E.164 정규화
function normalizePhone(raw: string): string {
  const digits = raw.replace(/[^0-9]/g, '');
  if (digits.startsWith('010') && digits.length === 11) {
    return `+82${digits.slice(1)}`; // +821012345678
  }
  if (digits.startsWith('82') && digits.length === 12) {
    return `+${digits}`;
  }
  throw new Error('올바른 한국 휴대폰 번호를 입력해주세요.');
}

// 6자리 OTP 생성
function generateOTP(): string {
  const num = parseInt(randomBytes(4).toString('hex'), 16);
  return String(num % 1000000).padStart(6, '0');
}

// OTP 해싱
function hashOTP(code: string, salt: string): string {
  return createHash('sha256').update(code + salt).digest('hex');
}

// CoolSMS 발송
async function sendCoolSMS(to: string, message: string): Promise<void> {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const salt = randomBytes(16).toString('hex');
  const signature = createHash('sha256')
    .update(timestamp + salt)
    .digest('hex');

  const response = await fetch('https://api.coolsms.co.kr/messages/v4/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `HMAC-SHA256 apiKey=${COOLSMS_API_KEY}, date=${timestamp}, salt=${salt}, signature=${signature}`,
    },
    body: JSON.stringify({
      message: {
        to: to.replace('+82', '0'), // CoolSMS는 국내 형식
        from: COOLSMS_SENDER,
        text: message,
      },
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`SMS 발송 실패: ${err}`);
  }
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. 인증 확인
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: '인증이 필요합니다.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Supabase 클라이언트 (service_role)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 3. 현재 유저 확인
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    );
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: '유효하지 않은 세션입니다.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. 요청 파싱
    const body: SendRequest = await req.json();
    const phoneE164 = normalizePhone(body.phone);

    // 5. 유저 프로필 조회
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_id', user.id)
      .single();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: '프로필을 찾을 수 없습니다.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 6. 전화번호 중복 체크 (다른 유저가 이미 인증한 번호)
    const { data: existingPhone } = await supabase
      .from('profiles')
      .select('id')
      .eq('phone', phoneE164)
      .neq('id', profile.id)
      .is('deleted_at', null)
      .maybeSingle();

    if (existingPhone) {
      return new Response(
        JSON.stringify({ error: '이미 다른 계정에서 사용 중인 번호입니다.' }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7. 레이트 리밋 체크
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';

    // 7-1. 같은 번호 60초 간격
    const { data: recentForPhone } = await supabase
      .from('phone_verifications')
      .select('created_at')
      .eq('phone_e164', phoneE164)
      .gte('created_at', new Date(Date.now() - 60_000).toISOString())
      .limit(1);

    if (recentForPhone && recentForPhone.length > 0) {
      return new Response(
        JSON.stringify({ error: '잠시 후 다시 시도해주세요. (60초 간격)', retryAfter: 60 }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7-2. 같은 번호 일일 5회
    const { count: dailyPhoneCount } = await supabase
      .from('phone_verifications')
      .select('id', { count: 'exact', head: true })
      .eq('phone_e164', phoneE164)
      .gte('created_at', new Date(Date.now() - 86_400_000).toISOString());

    if ((dailyPhoneCount ?? 0) >= 5) {
      return new Response(
        JSON.stringify({ error: '오늘 인증 요청 횟수를 초과했습니다. 내일 다시 시도해주세요.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7-3. 같은 유저 일일 5회
    const { count: dailyUserCount } = await supabase
      .from('phone_verifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', profile.id)
      .gte('created_at', new Date(Date.now() - 86_400_000).toISOString());

    if ((dailyUserCount ?? 0) >= 5) {
      return new Response(
        JSON.stringify({ error: '오늘 인증 요청 횟수를 초과했습니다.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 8. 기존 pending OTP 만료 처리
    await supabase
      .from('phone_verifications')
      .update({ status: 'expired' })
      .eq('user_id', profile.id)
      .eq('status', 'pending');

    // 9. OTP 생성 및 해싱
    const code = generateOTP();
    const salt = randomBytes(16).toString('hex');
    const codeHash = hashOTP(code, salt);

    // 10. DB 저장
    const { error: insertError } = await supabase
      .from('phone_verifications')
      .insert({
        user_id: profile.id,
        phone_e164: phoneE164,
        code_hash: codeHash,
        salt: salt,
        ip_address: ip,
        expires_at: new Date(Date.now() + 5 * 60_000).toISOString(), // 5분
      });

    if (insertError) {
      throw new Error(`DB 저장 실패: ${insertError.message}`);
    }

    // 11. SMS 발송
    const message = `[momo] 인증번호: ${code}\n5분 안에 입력해주세요.`;
    await sendCoolSMS(phoneE164, message);

    // 12. 응답
    return new Response(
      JSON.stringify({
        success: true,
        message: '인증번호가 발송되었습니다.',
        expiresInSeconds: 300,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    const status = message.includes('올바른') || message.includes('이미') ? 400 : 500;
    return new Response(
      JSON.stringify({ error: message }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### 6.2 `verify-sms-code` — OTP 검증 (❌ 폐기 → Supabase `verifyOTP` 대체)

```typescript
// supabase/functions/verify-sms-code/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHash } from 'node:crypto';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface VerifyRequest {
  phone: string;
  code: string;
}

function normalizePhone(raw: string): string {
  const digits = raw.replace(/[^0-9]/g, '');
  if (digits.startsWith('010') && digits.length === 11) {
    return `+82${digits.slice(1)}`;
  }
  if (digits.startsWith('82') && digits.length === 12) {
    return `+${digits}`;
  }
  throw new Error('올바른 한국 휴대폰 번호를 입력해주세요.');
}

function hashOTP(code: string, salt: string): string {
  return createHash('sha256').update(code + salt).digest('hex');
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. 인증 확인
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: '인증이 필요합니다.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 2. 현재 유저
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    );
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: '유효하지 않은 세션입니다.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. 요청 파싱
    const body: VerifyRequest = await req.json();
    const phoneE164 = normalizePhone(body.phone);
    const code = body.code?.trim();

    if (!code || code.length !== 6 || !/^\d{6}$/.test(code)) {
      return new Response(
        JSON.stringify({ error: '6자리 숫자를 입력해주세요.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. 프로필 조회
    const { data: profile } = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_id', user.id)
      .single();

    if (!profile) {
      return new Response(
        JSON.stringify({ error: '프로필을 찾을 수 없습니다.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 5. 최신 pending 인증 레코드 조회
    const { data: verification, error: verifError } = await supabase
      .from('phone_verifications')
      .select('*')
      .eq('user_id', profile.id)
      .eq('phone_e164', phoneE164)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!verification) {
      return new Response(
        JSON.stringify({ error: '인증 요청을 찾을 수 없습니다. 다시 인증번호를 요청해주세요.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 6. 만료 체크
    if (new Date(verification.expires_at) < new Date()) {
      await supabase
        .from('phone_verifications')
        .update({ status: 'expired' })
        .eq('id', verification.id);

      return new Response(
        JSON.stringify({ error: '인증번호가 만료되었습니다. 다시 요청해주세요.' }),
        { status: 410, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7. 시도 횟수 체크
    if (verification.attempts >= verification.max_attempts) {
      await supabase
        .from('phone_verifications')
        .update({ status: 'blocked' })
        .eq('id', verification.id);

      return new Response(
        JSON.stringify({ error: '인증 시도 횟수를 초과했습니다. 30분 후 다시 시도해주세요.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 8. OTP 검증
    const expectedHash = hashOTP(code, verification.salt);

    if (expectedHash !== verification.code_hash) {
      // 실패: 시도 횟수 증가
      await supabase
        .from('phone_verifications')
        .update({ attempts: verification.attempts + 1 })
        .eq('id', verification.id);

      const remaining = verification.max_attempts - verification.attempts - 1;
      return new Response(
        JSON.stringify({
          error: `인증번호가 일치하지 않습니다. (${remaining}회 남음)`,
          remainingAttempts: remaining,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 9. 인증 성공! — 트랜잭션으로 처리
    const now = new Date().toISOString();

    // 9-1. phone_verifications 상태 업데이트
    await supabase
      .from('phone_verifications')
      .update({
        status: 'verified',
        verified_at: now,
      })
      .eq('id', verification.id);

    // 9-2. profiles 업데이트
    await supabase
      .from('profiles')
      .update({
        phone: phoneE164,
        phone_verified_at: now,
        verification_level: 'phone',
      })
      .eq('id', profile.id);

    // 10. 응답
    return new Response(
      JSON.stringify({
        success: true,
        message: '전화번호 인증이 완료되었습니다.',
        phone: phoneE164,
        verifiedAt: now,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

</details>

---

## 7. 보안 및 컴플라이언스

### 7.1 전화번호 유니크 정책

```
┌─────────────────────────────────────────────────────┐
│ 규칙: 하나의 전화번호 = 하나의 활성 계정              │
├─────────────────────────────────────────────────────┤
│                                                     │
│ 1. 가입 시: phone UNIQUE WHERE deleted_at IS NULL    │
│ 2. 탈퇴 시: soft delete → phone 유지 (재가입 방지)    │
│ 3. 영구삭제: 30일 후 phone = NULL → 번호 해제         │
│ 4. 번호 변경: 기존 phone NULL → 새 번호 인증          │
│                                                     │
│ DB 제약: UNIQUE INDEX (phone) WHERE phone IS NOT NULL │
│          AND deleted_at IS NULL                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 7.2 SMS 남용 방지 체크리스트

- [x] OTP 해싱 (평문 저장 금지) — SHA256 + salt
- [x] 시도 횟수 제한 — 5회 실패 시 30분 블록
- [x] 발송 간격 제한 — 같은 번호 60초 간격
- [x] 일일 발송 제한 — 번호/IP/유저별 5~10회
- [x] OTP 만료 — 5분
- [x] 기존 pending OTP 자동 만료 — 새 발송 시

### 7.3 개인정보 보호 (PIPA 준수)

| 항목 | 조치 |
|------|------|
| **수집 동의** | 전화번호 수집 전 개인정보 수집·이용 동의 팝업 |
| **이용 목적** | 본인 확인, 부정 이용 방지 (약관에 명시) |
| **보관 기간** | 회원 탈퇴 후 30일 → 영구 삭제 |
| **암호화** | 전화번호: DB 컬럼 레벨 암호화 (pgcrypto) |
| **접근 제어** | RLS: 본인만 조회, Edge Function만 쓰기 |
| **전송 보안** | HTTPS only, Supabase JWT 인증 |
| **CI/DI (본인인증)** | AES-256-GCM 암호화 후 저장 |

### 7.4 전화번호 저장 암호화 (선택적 강화)

```sql
-- pgcrypto를 이용한 전화번호 암호화 (필요 시)
-- 현재는 E.164 평문 저장 + RLS로 보호
-- 규모가 커지면 아래 방식으로 강화 가능:

-- 암호화 저장
UPDATE profiles SET phone = pgp_sym_encrypt(
  '+821012345678',
  current_setting('app.settings.encryption_key')
);

-- 복호화 조회
SELECT pgp_sym_decrypt(
  phone::bytea,
  current_setting('app.settings.encryption_key')
) FROM profiles WHERE id = '...';
```

> **현 단계 권장**: E.164 평문 저장 + UNIQUE 인덱스 + RLS 보호.
> 암호화하면 UNIQUE 인덱스가 작동하지 않아 중복 체크를 Edge Function에서 해야 하므로,
> MVP 단계에서는 평문 + RLS가 더 실용적입니다.

---

## 8. Flutter 코드 변경 요약

### 8.1 변경 파일 목록

```
lib/
├── features/auth/
│   ├── data/
│   │   ├── datasources/
│   │   │   └── auth_remote_datasource.dart    # 카카오 추가, 구글 제거
│   │   ├── models/
│   │   │   └── user_model.dart                # 신규 필드 매핑 추가
│   │   └── repositories/
│   │       └── auth_repository_impl.dart      # signInWithKakao 구현
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user_entity.dart               # 신규 필드 추가
│   │   └── repositories/
│   │       └── auth_repository.dart           # signInWithKakao, verifyPhone 추가
│   └── presentation/
│       ├── pages/
│       │   ├── login_page.dart                # Google → Kakao 버튼 교체
│       │   └── phone_verification_page.dart   # NEW: SMS 인증 페이지
│       └── providers/
│           ├── auth_provider.dart             # signInWithKakao 추가
│           └── phone_verification_provider.dart  # NEW
├── core/
│   ├── constants/
│   │   └── app_constants.dart                 # 테이블명 상수 추가
│   └── di/
│       └── providers.dart                     # 신규 provider 등록
└── main.dart                                  # KakaoSdk.init() 추가
```

### 8.2 AuthRepository 인터페이스 변경

```dart
// lib/features/auth/domain/repositories/auth_repository.dart

abstract class AuthRepository {
  /// Apple 소셜 로그인
  Future<UserEntity?> signInWithApple();

  /// Kakao 소셜 로그인 (Google 대체)
  Future<UserEntity?> signInWithKakao();

  /// 로그아웃
  Future<void> signOut();

  /// 현재 로그인된 사용자의 프로필 조회
  Future<UserEntity?> getCurrentUserProfile();

  /// 프로필 존재 여부 확인
  Future<bool> hasProfile();

  /// SMS 인증번호 발송
  Future<void> sendPhoneVerification(String phone);

  /// SMS 인증번호 검증
  Future<bool> verifyPhoneCode(String phone, String code);
}
```

### 8.3 UserEntity 신규 필드

```dart
// 추가할 필드들 (user_entity.dart)

/// 전화번호 인증 시각
final DateTime? phoneVerifiedAt;

/// 인증 레벨 (none/phone/identity)
final VerificationLevel verificationLevel;

/// 상세 자기소개 (최대 1000자)
final String? selfIntroduction;

/// 키(cm) — 명시적
final int? heightCm;

/// 체형
final BodyType? bodyType;

/// 지역 - 시도
final String? regionSido;

/// 지역 - 시군구
final String? regionSigungu;

/// 취미 태그
final List<String> hobbies;

/// 이상형 (최대 300자)
final String? idealType;

/// 본인인증 시각
final DateTime? identityVerifiedAt;
```

### 8.4 SMS 인증 페이지 개요

```dart
// lib/features/auth/presentation/pages/phone_verification_page.dart

/// 온보딩 완료 후 SMS 인증 페이지
///
/// 플로우:
/// 1. 전화번호 입력 (010-XXXX-XXXX)
/// 2. "인증번호 받기" → Edge Function 호출
/// 3. 6자리 코드 입력 + 타이머 (5:00)
/// 4. "인증하기" → Edge Function 호출
/// 5. 성공 → 운명 분석 페이지로 이동
///
/// 디자인: 토스 스타일 — 한 화면에 하나의 질문
/// 캐릭터: 물결이 (水) — "안전하게 지켜드릴게요~"
```

### 8.5 supabase/config.toml 변경사항

```toml
# Google 제거, Kakao 추가
# [auth.external.google] 섹션 삭제 또는 enabled = false

[auth.external.kakao]
enabled = true
client_id = "env(SUPABASE_AUTH_EXTERNAL_KAKAO_CLIENT_ID)"
secret = "env(SUPABASE_AUTH_EXTERNAL_KAKAO_SECRET)"
redirect_uri = ""
url = ""
skip_nonce_check = false
```

---

## 9. 구현 로드맵

### Phase A: 카카오 로그인 + SMS 인증 (Sprint 1 — 3~5일)

| 순서 | 작업 | 예상 시간 |
|------|------|----------|
| A-1 | 카카오 개발자 콘솔 설정 + Supabase Kakao Provider 설정 | 1시간 |
| A-2 | `pubspec.yaml` — google_sign_in 제거, kakao_flutter_sdk 추가 | 30분 |
| A-3 | iOS Info.plist 카카오 설정 + main.dart KakaoSdk.init | 30분 |
| A-4 | `auth_remote_datasource.dart` — signInWithKakao 구현 | 1시간 |
| A-5 | `auth_repository.dart/impl` — 카카오 메서드 추가 | 30분 |
| A-6 | `auth_provider.dart` — signInWithKakao 추가 | 30분 |
| A-7 | `login_page.dart` — Google 버튼 → Kakao 버튼 교체 (노란색) | 1시간 |
| A-8 | DB 마이그레이션 실행 (phone_verifications 테이블 등) | 30분 |
| A-9 | Firebase Console 프로젝트 생성 + Phone Auth 활성화 + 앱 등록 | 1시간 |
| A-10 | Flutter: `firebase_core` + `firebase_auth` 패키지 추가 + 설정 | 1시간 |
| A-11 | Flutter: BYPASS-6/7 → Firebase verifyPhoneNumber() 교체 | 2시간 |
| A-12 | `phone_verification_page.dart` UI 구현 | 3시간 |
| A-13 | 라우팅 연결: 온보딩 → SMS 인증 → 운명 분석 | 1시간 |
| A-14 | E2E 테스트: 카카오 로그인 → SMS 인증 → 프로필 저장 | 2시간 |

### Phase B: 프로필 확장 (Sprint 2 — 2~3일)

| 순서 | 작업 | 예상 시간 |
|------|------|----------|
| B-1 | DB 마이그레이션: profiles 신규 컬럼 | 30분 |
| B-2 | UserEntity + UserModel 신규 필드 추가 | 1시간 |
| B-3 | 프로필 편집 페이지 확장 (상세 프로필 입력) | 4시간 |
| B-4 | 매칭 카드에 인증 배지 표시 | 2시간 |

### Phase C: 본인인증 배지 (Sprint 3 — 3~5일)

| 순서 | 작업 | 예상 시간 |
|------|------|----------|
| C-1 | PASS 사업자 등록 + API 연동 계약 | 1~2주 (외부) |
| C-2 | Edge Function: `request-identity-verification` | 4시간 |
| C-3 | Edge Function: `callback-identity-verification` | 4시간 |
| C-4 | Flutter: 본인인증 WebView 페이지 | 3시간 |
| C-5 | 매칭 카드 배지 업데이트 | 1시간 |

---

## 부록: Supabase 환경변수 목록

```bash
# .env.local (Supabase Edge Functions)

# Firebase — 전화번호 인증은 Firebase Phone Auth 사용
# GoogleService-Info.plist (iOS) / google-services.json (Android) 파일로 설정
# 별도 환경변수 불필요

# Kakao (Supabase Dashboard에서 설정)
SUPABASE_AUTH_EXTERNAL_KAKAO_CLIENT_ID=your_kakao_rest_api_key
SUPABASE_AUTH_EXTERNAL_KAKAO_SECRET=your_kakao_client_secret

# Flutter (--dart-define)
KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key

# PASS 인증 (Phase C)
PASS_CLIENT_ID=your_pass_client_id
PASS_CLIENT_SECRET=your_pass_client_secret
PASS_CALLBACK_URL=https://ejngitwtzecqbhbqfnsc.supabase.co/functions/v1/callback-identity-verification
```

---

## 부록: 체크리스트

### 구현 전 확인사항

- [ ] 카카오 개발자 계정 생성 및 앱 등록
- [ ] 카카오 앱 설정: 로그인 활성화, 동의항목, 플랫폼(iOS/Android)
- [ ] Supabase Dashboard: Kakao Provider 활성화
- [ ] Firebase Console 프로젝트 생성 + Phone Auth 활성화
- [ ] GoogleService-Info.plist (iOS) / google-services.json (Android) 배치
- [ ] 개인정보 처리방침 업데이트 (전화번호 수집 항목 추가)
- [ ] 이용약관 업데이트 (SMS 인증 관련)

### 테스트 케이스

- [ ] 카카오톡 설치 기기: 카카오톡 앱으로 로그인
- [ ] 카카오톡 미설치 기기: 카카오 웹 로그인
- [ ] Apple 로그인 후 카카오 전환 시나리오
- [ ] SMS 발송 성공 + 올바른 코드 입력 → 인증 성공
- [ ] 잘못된 코드 5회 입력 → 블록
- [ ] 만료된 코드 입력 → 재발송 안내
- [ ] 이미 등록된 전화번호 → 중복 에러
- [ ] 레이트 리밋 초과 → 429 에러
- [ ] 네트워크 끊김 → 에러 핸들링

---

*노아님, 아리가 최선을 다해 설계했습니다. 궁금하신 부분이나 수정할 부분 말씀해 주시면 즉시 반영하겠습니다!*
