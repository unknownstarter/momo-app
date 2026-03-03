# 테스크 마스터 — 2026-03-03 (v11)

> **작성일**: 2026-02-24 | **갱신**: 2026-03-03
> **목적**: 다음에 할 일을 한곳에 정리해, 다른 디바이스에서 보고 연속으로 작업할 수 있게 함.
> **참조**: PRD `docs/plans/2026-02-24-app-design.md`, 개선 제안서 `docs/plans/2026-02-24-saju-궁합-engine-improvement-proposal.md`, dev-log `docs/dev-log/2026-02-24-progress.md`

---

## 0. 새 디바이스 셋업 가이드

> 다른 맥에서 이어서 작업할 때 이 섹션을 먼저 확인.

### 필수 환경

| 도구 | 최소 버전 | 현재 검증 버전 | 비고 |
|------|----------|---------------|------|
| **Flutter** | 3.38+ | 3.41.2 (stable) | `flutter doctor`로 확인 |
| **Dart SDK** | ^3.10.0 | 3.11.0 | Flutter에 포함 |
| **Xcode** | 16+ | 26.2 | iOS 빌드 필수 |
| **CocoaPods** | 1.14+ | 1.16.2 | `sudo gem install cocoapods` |
| **Node.js** | 20+ | 25.4.0 | Supabase Edge Functions 로컬 테스트용 |
| **Supabase CLI** | 2.0+ | 2.75.0 | `brew install supabase/tap/supabase` |
| **Ruby** | 2.6+ | 2.6.10 | CocoaPods 의존 (macOS 기본) |

> **Deno**: 로컬 미설치 상태 (Edge Function은 Supabase 클라우드에서 실행). 로컬 테스트하려면 `brew install deno`.

### 클론 후 바로 실행하기

```bash
# 1. 레포 클론
git clone https://github.com/unknownstarter/momo-app.git momo
cd momo

# 2. Flutter 의존성
flutter pub get

# 3. iOS 의존성 (최초 1회)
cd ios && pod install && cd ..

# 4. 코드 생성 (freezed/riverpod/json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 5. 빌드 검증
flutter analyze lib/          # 0 errors 확인
flutter build ios --no-codesign --debug   # iOS 빌드 확인
```

### 핵심 의존성 (pubspec.yaml)

| 카테고리 | 패키지 | 버전 |
|---------|--------|------|
| 상태관리 | `flutter_riverpod` | ^2.6.1 |
| 라우팅 | `go_router` | ^14.8.1 |
| Backend | `supabase_flutter` | ^2.9.0 |
| 코드 생성 | `freezed` / `json_serializable` | ^2.5.7 / ^6.9.4 |
| 관상 ML | `google_mlkit_face_detection` | ^0.13.2 |
| 이미지 | `image_picker` / `image_cropper` | ^1.1.2 / ^8.0.2 |
| 결제 | `purchases_flutter` (RevenueCat) | ^8.4.1 |
| 소셜로그인 | `sign_in_with_apple` / `kakao_flutter_sdk_user` | ^6.1.4 / ^1.9.6 |

### 플랫폼 설정

| 항목 | 값 |
|------|-----|
| iOS minimum | 16.0 |
| Android SDK | Flutter 기본값 (compileSdk/minSdk/targetSdk) |
| 폰트 | Pretendard (Regular/Medium/SemiBold/Bold) — `assets/fonts/` |

### Supabase 프로젝트

| 항목 | 값 |
|------|-----|
| Project ID | `csjdfvxyjnpmbkjbomyf` |
| 로컬 config | `supabase/config.toml` (project_id: momo-app) |
| Edge Functions | `supabase/functions/` 디렉토리 |
| 주요 함수 | `calculate-saju`, `calculate-compatibility`, `generate-gwansang-reading` |

### 현재 디버그 바이패스 (6건)

> Auth 미연동 상태에서 테스트하기 위한 바이패스. Sprint A에서 제거 예정.
> 검색: `TODO(PROD)` 또는 `BYPASS-N`
> 상세 문서: `docs/dev-log/2026-02-26-debug-bypass.md`

| ID | 위치 | 역할 |
|----|------|------|
| BYPASS-1 | `login_page.dart:87` | 로그인 실패 → 온보딩 직행 |
| BYPASS-2 | `onboarding_page.dart:113` | 프로필 저장 실패 → Mock 분석 진행 |
| BYPASS-3 | `destiny_analysis_page.dart:238` | 사주 분석 실패 → Mock 결과 |
| BYPASS-4 | `destiny_analysis_page.dart:259` | 관상 분석 실패 → Mock 결과 |
| BYPASS-5 | `matching_profile_page.dart:320` | 프로필 저장 실패 → 매칭 직행 |
| BYPASS-6 | `app_router.dart:93-95` | matching/chat/profile 비로그인 접근 허용 |

