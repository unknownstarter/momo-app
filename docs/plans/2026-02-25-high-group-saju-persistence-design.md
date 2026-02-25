# High 그룹 설계: 사주 저장 파이프라인 + 실데이터 연동

> **작성일**: 2026-02-25
> **승인**: 노아님
> **접근**: Bottom-up (데이터 파이프라인 → 핸드오프 수정 → 검증+와우모먼트)
> **참조**: 테스크마스터 `docs/plans/2026-02-24-task-master.md` #1~#3

---

## 1. 문제 정의

### 현재 상태
- 온보딩 → 사주 분석까지 동작하지만, **결과가 DB에 저장되지 않음**
- 궁합 계산 시 상대방 사주를 `saju_profiles` 테이블에서 조회 → 항상 `null` 반환
- 시진(자시/축시...) → HH:mm 변환 누락으로 Edge Function 400 에러 발생 가능
- 온보딩 → 사주 분석 페이지로 userId가 전달되지 않음

### 해결 후 목표
- 온보딩 완료 → 사주 분석 → **결과 자동 저장** → 궁합 계산 가능
- 전체 루프: 온보딩 → 사주 → 홈 → 매칭 카드 → 궁합 프리뷰가 실데이터로 동작

---

## 2. 설계

### 2.1 데이터 흐름 (Target)

```
OnboardingFormPage
  └── 시진 선택 → _siJinToHHmm() → "00:00" (HH:mm)
  └── formData = { name, gender, birthDate, birthTime: "00:00", isLunar }
        │
        ▼
OnboardingPage._onFormComplete(formData)
  └── saveOnboardingData(formData) → UserEntity (profiles.id 획득)
  └── context.go(sajuAnalysis, extra: {
        userId: userEntity.id,
        birthDate, birthTime, isLunar, userName
      })
        │
        ▼
SajuAnalysisPage (analysisData에서 userId 등 수신)
  └── sajuAnalysisNotifier.analyze(userId, birthDate, birthTime, ...)
        │
        ▼
SajuRepositoryImpl.analyzeSaju()
  ├── Step 1: Edge Function calculate-saju → SajuProfileModel
  ├── Step 2: Edge Function generate-saju-insight → SajuInsightModel
  ├── Step 3: datasource.saveSajuProfile(userId, model+insight)
  │     └── saju_profiles UPSERT (onConflict: user_id) → savedId
  ├── Step 4: datasource.linkSajuProfileToUser(userId, savedId, element, character)
  │     └── profiles UPDATE (saju_profile_id, dominant_element, character_type)
  └── Step 5: return SajuProfile(id: savedId) ← 실제 DB ID
        │
        ▼
이후 궁합 계산 시:
  getSajuForCompatibility(userId) → saju_profiles에서 조회 → 데이터 있음 ✅
```

### 2.2 수정 파일 목록

| # | 파일 | 작업 | 변경 내용 |
|---|------|------|-----------|
| 1 | `supabase/migrations/20260225_add_saju_profile_id.sql` | CREATE | profiles에 saju_profile_id 컬럼 추가 |
| 2 | `lib/features/saju/domain/repositories/saju_repository.dart` | MODIFY | `saveSajuProfile` 추상 메서드 추가 |
| 3 | `lib/features/saju/data/datasources/saju_remote_datasource.dart` | MODIFY | `saveSajuProfile()`, `linkSajuProfileToUser()` 추가, birthDate 하드코딩 수정 |
| 4 | `lib/features/saju/data/repositories/saju_repository_impl.dart` | MODIFY | analyzeSaju에 저장 로직(Step 3~5) 추가 |
| 5 | `lib/features/auth/presentation/pages/onboarding_form_page.dart` | MODIFY | 시진→HH:mm 변환, `birthHour`→`birthTime` 키 변경 |
| 6 | `lib/features/auth/presentation/providers/onboarding_provider.dart` | MODIFY | `formData['birthHour']`→`formData['birthTime']` |
| 7 | `lib/features/auth/presentation/pages/onboarding_page.dart` | MODIFY | UserEntity에서 userId 추출, extra로 analysisData 전달 |

