# 온보딩 & 인증 리디자인 마스터 플랜

> **작성일**: 2026-03-03
> **작성**: 아리 (PO/Designer/Backend/Flutter/Growth 5개 직군 종합)
> **승인**: 노아님 검토 대기
> **상태**: 설계 완료 — 구현 승인 대기

---

## 0. 노아님 핵심 결정사항

1. **로그인**: Apple + Kakao (Google 제거)
2. **SMS 인증**: 사주 정확도가 아닌 **데이팅 사기 방지** 목적
3. **플로우**: 로그인 → 온보딩 → 사주+SMS → 사진 → 분석 → 프로필 추가정보 → 추천리스트 → 홈
4. **프로필 필드**: 자기소개(1,000자), 키, 스타일/체형, 지역, 종교, 직업, 취미, 이상형
5. **인증 뱃지**: 나중에 선택적 추가 인증 → 매칭 카드에 뱃지 표시

---

## 1. 전체 플로우 다이어그램

```
┌──────────┐   ┌──────────────┐   ┌───────────────────────────────┐
│  로그인    │──>│  온보딩 인트로 │──>│  사주 정보 + SMS 인증 (7스텝) │
│ Apple     │   │  3슬라이드     │   │                               │
│ Kakao     │   │ (건너뛰기 O)  │   │  0.이름 → 1.성별(auto)        │
└──────────┘   └──────────────┘   │  → 2.생년월일 → 3.시진(auto)   │
                                   │  → 4.SMS인증 → 5.사진          │
                                   │  → 6.확인 요약                  │
                                   └──────────┬────────────────────┘
                                              │
                         ┌────────────────────▼────────────────────┐
                         │  사주 & 관상 통합 분석 (~10초, 다크 모드) │
                         └────────────────────┬────────────────────┘
                                              │
                         ┌────────────────────▼────────────────────┐
                         │  통합 결과 (탭: 사주 | 관상)              │
                         │  CTA: "운명의 인연 찾으러 가기"           │
                         └────────────────────┬────────────────────┘
                                              │
                         ┌────────────────────▼────────────────────┐
                         │  데이팅 프로필 추가정보 (8필드)           │
                         │  자기소개/키/체형/지역/종교/직업/취미/이상형│
                         │  최소 필수: 키 + 직업 + 지역              │
                         └────────────────────┬────────────────────┘
                                              │
                         ┌────────────────────▼────────────────────┐
                         │  궁합 기반 추천 리스트 (5~10명)           │
                         │  CTA: "홈으로 가기"                      │
                         └────────────────────┬────────────────────┘
                                              │
                                    ┌─────────▼─────────┐
                                    │  홈 (4탭 메인)     │
                                    └───────────────────┘
```

**예상 소요 시간**: 5~8분 (업계 평균 5~7분)

---

## 2. 화면별 상세 설계

### 2-1. 로그인 (Login)

