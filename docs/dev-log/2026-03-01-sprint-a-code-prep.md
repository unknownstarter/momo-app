# 개발 일지 — 2026-03-01: Sprint A 코드 사전 준비

> Sprint A (Auth 실연동)의 코드 사전 준비 완료.
> 인프라 설정(Apple Developer / Google Cloud Console / Supabase Dashboard)만 하면 Auth가 바로 작동하도록 모든 코드를 세팅함.

---

## 완료된 작업 (8개 태스크)

### Task 1: iOS Sign in with Apple Entitlements

**신규 파일:**
- `ios/Runner/Runner.entitlements` — `com.apple.developer.applesignin` capability

**수정 파일:**
- `ios/Runner.xcodeproj/project.pbxproj`
  - PBXFileReference에 Runner.entitlements 등록
  - Runner 그룹 children에 entitlements 파일 추가
  - Debug/Release/Profile 3개 빌드 설정에 `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` 추가

### Task 2: iOS Info.plist URL Scheme

**수정 파일:**
- `ios/Runner/Info.plist` — `CFBundleURLTypes` 추가
  - scheme: `com.nworld.momo` (Supabase Auth PKCE 콜백용)

### Task 3: Android Deep Link

**수정 파일:**
- `android/app/src/main/AndroidManifest.xml` — OAuth 콜백용 intent-filter 추가
  - `<data android:scheme="com.nworld.momo" android:host="login-callback" />`

### Task 4: Supabase Auth 딥링크 콜백

**확인 결과:**
- `lib/main.dart`의 `FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce)` 이미 설정됨
- supabase_flutter v2.12.0은 URL scheme 등록만으로 딥링크 자동 처리 (별도 코드 불필요)
- `SceneDelegate.swift`가 `FlutterSceneDelegate` 상속 → URL handling 내장

### Task 5: Supabase Storage 버킷

**수정 파일:**
- `supabase/config.toml` — `[storage.buckets.profile-images]` 섹션 추가
  - file_size_limit: 10MiB
  - allowed_mime_types: png, jpeg, webp, heic

**신규 파일:**
- `supabase/migrations/20260301000001_profile_images_bucket.sql`
  - `profile-images` 버킷 생성 (INSERT ON CONFLICT DO NOTHING)
  - RLS 정책 4개: upload(자기 폴더만) / update(자기만) / delete(자기만) / select(인증 유저 전체)

### Task 6: 프로필 이미지 업로드 코드 보강

**수정 파일:**
- `lib/features/profile/domain/repositories/profile_repository.dart`
  - `uploadProfileImages(List<String> localFilePaths)` 메서드 추가
- `lib/features/profile/data/repositories/profile_repository_impl.dart`
  - `uploadProfileImages` 구현: 로컬 파일 → Storage `{authId}/profile_{i}.{ext}` 업로드 → URL 반환
  - `FileOptions(upsert: true)` — 같은 슬롯 재업로드 시 덮어쓰기

### Task 7: Google OAuth Provider

**수정 파일:**
- `supabase/config.toml`
  - `[auth.external.google]` 섹션 추가 (enabled=false, 환경변수 참조)
  - `skip_nonce_check = true` (네이티브 Google Sign-In 호환)
  - `additional_redirect_urls`에 `com.nworld.momo://login-callback` 추가

### Task 8: 인프라 설정 가이드

**신규 파일:**
- `docs/guides/sprint-a-infra-setup.md`
  - Apple Developer 설정 (App ID capability + Service ID + Key)
  - Google Cloud Console 설정 (OAuth 동의 + Web/iOS/Android Client ID)
  - Supabase Dashboard 설정 (Apple/Google Provider 활성화 + Redirect URL)
  - Flutter 빌드 환경변수
  - iOS/Android 테스트 절차
  - BYPASS 제거 체크리스트

---

## 검증 결과

- `flutter analyze lib/` — **0 errors** (기존 info/warning 28개 동일)
- `flutter build ios --no-codesign --debug` — **빌드 성공** (60.9s)
- Entitlements가 Xcode 프로젝트 3개 빌드 설정에 모두 정상 참조됨

---

## 수정 파일 요약

| 파일 | 작업 |
|------|------|
| `ios/Runner/Runner.entitlements` | **신규** — Apple Sign In capability |
| `ios/Runner.xcodeproj/project.pbxproj` | entitlements 참조 + CODE_SIGN_ENTITLEMENTS (Debug/Release/Profile) |
| `ios/Runner/Info.plist` | CFBundleURLTypes URL Scheme 추가 |
| `android/app/src/main/AndroidManifest.xml` | OAuth 딥링크 intent-filter 추가 |
| `lib/main.dart` | 코멘트 정리 (기능 변경 없음) |
| `lib/features/profile/domain/repositories/profile_repository.dart` | uploadProfileImages 인터페이스 추가 |
| `lib/features/profile/data/repositories/profile_repository_impl.dart` | uploadProfileImages 구현 |
| `supabase/config.toml` | Google OAuth + Storage 버킷 + redirect URL |
| `supabase/migrations/20260301000001_profile_images_bucket.sql` | **신규** — 프로필 이미지 버킷 + RLS |
| `docs/guides/sprint-a-infra-setup.md` | **신규** — 인프라 설정 체크리스트 |

---

## 다음 액션

1. **노아님 인프라 설정**: `docs/guides/sprint-a-infra-setup.md` 체크리스트 수행
2. **BYPASS 도미노 제거**: 인프라 완료 → A3~A10 순차 진행
3. **UX 고도화**: 유저 상세페이지 + 궁합 매칭 진입점 Wow 경험 설계