### 현재 앱 상태 요약 (2026-03-03 v2)

- **작동하는 것**: 온보딩(7스텝, SMS 필수) → 사주+관상 통합 분석(Mock) → 결과(탭) → 데이팅 프로필(8필드) → 추천 리스트 → 홈(추천 그리드) → **프로필 상세(즉시 표시, 인라인 궁합, Hero 트랜지션)** → 궁합 프리뷰(실연동 가능)
- **Mock인 것**: 로그인, 프로필 저장, 사주/관상 AI 분석, 추천 목록, 좋아요, SMS 인증(BYPASS-6/7)
- **실연동된 것**: `calculate-compatibility` Edge Function (궁합 계산, Mock 파트너일 때는 로컬 Mock 사용)
- **직전 완료**: Sprint ON (온보딩 리디자인 구현) + SMS 필수화 + Send SMS Hook + CoolSMS 아키텍처 확정
- **다음 작업**: **Sprint A — 노아님 인프라 설정** (Apple/Kakao/CoolSMS/Supabase) → **아리 BYPASS 제거** (A3~A10)

---

## 1. 완료된 것

### 2026-02-24

| # | 항목 | 상태 |
|---|------|------|
| 1 | 사주 엔진 만세력 기준 전환 (`calculate-saju` → @fullstackfamily/manseryeok, KASI) | ✅ |
| 2 | 실궁합 Edge Function `calculate-compatibility` 구현 (오행+일주 기반) | ✅ |
| 3 | RLS `saju_select_recommended` 추가, Saju `getSajuForCompatibility` | ✅ |
| 4 | MatchingRepositoryImpl 연동, DI 전환 (궁합만 실연동, 추천/좋아요 Mock 유지) | ✅ |
| 5 | Phase 1 스펙·dev-log·문서 반영 | ✅ |

### 2026-02-25

| # | 항목 | 커밋 | 상태 |
|---|------|------|------|
| 6 | 사주 분석 결과 DB 저장 파이프라인 (Tasks 1-4) | `da1a400` | ✅ |
| 7 | 온보딩→사주분석 데이터 핸드오프 연결 (Tasks 5-7) | `6071706` | ✅ |
| 8 | 두 퍼널 아키텍처 (DB 11컬럼 + 트리거 + RLS + 라우터 게이트) | `3944840` | ✅ |
| 9 | 궁합 프리뷰 버그 수정 (Mock 분기 + upsert onConflict) | `f41f4ae` | ✅ |
| 10 | 궁합 프리뷰 와우 모먼트 (게이지 1800ms + 딜레이 페이드인 + 글로우) | `f41f4ae` | ✅ |
| 11 | UI 토큰 시스템 구현 (ThemeExtension 기반 SajuColors/Typography/Elevation) | `a47c5fa` | ✅ |
| 12 | 코어 위젯 11개 + 피처 레이어 18개 토큰 마이그레이션 (deprecated 0개) | `0758045` | ✅ |
| 13 | AI 관상 + 동물상 Feature 설계 완료 (PM/Tech/Content/Growth 4개 에이전트 분석) | — | ✅ |
| 14 | 관상 구현 계획서 작성 (13 Tasks) | — | ✅ |

---

## 2. 다음에 할 일 (우선순위순)

> **현재 최우선**: ⭐ **Sprint A 인프라 설정 (노아님)** → BYPASS 제거 (아리)
> Sprint ON 완료 (2026-03-03). SMS 필수화 + Send SMS Hook + CoolSMS 아키텍처 확정.

### 🔥 즉시 (Highest) — AI 관상 + 동물상 Feature 구현 + 온보딩 리팩토링

> **전략**: 관상은 홈에서 "동물상 케미" 동기로 자발적 유도, 온보딩은 3분 이내로 축소
> **구현 계획**: `docs/plans/2026-02-25-gwansang-implementation.md` (13 Tasks)
> **온보딩 리팩토링**: 사주 결과→매칭 프로필 퀵 모드(2스텝)→홈, 관상은 홈 넛지로 분리
> **설계 문서**: 아래 4개 참조