### 2.3 시진 → HH:mm 변환 테이블

| Index | 시진 | 시간 범위 | 대표 시각 |
|-------|------|-----------|-----------|
| 0 | 자시(子時) | 23:00~01:00 | 00:00 |
| 1 | 축시(丑時) | 01:00~03:00 | 02:00 |
| 2 | 인시(寅時) | 03:00~05:00 | 04:00 |
| 3 | 묘시(卯時) | 05:00~07:00 | 06:00 |
| 4 | 진시(辰時) | 07:00~09:00 | 08:00 |
| 5 | 사시(巳時) | 09:00~11:00 | 10:00 |
| 6 | 오시(午時) | 11:00~13:00 | 12:00 |
| 7 | 미시(未時) | 13:00~15:00 | 14:00 |
| 8 | 신시(申時) | 15:00~17:00 | 16:00 |
| 9 | 유시(酉時) | 17:00~19:00 | 18:00 |
| 10 | 술시(戌時) | 19:00~21:00 | 20:00 |
| 11 | 해시(亥時) | 21:00~23:00 | 22:00 |

### 2.4 DB 마이그레이션

```sql
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS saju_profile_id uuid
  REFERENCES public.saju_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_saju_profile
  ON public.profiles(saju_profile_id);
```

### 2.5 에러 처리 전략

- **Fail-hard**: DB 저장 실패 시 전체 analyzeSaju 실패 → 기존 에러 UI 표시 (SajuAnalysisPage에 "다시 시도" 버튼 있음)
- **Upsert**: 같은 사용자가 재분석해도 안전하게 덮어쓰기 (onConflict: user_id)
- 사주 분석은 성공했지만 저장만 실패한 경우도 에러로 처리 — 저장 없이는 궁합이 불가하므로

### 2.6 RLS 고려사항

- `saju_profiles` INSERT: `saju_insert_own` 정책 — `user_id = current_profile_id()` 확인
- `profiles` UPDATE: `profiles_update_own` 정책 — `auth_id = auth.uid()` 확인
- 쓰기 순서: profiles INSERT (온보딩) → saju_profiles UPSERT → profiles UPDATE (link)

### 2.7 와우 모먼트 포인트

| 시점 | 와우 요소 | 구현 수준 |
|------|-----------|-----------|
| 사주 분석 완료→저장 | 캐릭터가 "사주가 저장됐어!" 리액션 | 기존 결과 페이지에 자연스럽게 포함 |
| 첫 궁합 프리뷰 | 게이지 0→점수 애니메이션 | 이미 구현됨 ✅ |
| 궁합 실데이터 첫 확인 | "실제 사주 기반 궁합이에요" 뱃지/문구 | 간단 텍스트 추가 |

---

## 3. 테스크 마스터 매핑

| 테스크 마스터 # | 본 설계 커버리지 |
|----------------|------------------|
| #2 프로필·사주 저장 연동 | 2.1~2.6 전체 |
| #3 궁합 프리뷰 실사용 검증 | 파이프라인 완성 후 자동 해소 |
| #1 daily_matches | 본 설계 이후 별도 (사주 저장이 선결 조건) |

---

## 4. 구현 순서

### Phase A: 데이터 기반 (Backend, UI 변경 없음)
1. DB 마이그레이션 생성
2. `SajuRemoteDatasource`에 `saveSajuProfile()`, `linkSajuProfileToUser()` 추가
3. `SajuRepository` 인터페이스에 `saveSajuProfile` 추가
4. `SajuRepositoryImpl.analyzeSaju()`에 저장 로직 통합

### Phase B: 핸드오프 수정 (온보딩 → 사주 분석)
5. `onboarding_form_page.dart`에 시진→HH:mm 변환 추가
6. `onboarding_provider.dart` 키 이름 수정
7. `onboarding_page.dart`에서 userId+analysisData extra 전달

### Phase C: 검증
8. 풀 루프 테스트: 온보딩 → 사주 분석 → 결과 확인 → 홈 → 궁합 프리뷰
9. DB 확인: saju_profiles에 행 생성, profiles.saju_profile_id 연결
10. flutter analyze + flutter test 통과 확인
