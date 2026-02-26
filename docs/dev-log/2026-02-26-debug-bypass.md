# 디버그 바이패스 목록 (kDebugMode)

> 작성일: 2026-02-26
> 목적: Backend(Supabase) 및 외부 API 미연결 상태에서 전체 플로우를 시뮬레이터에서 테스트하기 위한 임시 우회 처리

## 원복 시점

**Supabase Auth + DB + Edge Functions 연결이 완료되면 반드시 원복할 것.**

코드에서 `TODO(PROD)` 또는 `BYPASS-` 로 검색하면 모든 바이패스 포인트를 찾을 수 있습니다.

```bash
grep -rn "BYPASS-" lib/ --include="*.dart"
grep -rn "TODO(PROD)" lib/ --include="*.dart"
```

---

## 바이패스 목록

### BYPASS-1: 로그인 인증 바이패스
- **파일**: `lib/features/auth/presentation/pages/login_page.dart`
- **위치**: `_handleSignIn()` catch 블록
- **동작**: Apple/Google 로그인 실패 시 → `RoutePaths.onboarding`으로 직행
- **원복**: Supabase Auth (Apple/Google OAuth) 연결 후 kDebugMode 블록 삭제
- **의존**: Google OAuth Client ID (`GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`) 설정

### BYPASS-2: 온보딩 프로필 저장 바이패스
- **파일**: `lib/features/auth/presentation/pages/onboarding_page.dart`
- **위치**: `_onFormComplete()` catch 블록
- **동작**: 프로필 저장 실패 시 → Mock 데이터로 `RoutePaths.destinyAnalysis` 진행
- **Mock 데이터**: userId=`dev-mock-user-001`, birthDate=`1995-03-15`, birthTime=`14:00`
- **원복**: Supabase `profiles` 테이블 연결 후 kDebugMode 블록 삭제

### BYPASS-3: 사주 분석 바이패스
- **파일**: `lib/features/destiny/presentation/pages/destiny_analysis_page.dart`
- **위치**: `sajuAnalysisNotifierProvider` 에러 리스너
- **동작**: 사주 분석 API 실패 시 → Mock SajuAnalysisResult 생성 후 관상 분석으로 진행
- **Mock 데이터**: 갑자일주, 목(木) dominant, 나무리 캐릭터, AI 해석 텍스트 하드코딩
- **원복**: manseryeok Edge Function + Claude API 연결 후 kDebugMode 블록 삭제
- **관련 함수**: `_createMockSajuResult()` — 바이패스 제거 시 함께 삭제

### BYPASS-4: 관상 분석 바이패스
- **파일**: `lib/features/destiny/presentation/pages/destiny_analysis_page.dart`
- **위치**: `gwansangAnalysisNotifierProvider` 에러 리스너
- **동작**: 관상 분석 API 실패 시 → Mock GwansangAnalysisResult 생성 후 결과 페이지 진행
- **Mock 데이터**: 여우상(fox), "봄바람의 영리한 여우상", 매력 키워드 4개
- **원복**: ML Kit + Claude API 관상 분석 연결 후 kDebugMode 블록 삭제
- **관련 함수**: `_createMockGwansangResult()` — 바이패스 제거 시 함께 삭제

### BYPASS-5: 매칭 프로필 저장 바이패스
- **파일**: `lib/features/profile/presentation/pages/matching_profile_page.dart`
- **위치**: `_submitProfile()` 실패 분기
- **동작**: 프로필 저장 실패 시 → `RoutePaths.home`으로 직행
- **원복**: Supabase `profiles` 테이블 (matching profile 컬럼들) 연결 후 kDebugMode 블록 삭제

### BYPASS-6: 라우터 publicPaths 확장
- **파일**: `lib/app/routes/app_router.dart`
- **위치**: `publicPaths` 리스트
- **동작**: matching, chat, profile 경로를 비인증 접근 허용
- **원복**: 인증 시스템 연결 후 해당 3줄 제거 (matching, chat, profile을 publicPaths에서 빼기)
- **주의**: home은 "둘러보기 모드"로 의도적 public이므로 유지

---

## 추가 참고: iOS 시뮬레이터 전용 설정

아래는 바이패스가 아니라 시뮬레이터 빌드 지원을 위한 설정이므로, 실기기 빌드 시 별도 처리 필요:

- **`pubspec_overrides.yaml`** (gitignored): ML Kit → stub 패키지 오버라이드. 실기기 빌드 시 이 파일 삭제하면 원본 ML Kit 사용.
- **`stubs/google_mlkit_face_detection/`**: 시뮬레이터 전용 순수 Dart 스텁. 실기기에서는 사용하지 않음.