| # | Task | 담당 관점 | 산출물/참고 | 상태 |
|---|------|-----------|-------------|------|
| G1 | **패키지 추가 + 상수 등록** | Flutter | pubspec.yaml, app_constants.dart | ✅ |
| G2 | **도메인 엔티티** (GwansangProfile, AnimalType 10종, FaceMeasurements) | Flutter | 3개 파일 생성 | ✅ |
| G3 | **Data 레이어** (Model, Datasource, Repository) | Flutter + Backend | 4개 파일 생성 | ✅ |
| G4 | **FaceAnalyzerService** (ML Kit on-device 얼굴 측정) | Flutter | google_mlkit_face_detection | ✅ |
| G5 | **DI 등록 + Riverpod Provider** | Flutter | providers.dart, gwansang_provider.dart | ✅ |
| G6 | **라우트 등록 + 사주 결과→관상 연결** | Flutter | app_router.dart, saju_result_page.dart 수정 | ✅ |
| G7 | **관상 브릿지 페이지** ("관상까지 더하면...") | Flutter | gwansang_bridge_page.dart | ✅ |
| G8 | **사진 업로드 페이지** (3장 가이드 + 얼굴 검증) | Flutter | gwansang_photo_page.dart | ✅ |
| G9 | **관상 분석 로딩 페이지** (8초 연출) | Flutter | gwansang_analysis_page.dart | ✅ |
| G10 | **관상 결과 페이지** (동물상 리빌 + 바이럴 공유) | Flutter | gwansang_result_page.dart + 위젯 2개 | ✅ |
| G11 | **매칭 프로필 사진 스킵** (관상 사진 자동 연동) | Flutter | matching_profile_page.dart 수정 | ✅ |
| G12 | **Supabase 마이그레이션 + Edge Function** | Backend | DB 테이블 + generate-gwansang-reading | ✅ |
| G13 | **통합 검증** (flutter analyze + 빌드) | QA | 0 errors 확인 | ✅ |

#### 온보딩 플로우 리팩토링 (2026-02-26)

> **핵심**: 12단계 ~7분 → 6단계 ~3분. 관상을 온보딩에서 분리, 홈 넛지로 유도.

| # | Task | 커밋 | 상태 |
|---|------|------|------|
| R1 | **사주 결과 CTA** → "운명의 인연 찾으러 가기" (matchingProfile quickMode) | `8493bea` | ✅ |
| R2 | **라우터 extra 타입** Map 확장 (quickMode + gwansangPhotoUrls) | `8493bea` | ✅ |
| R3 | **매칭 프로필 퀵 모드** — 사진 1장 + 기본정보 2스텝 | `26b827b` | ✅ |
| R4 | **홈 관상 넛지 배너** — "닮은 동물상끼리 잘 맞는대요!" | `f72fd76` | ✅ |
| R5 | **MatchProfile animalType** 필드 추가 | `d8ce376` | ✅ |
| R6 | **궁합 프리뷰 동물상 케미** 섹션 (넛지 CTA) | `d8ce376` | ✅ |
| R7 | **관상 결과 CTA** → "동물상 케미 확인하러 가기" (홈 복귀) | `03513f6` | ✅ |
| R8 | **관상 브릿지 스킵** → 홈으로 | `03513f6` | ✅ |
| R9 | **통합 검증** flutter analyze 0 errors | — | ✅ |

#### 토스 스타일 UX 리팩토링 (2026-02-26)

> **핵심**: "양식 작성" → "대화형 한 화면 하나" 패턴. 햅틱 피드백, 버튼 활성화, shake 에러, 스켈레톤 로딩.
> **설계**: `docs/plans/2026-02-26-toss-ux-refactoring-design.md`
> **구현 계획**: `docs/plans/2026-02-26-toss-ux-implementation.md`

| # | Task | 커밋 | 상태 |
|---|------|------|------|
| U1 | **HapticService** 글로벌 햅틱 피드백 서비스 | `27404ad` | ✅ |
| U2 | **SajuButton** 비활성 시각 상태 강화 (opacity 0.4) | `27404ad` | ✅ |
| U3 | **SajuInput** 에러 시 shake 애니메이션 + 햅틱 | `27404ad` | ✅ |
| U4 | **온보딩 폼** 2→5스텝 "한 화면 하나" (자동진행, 인라인 피커, 요약 확인) | `27404ad` | ✅ |
| U5 | **홈 스켈레톤** SkeletonCard + 섹션 fadeIn/slideUp | `27404ad` | ✅ |
| U6 | **통합 검증** flutter analyze 0 errors | `27404ad` | ✅ |

#### 통합 사주+관상 온보딩 플로우 (2026-02-26)

> **핵심**: 사주와 관상을 **하나의 온보딩 퍼널**로 통합. "이름→성별→생일→시진→사진→확인→통합분석→탭결과" 하나의 흐름.
> **플랜**: `.claude/plans/lucky-watching-goose.md`
> **원칙**: "자꾸 두 개로 분리하지 마라!" — 노아님 피드백

