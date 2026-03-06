# Supabase 프로젝트 이전 가이드

> **작성일**: 2026-03-05
> **목적**: 기존 Supabase 프로젝트(`csjdfvxyjnpmbkjbomyf`)를 다른 계정의 Supabase 프로젝트로 이전
> **전제**: 실유저 0명 (개발 단계) → 지금이 이전 최적 타이밍

---

## 1. 이전 범위 요약

| 항목 | 난이도 | 설명 |
|------|--------|------|
| DB 스키마 | 쉬움 | 마이그레이션 SQL 파일 순서대로 실행 |
| Edge Functions | 쉬움 | 폴더째 새 프로젝트에 배포 |
| Secrets | 쉬움 | `ANTHROPIC_API_KEY` 등 재등록 |
| Storage 버킷 | 쉬움 | `profile-images` 버킷 생성 (마이그레이션에 포함) |
| Auth Provider | 중간 | Apple/Kakao OAuth Redirect URL 변경 필요 |
| Flutter 코드 | 쉬움 | URL + Anon Key 2줄만 교체 |

---

## 2. 변경이 필요한 것 vs 안 바뀌는 것

### 바뀌는 것

| 항목 | 현재 값 | 변경 위치 |
|------|---------|-----------|
| Supabase Project URL | `https://csjdfvxyjnpmbkjbomyf.supabase.co` | `lib/core/network/supabase_client.dart` |
| Supabase Anon Key | (현재 키) | `lib/core/network/supabase_client.dart` |
| Supabase Project ID | `csjdfvxyjnpmbkjbomyf` | `supabase/config.toml` (project_id) |
| Apple OAuth Redirect URL | Supabase가 발급하는 콜백 URL | Apple Developer Console > Service ID |
| Kakao OAuth Redirect URL | Supabase가 발급하는 콜백 URL | Kakao Developers Console > 앱 설정 |

### 안 바뀌는 것

| 항목 | 이유 |
|------|------|
| Flutter 코드 구조 | Supabase와 무관 |
| Firebase 설정 | SMS 인증은 Firebase (독립) |
| Bundle ID (`com.dropdown.momo`) | 앱 식별자는 Supabase와 무관 |
| Edge Function 코드 | 로직 동일, 배포 대상만 변경 |
| DB 스키마 설계 | 마이그레이션 SQL 그대로 사용 |
| RLS 정책 | 마이그레이션에 포함 |

---

## 3. 작업 순서 (체크리스트)

### Phase 1: 새 프로젝트 생성 + DB 설정

- [ ] **1-1. 새 Supabase 프로젝트 생성** (대상 계정에서)
  - Region: Northeast Asia (ap-northeast-1) 권장 (한국 타겟)
  - 프로젝트 이름: `momo` 또는 원하는 이름
  - DB 비밀번호 기록해둘 것

- [ ] **1-2. 프로젝트 정보 기록**
  - 새 Project URL: `https://__________.supabase.co`
  - 새 Anon Key: `eyJ___...`
  - 새 Service Role Key: (Edge Function에서 필요 시)
  - 새 Project ID: (CLI 링크에 사용)

- [ ] **1-3. DB 마이그레이션 실행** (순서 중요!)
  ```
  supabase/migrations/ 폴더의 SQL 파일을 시간순으로 실행:
  1. 기본 테이블 (profiles, saju_profiles, gwansang_profiles 등)
  2. RLS 정책
  3. 20260304000001_add_sprint_on_columns.sql
  4. 20260304000002_sync_profiles_to_auth.sql
  5. 20260305000001_phone_unique_constraint.sql
  6. 20260305000002_gwansang_profiles_add_columns.sql
  7. 20260305000004_profile_images_bucket_public.sql
  ```
  - 방법 A: Supabase CLI `supabase db push` (새 프로젝트 링크 후)
  - 방법 B: Supabase Dashboard > SQL Editor에서 수동 실행

### Phase 2: Auth Provider 설정

- [ ] **2-1. Apple Sign In 설정**
  - Supabase Dashboard > Authentication > Providers > Apple
  - Apple Developer Console에서:
    - Service ID의 Return URL을 새 Supabase 콜백 URL로 변경
    - 형식: `https://{새_PROJECT_ID}.supabase.co/auth/v1/callback`
  - 기존 Apple Key(.p8)는 재사용 가능

