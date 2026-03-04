# 디버그 바이패스 목록 (kDebugMode) — ✅ 전체 제거 완료

> 작성일: 2026-02-26
> **전체 제거 완료: 2026-03-04** — Sprint A BYPASS 제거 작업으로 8건 모두 실연동 코드로 교체됨.
> 목적: Backend(Supabase) 및 외부 API 미연결 상태에서 전체 플로우를 시뮬레이터에서 테스트하기 위한 임시 우회 처리

## 원복 현황

**✅ 8건 전체 제거 완료 (2026-03-04)**

코드에서 `TODO(PROD)` 또는 `BYPASS-` 검색 결과: **0건**

```bash
grep -rn "BYPASS-" lib/ --include="*.dart"   # 0 results
grep -rn "TODO(PROD)" lib/ --include="*.dart" # 0 results
```

---

## 바이패스 목록 (전체 제거됨)

### ✅ BYPASS-1: 로그인 인증 바이패스
- **파일**: `lib/features/auth/presentation/pages/login_page.dart`
- **제거일**: 2026-03-04
- **내용**: Apple/Kakao 로그인 실패 시 kDebugMode 블록 삭제. 실패 → 에러 스낵바만 표시.

### ✅ BYPASS-2: 온보딩 프로필 저장 바이패스
- **파일**: `lib/features/auth/presentation/pages/onboarding_page.dart`
- **제거일**: 2026-03-04
- **내용**: 프로필 저장 실패 시 kDebugMode 블록 삭제. 실패 → 에러 스낵바만 표시.

### ✅ BYPASS-3: 사주 분석 바이패스
- **파일**: `lib/features/destiny/presentation/pages/destiny_analysis_page.dart`
- **제거일**: 2026-03-04
- **내용**: Mock saju 결과 생성 블록 + `_createMockSajuResult()` 메서드 삭제. 실패 → 에러 화면 + 재시도.

### ✅ BYPASS-4: 관상 분석 바이패스
- **파일**: `lib/features/destiny/presentation/pages/destiny_analysis_page.dart`
- **제거일**: 2026-03-04
- **내용**: Mock gwansang 결과 생성 블록 + `_createMockGwansangResult()` 메서드 삭제. 실패 → 사주만으로 graceful degradation.

### ✅ BYPASS-5: 매칭 프로필 저장 바이패스
- **파일**: `lib/features/profile/presentation/pages/matching_profile_page.dart`
- **제거일**: 2026-03-04
- **내용**: 프로필 저장 실패 시 매칭 직행 kDebugMode 블록 삭제. 실패 → 에러 스낵바, 페이지 유지.

### ✅ BYPASS-6: SMS 인증번호 발송 mock
- **파일**: `lib/features/auth/presentation/pages/onboarding_form_page.dart`
- **제거일**: 2026-03-04
- **내용**: 800ms delay mock → Firebase `verifyPhoneNumber()` 실 SMS 발송으로 교체.

### ✅ BYPASS-7: SMS 인증번호 검증 mock
- **파일**: `lib/features/auth/presentation/pages/onboarding_form_page.dart`
- **제거일**: 2026-03-04
- **내용**: 500ms delay mock → Firebase `PhoneAuthProvider.credential()` + `signInWithCredential()` 실 OTP 검증으로 교체. 인증 성공 시 Supabase profiles 테이블에 phone + is_phone_verified 저장 후 Firebase signOut.

### ✅ BYPASS-8: 라우터 publicPaths 확장
- **파일**: `lib/app/routes/app_router.dart`
- **제거일**: 2026-03-04
- **내용**: matching, chat, profile 경로를 publicPaths에서 제거. 비로그인 시 `/login`으로 리다이렉트.

---

## 추가 참고: iOS 시뮬레이터 전용 설정

아래는 바이패스가 아니라 시뮬레이터 빌드 지원을 위한 설정이므로, 실기기 빌드 시 별도 처리 필요:

- **`pubspec_overrides.yaml`** (gitignored): ML Kit → stub 패키지 오버라이드. 실기기 빌드 시 이 파일 삭제하면 원본 ML Kit 사용.
- **`stubs/google_mlkit_face_detection/`**: 시뮬레이터 전용 순수 Dart 스텁. 실기기에서는 사용하지 않음.