| # | Task | 커밋 | 상태 |
|---|------|------|------|
| D1 | **온보딩 폼 사진 스텝 추가** (5→6스텝, 정면 사진 1장) | `55cfb27` | ✅ |
| D2 | **온보딩 완료 시 통합 분석(destiny-analysis)으로 라우팅** | `55cfb27` | ✅ |
| D3 | **라우트 등록** destiny-analysis, destiny-result 라우트 + 상수 | `55cfb27` | ✅ |
| D4 | **통합 분석 로딩 페이지** — 사주→관상 순차 분석 (~10s 연출) | `55cfb27` | ✅ |
| D5 | **통합 결과 페이지** — TabBar [사주 \| 관상] + 통합 CTA | `55cfb27` | ✅ |
| D6 | **통합 검증** flutter analyze 0 errors (28 issues = 기존 동일) | `55cfb27` | ✅ |

**신규 파일:**
- `lib/features/destiny/presentation/pages/destiny_analysis_page.dart` (~630줄)
- `lib/features/destiny/presentation/pages/destiny_result_page.dart` (~916줄)

**수정 파일:**
- `onboarding_form_page.dart` — Step 4 사진 추가, 6스텝 전환
- `onboarding_page.dart` — destinyAnalysis 라우팅
- `app_constants.dart` — destinyAnalysis/destinyResult 상수
- `app_router.dart` — destiny 라우트 2개 등록

### 2026-02-27

| # | 항목 | 상태 |
|---|------|------|
| C1 | 나무리 캐릭터 누끼 + 영문 네이밍 적용 (4종: default/expressions/poses/turnaround) | ✅ |
| C2 | 나무리 여친 + 쇠동이 재누끼 (텍스트 제거 포함, 6종) | ✅ |
| C3 | 전 캐릭터(8종) 스프라이트 시트 → 개별 PNG 분리 (103개 파일) | ✅ |
| C4 | 캐릭터 에셋 폴더 구조 체계화 (`{char}/{variant}/`) | ✅ |
| C5 | `CharacterPath` 헬퍼 클래스 + `CharacterAssets` 리팩토링 | ✅ |
| C6 | pubspec.yaml 에셋 경로 + 빌드 검증 (0 errors) | ✅ |

### 2026-02-28

| # | 항목 | 상태 |
|---|------|------|
| UX1 | 홈 화면 & UX 리디자인 설계 — PD/Growth/UX 에이전트 협의, 경쟁앱 리서치 | ✅ |
| UX2 | 온보딩 문구 해요체+위트 개선안 확정 | ✅ |
| UX3 | 전체 유저 플로우 도식화 + 와우 모먼트 3곳 정의 | ✅ |
| UX4 | 설계 문서 작성: `docs/plans/2026-02-28-home-ux-redesign-design.md` | ✅ |
| UX5 | PRD 업데이트: 홈 화면 구성(§6) + 온보딩 대사(§3.2) + 분석 페이즈(§3.3) | ✅ |
| UX6 | 온보딩 전체 문구 해요체+위트 코드 적용 (Phase 1: 로그인/온보딩/분석/결과 6개 파일) | ✅ |
| UX7 | SajuMatchCard v2 — showCharacterInstead + isNew 뱃지 | ✅ |
| UX8 | 홈 페이지 리디자인 구현 — 2컬럼 그리드 + 연애운 + 동물상 | ✅ |
| UX9 | ProfileDetailPage — 블러 사진 + 캐릭터 + 궁합 + 라우트 등록 | ✅ |
| UX10 | 전체 통합 검증 (flutter analyze + iOS build) | ✅ |

### 2026-03-01

| # | 항목 | 상태 |
|---|------|------|
| WOW1 | **Hero 섹션** — SliverAppBar(0.55) + 패럴랙스 블러 + 캐릭터 96px 스케일 등장 + bounce chevron | ✅ |
| WOW2 | **첫인상 섹션** — 캐릭터 말풍선 소개 + bio 확장 + 기본 정보 칩 + scroll reveal | ✅ |
| WOW3 | **궁합 인라인** — 게이지 140px 카운트업 + 등급 딜레이 + 강점/도전 스태거드 등장 | ✅ |
| WOW4 | **관상 케미** — 조건부 동물상 + traits 미니 바 차트 + 넛지 CTA | ✅ |
| WOW5 | **고정 액션** — 하단 고정 LikeButton + ghost 건너뛰기 + 스와이프 업 제스처 | ✅ |
| WOW6 | **RevealSection** — 스크롤 위치 기반 섹션 자동 등장 (fade+slide, 단방향) | ✅ |
| WOW7 | **Hero 트랜지션** — 홈 카드 heroTag → 상세 Hero, 캐릭터 이동 효과 | ✅ |
| WOW8 | **문서 업데이트** — dev-log + task-master | ✅ |

### 2026-03-02