- [ ] **2-2. Kakao 로그인 설정**
  - Supabase Dashboard > Authentication > Providers > Kakao
  - REST API 키 + Client Secret 입력
  - Kakao Developers Console에서:
    - 플랫폼 > Web > Redirect URI를 새 Supabase 콜백 URL로 변경
    - 형식: `https://{새_PROJECT_ID}.supabase.co/auth/v1/callback`
  - **주의**: 동의항목에서 이메일 "선택 동의" 설정 유지

- [ ] **2-3. Auth 설정 확인**
  - Dashboard > Authentication > URL Configuration
  - Site URL: 앱 딥링크 (`com.dropdown.momo://login-callback/`)
  - Redirect URLs: `com.dropdown.momo://login-callback/` 추가
  - `enable_manual_linking` 설정 확인 (1인1계정 정책)

### Phase 3: Edge Functions + Secrets

- [ ] **3-1. Supabase CLI 새 프로젝트 링크**
  ```bash
  supabase link --project-ref {새_PROJECT_ID}
  ```

- [ ] **3-2. Secrets 등록**
  ```bash
  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
  ```

- [ ] **3-3. Edge Functions 배포**
  ```bash
  supabase functions deploy calculate-saju --no-verify-jwt
  supabase functions deploy generate-saju-insight --no-verify-jwt
  supabase functions deploy calculate-compatibility --no-verify-jwt
  supabase functions deploy generate-gwansang-reading --no-verify-jwt
  ```
  - **주의**: 모든 Edge Function에 `--no-verify-jwt` 필수 (Supabase 유저 JWT가 ES256 알고리즘을 사용하여 기본 검증기와 비호환)

### Phase 4: Flutter 코드 교체

- [ ] **4-1. Supabase URL + Anon Key 교체**
  - 파일: `lib/core/network/supabase_client.dart`
  - `supabaseUrl`과 `supabaseAnonKey` 값만 변경

- [ ] **4-2. config.toml 업데이트** (선택)
  - 파일: `supabase/config.toml`
  - `project_id` 값 변경

### Phase 5: 테스트 검증

- [ ] **5-1. 빌드 확인**
  ```bash
  fvm flutter analyze lib/
  fvm flutter build ios --no-codesign --debug
  ```

- [ ] **5-2. E2E 플로우 테스트** (시뮬레이터 또는 실기기)
  - [ ] Apple 로그인 → auth.users 레코드 생성 확인
  - [ ] Kakao 로그인 → auth.users 레코드 생성 확인
  - [ ] SMS 인증 → Firebase (Supabase 무관, 동작 확인만)
  - [ ] 온보딩 → profiles 테이블 INSERT 확인
  - [ ] 사주 분석 → Edge Function 호출 → saju_profiles 저장 확인
  - [ ] 관상 분석 → Edge Function 호출 → gwansang_profiles 저장 확인
  - [ ] 비로그인 상태 → /login 리다이렉트 확인

- [ ] **5-3. 모든 테스트 통과 후 커밋**

---

## 4. 롤백 계획

만약 이전 중 문제가 발생하면:

```bash
# Flutter 코드 변경사항 전부 원복
git checkout .
```

- 기존 Supabase 프로젝트는 건드리지 않으므로 그대로 살아 있음
- 새 프로젝트만 삭제하면 완전 원상복구

---

## 5. 이전 후 정리

- [ ] 기존 Supabase 프로젝트 비활성화/삭제 (안정화 확인 후)
- [ ] CLAUDE.md의 Project ID 업데이트
- [ ] 테스크 마스터의 Supabase 프로젝트 정보 업데이트
- [ ] `docs/guides/sprint-a-infra-setup.md`의 Project ID 업데이트
- [ ] `docs/plans/2026-03-03-auth-backend-architecture.md`의 Project ID 업데이트

---

## 6. 예상 소요 시간

| Phase | 소요 |
|-------|------|
| 프로젝트 생성 + DB | 15분 |
| Auth Provider 설정 | 20분 |
| Edge Functions 배포 | 10분 |
| Flutter 코드 교체 | 5분 |
| E2E 테스트 | 30분 |
| **합계** | **~1시간 20분** |

> **핵심**: 실유저 데이터가 없는 지금이 이전 최적 타이밍. 나중에 유저가 쌓이면 데이터 마이그레이션까지 필요해져서 10배 이상 복잡해짐.