| 항목 | 내용 |
|------|------|
| **모드** | 라이트 (#F7F3EE) |
| **버튼** | Apple (검정 filled) + Kakao (#FEE500 filled) |
| **변경점** | Google 버튼 제거, Kakao 버튼 추가 |

### 2-2. 온보딩 인트로 (3슬라이드)

| 슬라이드 | 헤드라인 | 서브카피 |
|---------|---------|---------|
| 1 (Hook) | "200번 스와이프해도\n못 찾은 그 사람" | "사주가 이미 알고 있었어요" |
| 2 (Wow) | "3분이면 알 수 있는\n나의 연애 사주" | "조상님 덕에 쌓인 사주, AI가 풀어드려요" |
| 3 (CTA) | "사주 궁합이 좋은 사람,\n먼저 만나볼래요?" | "수천 년 이어진 인연의 지혜" |

### 2-3. 사주 정보 + SMS 인증 (통합 폼 7스텝)

| Step | 필드 | 필수 | 캐릭터 | 대사 | 진행 |
|------|------|:---:|--------|------|------|
| 0 | 이름 | O | 물결이(水) | "반가워요! 이름이 어떻게 돼요~?" | 버튼 |
| 1 | 성별 | O | 물결이(水) | "성별을 알려주세요~" | 자동(0.3초) |
| 2 | 생년월일 | O | 물결이(水) | "생년월일이 사주의 시작이에요!" | 버튼 |
| 3 | 시진 | 선택 | 쇠동이(金) | "태어난 시간도 알면 더 정확해요!" | 자동(0.3초) |
| 4 | **SMS 인증** | **O** | **흙순이(土)** | **"안전한 만남을 위해 번호 확인 한 번만~"** | **인증 후 자동** |
| 5 | 사진 | O | 불꼬리(火) | "얼굴에 숨은 동물상이 궁금하지 않아요?" | 버튼 |
| 6 | 확인 요약 | — | 전체 | "다 맞는지 한 번만 확인해주세요!" | CTA |

**SMS 인증 상세 UX:**
- 안내 문구: "진짜 인연만 만나는 곳 — 본인 확인된 사람만 매칭해드려요"
- 신뢰 포인트: "번호는 암호화 저장, 절대 공개 안 됨"
- 6자리 개별 박스 입력 + 3분 타이머
- 인증 완료 시 체크 애니메이션 → 0.5초 후 자동 진행

### 2-4. 데이팅 프로필 추가정보 (8필드)

| Step | 필드 | 필수 | 타입 | 검증 |
|------|------|:---:|------|------|
| 1 | 자기소개 | 선택 | textarea | 최대 1,000자 |
| 2 | 키 | **필수** | 숫자 입력 | 140~220cm |
| 3 | 스타일/체형 | 선택 | 칩 단일선택 | 마름/슬림/보통/근육질/통통 |
| 4 | 지역 | **필수** | 2단 선택(시도→시군구) | 프리셋 |
| 5 | 종교 | 선택 | 칩 단일선택 | 무교/기독교/천주교/불교/기타 |
| 6 | 직업 | **필수** | 텍스트 입력 | 1~30자 |
| 7 | 취미 | 선택 | 칩 다중선택 | 프리셋+자유, 3~10개 |
| 8 | 이상형 | 선택 | 칩+텍스트 복합 | 키워드 5개 + 자유 100자 |

**최소 필수**: 키 + 직업 + 지역 → 나머지는 "나중에" 스킵 가능

---

## 3. 백엔드 아키텍처

### 3-1. 카카오 로그인

**방식**: `kakao_flutter_sdk` → ID Token → Supabase `signInWithIdToken(provider: OAuthProvider.kakao)`

**필요 설정**:
- 카카오 개발자 콘솔: 앱 등록 + Native App Key + 로그인 활성화
- Supabase Dashboard: Auth > Providers > Kakao에 REST API Key + Secret 등록
- iOS: Info.plist에 `kakao{APP_KEY}` URL Scheme
- Android: AndroidManifest에 카카오 Activity

### 3-2. SMS 인증

**방식**: Supabase Edge Function + CoolSMS (한국 최대 SMS API, 건당 ~20원)

> Supabase Auth Phone은 "전화번호 기반 회원가입"용이라 이미 Apple/Kakao로 로그인한 유저에게
> 전화번호를 "추가 인증"하는 시나리오에는 부적합. Edge Function + 외부 SMS가 적합.

**Edge Functions**:
- `send-sms-verification`: 번호 정규화 → 중복 체크 → 레이트리밋 → OTP 생성(SHA256+salt) → CoolSMS 발송
- `verify-sms-code`: OTP 검증 → 만료/시도횟수 체크 → profiles 업데이트

**보안**:
- OTP 평문 저장 금지 (SHA256 + salt 해싱)
- 5분 만료, 5회 실패 시 30분 블록
- 전화번호 UNIQUE 제약 (1번호 = 1계정)

### 3-3. DB 스키마 변경

```sql
-- profiles 테이블 신규 컬럼
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  phone_verified_at TIMESTAMPTZ,
  verification_level TEXT DEFAULT 'none'
    CHECK (verification_level IN ('none', 'phone', 'identity')),
  self_introduction TEXT,              -- 최대 1000자
  height_cm SMALLINT CHECK (height_cm BETWEEN 140 AND 220),
  body_type TEXT,                       -- 마름/슬림/보통/근육질/통통
  region_sido TEXT,                     -- 시/도
  region_sigungu TEXT,                  -- 시/군/구
  religion TEXT,
  hobbies TEXT[] DEFAULT '{}',
  ideal_type TEXT,                      -- 이상형 자유 서술
  ideal_type_keywords TEXT[] DEFAULT '{}',
  identity_verified_at TIMESTAMPTZ;

-- SMS 인증 이력 테이블
CREATE TABLE IF NOT EXISTS phone_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  otp_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT DEFAULT 0,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_phone_unique
  ON profiles(phone) WHERE phone IS NOT NULL;
```

### 3-4. 인증 배지 시스템 (Phase 2)

| 등급 | 명칭 | 조건 | 매칭 가중치 |
|------|------|------|-----------|
| Lv.0 | (없음) | 가입만 | 기본 |
| Lv.1 | 기본 | SMS 인증 (온보딩 필수) | 표시 안 함 (모든 유저 기본) |
| Lv.2 | **진심 마크** | PASS 본인인증 (선택) | +15% 노출 우선 |
| Lv.3 | **신뢰 마크** | 셀카 AI 인증 (선택) | +25% 노출 우선 |

---

## 4. Flutter 구현 계획

### 4-1. 패키지 변경

```yaml
# 제거
google_sign_in: ^6.2.2

# 추가
kakao_flutter_sdk_user: ^1.9.6
```

### 4-2. 파일별 변경 목록 (20개)

#### Phase 1: 도메인 & 데이터 (1일)

| # | 파일 | 변경 | LOC |
|---|------|------|-----|
| 1 | `pubspec.yaml` | google_sign_in → kakao_flutter_sdk_user | ~5 |
| 2 | `auth/domain/entities/user_entity.dart` | bodyType, idealType, isPhoneVerified 추가 | ~40 |
| 3 | `auth/data/models/user_model.dart` | JSON 매핑 추가 | ~15 |
| 4 | `matching/domain/entities/match_profile.dart` | 인증 뱃지 + 추가 필드 | ~30 |
| 5 | `auth/domain/repositories/auth_repository.dart` | signInWithKakao, SMS 메서드 | ~10 |
| 6 | `profile/domain/repositories/profile_repository.dart` | bodyType, idealType 파라미터 | ~10 |
| 7 | `auth/data/datasources/auth_remote_datasource.dart` | Kakao SDK + SMS API | ~50 |
| 8 | `auth/data/repositories/auth_repository_impl.dart` | 구현 교체 | ~30 |
| 9 | `profile/data/repositories/profile_repository_impl.dart` | 신규 필드 저장 | ~15 |
| 10 | `core/constants/app_constants.dart` | maxBioLengthDating 등 상수 | ~5 |

#### Phase 2: Presentation (2일)

| # | 파일 | 변경 | LOC |
|---|------|------|-----|
| 11 | `auth/presentation/providers/auth_provider.dart` | Google→Kakao | ~10 |
| 12 | `auth/presentation/providers/onboarding_provider.dart` | phone 전달 | ~5 |
| 13 | `profile/presentation/providers/matching_profile_provider.dart` | 신규 필드 | ~10 |
| 14 | `auth/presentation/pages/login_page.dart` | Google→Kakao 버튼 | ~60 |
| 15 | `auth/presentation/pages/onboarding_form_page.dart` | **SMS 스텝 추가 (핵심)** | ~200 |
| 16 | `auth/presentation/pages/onboarding_page.dart` | phone 전달 | ~5 |
| 17 | `profile/presentation/pages/matching_profile_page.dart` | **풀 프로필 리디자인** | ~250 |
| 18 | `app/routes/app_router.dart` | quickMode 제거 | ~10 |

#### Phase 3: 플랫폼 + 테스트 (0.5일)

| # | 파일 | 변경 | LOC |
|---|------|------|-----|
| 19 | `ios/Runner/Info.plist` | 카카오 URL Scheme | ~10 |
| 20 | `android/app/src/main/AndroidManifest.xml` | 카카오 Activity | ~15 |

#### 신규 파일 (1개)

| 파일 | 용도 |
|------|------|
| `assets/images/icons/kakao_logo.svg` | 카카오 로그인 버튼 아이콘 |

### 4-3. 구현 순서 (의존성 기반)

```
Day 1: 도메인/데이터 레이어 (#1~#10) + DB 마이그레이션 SQL
Day 2: 로그인 + 온보딩 폼 SMS (#11~#16)
Day 3: 매칭 프로필 리디자인 + 라우트 + 플랫폼 설정 (#17~#20)
Day 3.5: build_runner + flutter clean + 전체 빌드 검증 + E2E
```

---

## 5. 그로스 전략

### 5-1. 온보딩 퍼널 KPI

| 구간 | MVP 목표 | 경고 임계값 |
|------|---------|-----------|
| 설치 → 로그인 | 75% | <55% |
| 로그인 → 사주정보 완료 | 80% | <65% |
| **사주정보 → SMS 인증** | **65%** | **<50%** (최대 병목) |
| SMS → 사진 업로드 | 70% | <55% |
| 분석 → 추가정보 | 70% | <55% |
| **전체 온보딩 완주율** | **40%** | **<25%** |

### 5-2. SMS 이탈 최소화

- 프레이밍: "진짜 인연만 만나는 곳" (보안이 아닌 신뢰)
- 캐릭터 안내: 흙순이가 부드럽게 안내
- 신뢰 포인트 3개: 암호화 저장 / 절대 비공개 / 가짜 99% 차단

### 5-3. 사진 업로드 이탈 최소화

- **"사진 올려주세요" 대신 "동물상 분석하기"로 리프레이밍** → 모모만의 킬러 무브
- 불꼬리(火) 캐릭터: "얼굴에 숨은 동물상이 궁금하지 않아요?"

### 5-4. 인증 뱃지 로드맵

| Phase | 시기 | 인증 | 효과 |
|-------|------|------|------|
| 1 (MVP) | 출시 | SMS 필수 | 가짜 계정 90%+ 차단 |
| 2 | 출시 2~3개월 | AI 셀카 인증 (선택) | 캣피싱 방지 |
| 3 | 출시 4~6개월 | PASS 본인인증 (선택) | 실명 확인 |
| 4 | 출시 6~12개월 | 직장/학교 배지 (선택) | 프리미엄 포지셔닝 |

---

## 6. 상세 참조 문서

| 문서 | 경로 | 내용 |
|------|------|------|
| **Backend 아키텍처** | `docs/plans/2026-03-03-auth-backend-architecture.md` | Kakao OAuth, SMS, DB 스키마, Edge Function, 보안 |
| **UX/UI 디자인 스펙** | `docs/design/2026-03-03-full-flow-ux-spec.md` | 화면별 와이어프레임, 트랜지션, 캐릭터 대사, 마이크로인터랙션 |
| **기존 인프라 가이드** | `docs/guides/sprint-a-infra-setup.md` | Apple/Supabase 인프라 설정 |

---

## 7. 기존 플로우 대비 변경 요약

| 항목 | Before | After |
|------|--------|-------|
| 로그인 | Apple + Google | Apple + **Kakao** |
| SMS 인증 | 없음 (Placeholder) | 온보딩 Step 4에 통합 |
| 온보딩 스텝 | 6스텝 | **7스텝** (SMS 추가) |
| 프로필 추가정보 | 퀵 모드 2필드 or 풀 5스텝 | **풀 8필드** (자기소개/키/체형/지역/종교/직업/취미/이상형) |
| 자기소개 | max 300자 | max **1,000자** |
| 체형/이상형 | 없음 | **신규 추가** |
| 음주/흡연/MBTI | 온보딩 수집 | **온보딩에서 제거** (프로필 편집에서 선택 가능) |
| 인증 뱃지 | 없음 | Phase 2에서 추가 (선택적) |

---

## 8. 노아님 확인 필요 사항

1. **Kakao 개발자 앱 등록**: 노아님이 카카오 개발자 콘솔에서 앱 등록 + Native App Key 발급 필요
2. **CoolSMS 계정**: SMS 발송 서비스 가입 + API Key 발급 (또는 Twilio 등 대안)
3. **Supabase Dashboard**: Kakao Provider 활성화 + SMS 관련 시크릿 등록
4. ~~음주/흡연/MBTI~~ 온보딩에서 완전 제거 확인 (프로필 편집에서 선택적으로 유지?)
5. 체형 선택지 최종 확정: 마름/슬림/보통/근육질/통통 — 추가/변경 있는지?