| # | 항목 | 상태 |
|---|------|------|
| FIX1 | **Hero 태그 중복 크래시 수정** — heroTag에 소스 prefix + index 추가, extra를 Map으로 변경 | ✅ |
| FIX2 | **스크롤 reveal 제거** — 모든 섹션 즉시 표시, RevealSection/BouncingChevron/DelayedFadeIn 삭제 | ✅ |
| FIX3 | **홈 섹션 간격 32px 통일** — 기존 24/32/28/28px → 전체 32px, 그리드 aspect ratio 0.72→0.78 | ✅ |
| FIX4 | **문서 업데이트** — dev-log + task-master v10 | ✅ |

### 🔥 Sprint 0 — 관상 시스템 재설계 ("진짜 관상학 + 동적 동물 도감")

> **핵심**: 억지 오행 연결 제거. 관상학(삼정/오관) 기반 실제 해석이 메인, 닮은 동물은 재미 태그.
> **설계 원칙**:
> - 관상학 해석이 메인 콘텐츠 (삼정·오관 기반 눈·코·입·이마·턱 분석)
> - 닮은 동물은 "동적 확장 도감" — AI가 자유 제안 → DB에 등록/재사용 (고양이, 공룡, 낙타 뭐든 가능)
> - 수식어는 관상 특징에서 도출 ("나른한 고양이" = 처진 눈꼬리 반영)
> - 궁합은 동물이 아닌 **관상 traits 5축** 벡터 기반 계산
> - 동물 리빌 와우 모먼트는 유지 (연출은 살리되, 결과 페이지에서 관상학이 메인)
> **구현 계획**: `docs/plans/2026-02-28-gwansang-redesign.md` (9 Tasks)

```
변경 범위:
  F1(엔티티) ──┐
  F2(DB 스키마) ┤→ F3(Edge Function) → F5(결과 UI)
  F4(traits 궁합) ────────────────────→ F6(궁합 프리뷰 UI)
                                       → F7(통합 검증)
```

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| F1 | **GwansangProfile 엔티티 재설계** — `AnimalType` enum 제거 → `animalType: String`(동적) + `animalModifier`/`animalTypeKorean` + `traits` 5축 + 삼정·오관 해석 필드 추가 | Flutter | 없음 | ✅ |
| F2 | **Data 레이어 + DB 스키마 변경** — Model/Datasource/Repository 새 스키마 반영, `saju_synergy`/`element_modifier` 제거 | Backend + Flutter | F1 | ✅ |
| F3 | **Edge Function 재설계** (`generate-gwansang-reading`) — 삼정/오관 관상학 중심 프롬프트 재작성, 동물 자유형, traits 5축 출력 | Backend | F2 | ✅ |
| F4 | **AnimalType 참조 전면 제거 + MatchProfile traits 추가** — 4개 파일 컴파일 에러 해소, Mock 데이터에 traits 추가 | Flutter | F1 | ✅ |
| F5 | **관상 결과 페이지 UI 재설계** — 삼정(三停)/오관(五官) 메인 콘텐츠 + traits 5축 바 차트 + 동물 리빌 유지, `gwansang_result_page.dart` + `destiny_result_page.dart` 관상 탭 동시 수정 | Flutter | F1, F3 | ✅ |
| F6 | **궁합 프리뷰 UI 업데이트** — 관상 traits 문구 업데이트, 홈 "관상 매칭" 배너 리디자인 | Flutter | F4, F5 | ✅ |
| F7 | **통합 검증** — `flutter analyze` 0 errors, AnimalType/sajuSynergy/elementModifier 참조 0건 확인 | QA | F5, F6 | ✅ |

**Sprint 0 완료 기준:**
- ✅ 관상 결과가 삼정/오관 기반 실제 관상학 해석을 메인으로 보여줌
- ✅ 닮은 동물이 동적 — AI가 자유 제안, DB에 자동 등록
- ✅ "나른한 고양이상" 같은 수식어가 관상 특징에서 도출
- ✅ 동물 리빌 와우 모먼트 유지
- ✅ 궁합이 traits 5축 기반으로 계산
- ✅ 오행 ↔ 동물 억지 연결 완전 제거

---

### 🔥 Sprint ON — 온보딩 & 인증 리디자인 (Sprint A 전 선행)

> **핵심**: Google 로그인 제거 → Apple + Kakao, SMS 인증 추가 (데이팅 사기 방지), 데이팅 프로필 8필드 추가
> **설계 문서**:
> - 마스터 플랜: `docs/plans/2026-03-03-onboarding-redesign-master.md`
> - 백엔드 아키텍처: `docs/plans/2026-03-03-auth-backend-architecture.md`
> - UX 스펙: `docs/design/2026-03-03-full-flow-ux-spec.md`

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| ON1 | **pubspec.yaml 변경** — `google_sign_in` 제거, `kakao_flutter_sdk_user: ^1.9.6` 추가 | 아리 | 없음 | ✅ |
| ON2 | **로그인 페이지 리디자인** — Google 버튼 → Kakao 버튼 (#FEE500), auth_remote_datasource에 `signInWithKakao()` | 아리 | ON1 | ✅ |
| ON3 | **SMS 인증 백엔드** — ~~Edge Function 2개~~ → Supabase Phone Auth + Send SMS Hook + CoolSMS 확정 | 아리 | 없음 | ✅ |
| ON4 | **온보딩 폼 SMS 스텝 추가** — Step 4에 전화번호 입력 + OTP 인증 UI | 아리 | ON3 | ✅ |
| ON5 | **데이팅 프로필 페이지 재설계** — 8필드 (자기소개/키/체형/지역/종교/직업/취미/이상형), 최소 필수: 키+직업+지역 | 아리 | 없음 | ✅ |
| ON6 | **엔티티/모델 업데이트** — `UserEntity` + `MatchProfile`에 body_type, ideal_type, is_phone_verified 등 필드 추가 | 아리 | 없음 | ✅ |
| ON7 | **라우터 + 플로우 연결** — 분석결과 → 데이팅 프로필 → 추천 리스트 → 홈 라우팅 | 아리 | ON5 | ✅ |
| ON8 | **인증 뱃지 시스템** — 매칭 카드에 "진심 마크" 뱃지 표시 (SMS 인증 완료 유저) | 아리 | ON6 | ✅ |
| ON9 | **통합 검증** — flutter analyze 0 errors + iOS build | QA | ON1~ON8 | ✅ |

**Sprint ON 완료 기준:**
- ✅ 로그인 화면에 Apple + Kakao 버튼만 표시
- ✅ 온보딩 Step 4에서 SMS 인증 플로우 동작 (Mock 가능)
- ✅ SMS 인증 **필수화** — "나중에 할게요" 스킵 제거, `_smsVerified` 게이트
- ✅ SMS 아키텍처 확정 — Supabase Phone Auth + Send SMS Hook + CoolSMS (한국 010번호)
- ✅ `send-sms-hook` Edge Function 작성 완료
- ✅ 분석 결과 후 데이팅 프로필 8필드 입력 페이지 표시
- ✅ 프로필 완성 → 추천 리스트 → 홈 전체 플로우 동작
- ✅ 매칭 카드에 인증 뱃지 표시

---

### 🚨 Sprint A — 바이패스 제거 + Auth 실연동 (전체 블로커)

> **핵심 인사이트**: Auth 하나만 뚫으면 BYPASS-2→3→4→5→6이 도미노처럼 제거됨.
> **코드 준비 완료 (2026-03-01)**: entitlements, URL scheme, 딥링크, Storage 마이그레이션, 이미지 업로드 코드 세팅됨.
> **변경 (2026-03-03)**: Google 로그인 → Kakao 로그인으로 전환 (Sprint ON에서 처리). SMS 인증 추가.
> **변경 (2026-03-03 v2)**: Supabase Phone Auth + Send SMS Hook + CoolSMS 최종 확정. OTP는 Supabase 자동 관리, SMS 발송만 CoolSMS(한국 010번호).
> **남은 것**: 노아님의 인프라 설정(Apple Developer / **Kakao Developer Console** / Supabase Dashboard / **CoolSMS**) → BYPASS 제거.
> **인프라 가이드**: `docs/guides/sprint-a-infra-setup.md`

```
의존성 그래프:
  A0(코드 준비) ✅
  A1(Apple 인프라) ──┐
  A2(Google 인프라) ─┤→ A3(BYPASS-1) → A4(DB 마이그레이션) → A5(BYPASS-2) ──┐
  A6(API Key) ─────────────────────────────────────────────────────────────────┤→ A7(BYPASS-3/4)
  A8(Storage 인프라) ──────────────────────────────────────────────────────────┤→ A9(BYPASS-5)
                                                                               └→ A10(BYPASS-6)
```

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| A0 | **코드 사전 준비** — entitlements, URL scheme, 딥링크, Storage SQL, OAuth config, 이미지 업로드 | 아리 | 없음 | ✅ |
| A1 | **Apple Sign In 인프라** — Apple Developer에서 Service ID + Key 발급, Supabase에서 Apple Provider 활성화 | 노아님 | A0 | ⬜ |
| A2 | **Kakao 로그인 인프라** — Kakao Developer Console 앱 등록, Supabase Kakao Provider 활성화 | 노아님 | A0 + ON2 | ⬜ |
| A2.5 | **CoolSMS + Supabase Send SMS Hook 설정** — CoolSMS 계정 생성 + API Key 발급, Supabase Dashboard에서 Phone Provider 활성화 + Send SMS Hook → Edge Function 연결 | 노아님 | ON3 | ⬜ |
| A3 | **BYPASS-1 제거** — Auth 연결 검증 후 `login_page.dart` bypass 블록 삭제 | 아리 | A1 또는 A2 | ⬜ |
| A4 | **profiles 테이블 컬럼 마이그레이션** — `saju_profile_id`, `is_saju_complete`, `is_profile_complete` 등 누락 컬럼 추가 | 아리 | A3 | ⬜ |
| A5 | **BYPASS-2 제거** — 온보딩 프로필 저장 실연동 검증 후 `onboarding_page.dart` bypass 삭제 | 아리 | A4 | ⬜ |
| A6 | **Anthropic API Key Supabase 시크릿 등록** — Edge Functions 환경변수 설정 | 노아님 | 없음 | ⬜ |
| A7 | **BYPASS-3/4 제거** — 사주/관상 Edge Function 실연동 검증 후 `destiny_analysis_page.dart` bypass 삭제 | 아리 | A5 + A6 | ⬜ |
| A8 | **Storage 버킷 인프라** — Supabase Dashboard에서 마이그레이션 적용 확인 | 노아님 | A0 | ⬜ |
| A9 | **BYPASS-5 제거** — 매칭 프로필 저장 실연동 검증 후 `matching_profile_page.dart` bypass 삭제 | 아리 | A5 + A8 | ⬜ |
| A10 | **BYPASS-6 제거** — `app_router.dart` publicPaths에서 matching/chat/profile 제거 | 아리 | A3~A9 전체 | ⬜ |

**Sprint A 완료 기준 (데모 가능):**
- ✅ 실기기 Apple/Kakao 로그인 → `auth.users` 레코드 생성
- ✅ SMS 인증 → `phone_verifications` 레코드 생성
- ✅ 온보딩 → `profiles` 테이블 레코드 생성
- ✅ 사주 분석 → 실제 Edge Function 응답 → `saju_profiles` 저장
- ✅ 비로그인 → `/login` 리다이렉트

---

### 🔥 Sprint B — 실데이터 매칭 (Sprint A 이후)

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| B1 | **`get-daily-matches` Edge Function 신규 구현** — daily_matches 테이블 기반 오늘의 추천 생성 | Backend | A10 | ⬜ |
| B2 | **getDailyRecommendations Mock → 실연동** — MatchingRepositoryImpl에서 Mock 제거 | Flutter | B1 | ⬜ |
| B3 | **MatchProfile 캐릭터 동적 매핑** — `dominant_element` → `CharacterAssets` 매핑 로직 | Flutter | B2 | ⬜ |
| B4 | **궁합 프리뷰 E2E 실유저 테스트** — 실 계정 2개로 전체 플로우 검증 | QA | B2 | 🔶 |

---

### ⚡ Sprint C — 좋아요 시스템 + 프로필 관리 (Sprint B 이후)

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| C1 | **sendLike/acceptLike 실연동** — `likes` 테이블 insert + `daily_usage` 무료 횟수 관리 | Flutter + Backend | A10 | ⬜ |
| C2 | **getReceivedLikes 실연동** — `likes` + `profiles` join 쿼리 | Flutter + Backend | C1 | ⬜ |
| C3 | **받은 좋아요 목록 페이지 완성** — 수락·거절 플로우 UI | Flutter | C2 | ⬜ |
| C4 | **프로필 편집 페이지** — `/profile/edit` 라우트 구현 | Flutter | A10 | ⬜ |

---

### 🌊 Sprint D — Chat + Payment (Sprint C 이후)

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| D1 | **Chat 실연동** — `MockChatRepository` → `ChatRepositoryImpl` + Supabase Realtime 구독 | Flutter + Backend | C1 | ⬜ |
| D2 | **매칭 성사 플로우** — 양방향 좋아요 → `matches` insert → `chat_rooms` 자동 생성 DB 트리거 | Backend | C1 | ⬜ |
| D3 | **Payment RevenueCat 연동** — 인앱 결제 구현, 구독·포인트 모델 | Flutter + Backend | A10 | ⬜ |

---

### 🌙 Sprint E — 궁합 고도화 + 바이럴 (장기)

| # | Task | 담당 | 의존성 | 상태 |
|---|------|------|--------|------|
| E1 | **데이팅용 궁합 규칙집 + 상세 리포트** | PM + 도메인 전문가 | B4 | ⬜ |
| E2 | **십신 기반 커플 궁합 보강** | Backend + 도메인 | E1 | ⬜ |
| E3 | **궁합 가중치 A/B 테스트** | Data + Backend | D3 | ⬜ |
| E4 | **푸시 알림** | Backend + Flutter | D2 | ⬜ |
| E5 | **바이럴 공유 + Mixpanel 분석** | Growth | A10 | ⬜ |

---

### ⚠️ 코드 분석에서 발견된 주의사항

1. **`profiles.saju_profile_id` 순환 참조** — `saju_profiles.user_id` → `profiles.id` + `profiles.saju_profile_id` → `saju_profiles.id`. 마이그레이션 시 `deferrable` constraint 또는 외래키 없이 text로 관리 권장
2. **`character_type` vs `dominant_element` 불일치** — DB check constraint는 캐릭터명(`namuri`), 코드는 오행명(`wood`). 매핑 정리 필요
3. **`UserModel.fromJson`의 `email` 필드** — `profiles` 테이블에 없음. `auth.users`에서 가져와야 하나 RLS 제약 있음

---

## 3. 참조 문서 (다른 디바이스에서 연속 작업 시 먼저 볼 것)

| 문서 | 용도 |
|------|------|
| **본 파일** `docs/plans/2026-02-24-task-master.md` | 다음 할 일·우선순위·담당 관점 |
| `docs/dev-log/2026-02-24-progress.md` | 완료 내역, 아키텍처 현황, 레슨런 |
| `docs/dev-log/2026-02-26-debug-bypass.md` | **6개 바이패스 상세 목록 + 원복 가이드** |
| `docs/plans/2026-02-24-app-design.md` | PRD·MVP 플로우·화면 설계 |
| `docs/plans/2026-02-24-saju-궁합-engine-improvement-proposal.md` | 궁합 엔진 Phase 2/3 로드맵 |
| `docs/plans/2026-02-24-phase1-calculate-compatibility-spec.md` | 궁합 API 스펙·배점·규칙집 |
| `docs/plans/2026-02-25-gwansang-implementation.md` | 관상 구현 계획 (13 Tasks) |
| `docs/plans/2026-02-26-toss-ux-implementation.md` | 토스 UX 구현 계획 (6 Tasks) |
| `docs/plans/2026-02-28-home-ux-redesign-design.md` | 홈 UX 리디자인 설계 (12 섹션) |
| `docs/plans/2026-02-28-home-ux-implementation.md` | 홈 UX 구현 계획 (10 Tasks, 5 Phases) |
| `docs/plans/2026-02-28-gwansang-redesign.md` | 관상 재설계 구현 계획 (9 Tasks) |
| `docs/plans/2026-03-03-onboarding-redesign-master.md` | **온보딩 리디자인 마스터 플랜** (5개 직군 종합) |
| `docs/plans/2026-03-03-auth-backend-architecture.md` | **인증 백엔드 아키텍처** (Kakao OAuth, CoolSMS, DB 스키마) |
| `docs/design/2026-03-03-full-flow-ux-spec.md` | **전체 플로우 UX 스펙** (12섹션 와이어프레임) |
| `docs/guides/sprint-a-infra-setup.md` | **Sprint A 인프라 설정 체크리스트** (Apple/Kakao/CoolSMS/Supabase) |
| `docs/dev-log/2026-03-01-sprint-a-code-prep.md` | Sprint A 코드 사전 준비 상세 기록 |
| `CLAUDE.md` | 개발자룰·아키텍처·에셋·라우팅 규칙 |

---

## 4. 연속 작업 시 체크리스트

- [x] ~~Sprint 0 — 관상 시스템 재설계~~ ✅ 완료
- [x] ~~Sprint A 코드 사전 준비~~ ✅ 완료 (2026-03-01)
- [x] ~~온보딩 리디자인 설계~~ ✅ 완료 (2026-03-03) — 마스터 플랜 + 백엔드 아키텍처 + UX 스펙
- [x] ~~Sprint ON — 온보딩 리디자인 구현~~ ✅ 완료 (2026-03-03) — ON1~ON9 + SMS 필수화 + Send SMS Hook
- [ ] **⭐ Sprint A 인프라 설정 (노아님)** — Apple Developer + Kakao Developer + CoolSMS + Supabase Phone Auth + Send SMS Hook 연결. 가이드: `docs/guides/sprint-a-infra-setup.md`
- [ ] **Sprint A BYPASS 제거 (아리)** — 인프라 완료 후 A3~A10 순차 진행
- [x] ~~**UX 고도화** — 유저 상세페이지 + 궁합 매칭 진입점 Wow 경험~~ ✅ 완료 (2026-03-02)
- [ ] 참조: `docs/dev-log/2026-02-26-debug-bypass.md` (바이패스 상세)
- [ ] `lib/core/di/providers.dart` 확인 (새 Repository/DataSource 추가 시 반드시 등록)
- [ ] 작업 완료 시 본 테스크 마스터 상태(⬜→✅) 및 dev-log 업데이트
