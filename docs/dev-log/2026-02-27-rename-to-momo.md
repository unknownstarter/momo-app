# 프로젝트 리네이밍: Saju App → Momo (2026-02-27)

---

## 배경

노아님이 앱 이름을 **momo**로 확정. 프로젝트 전반의 식별자·패키지명·저장소명을 일괄 변경.

---

## 변경 내역

### 1. Flutter 패키지명

| 항목 | Before | After |
|------|--------|-------|
| `pubspec.yaml` name | `saju_app` | `momo_app` |
| `pubspec.yaml` description | 사주 기반 소개팅 앱 - 운명적 만남을 찾아주는 사주인연 | momo - 사주 기반 소개팅 앱, 운명적 만남 |
| 루트 위젯 클래스 | `SajuApp` | `MomoApp` |
| 앱 타이틀 | 사주인연 | momo |
| `import 'package:...'` | `package:saju_app/...` | `package:momo_app/...` |

**변경 파일:**
- `pubspec.yaml`
- `lib/main.dart`
- `lib/app/app.dart`
- `lib/core/widgets/widgets.dart` (barrel export import)
- `lib/core/theme/tokens/tokens.dart` (barrel export import)
- `test/widget_test.dart`
- `test/core/widgets/saju_button_test.dart`
- `test/core/widgets/saju_input_test.dart`
- `test/core/widgets/saju_avatar_test.dart`
- `test/core/widgets/saju_chip_test.dart`
- `test/core/widgets/saju_badge_test.dart`
- `test/core/widgets/saju_card_test.dart`
- `test/core/widgets/saju_character_bubble_test.dart`

### 2. iOS 설정

| 항목 | Before | After |
|------|--------|-------|
| Bundle Identifier | `com.nworld.sajuApp` | `com.dropdown.momo` |
| CFBundleDisplayName | `Saju App` | `momo` |
| CFBundleName | `saju_app` | `momo` |
| Test Bundle ID | `com.nworld.sajuApp.RunnerTests` | `com.dropdown.momo.RunnerTests` |

**변경 파일:**
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj` (6곳)

### 3. Android 설정

| 항목 | Before | After |
|------|--------|-------|
| namespace | `com.nworld.saju_app` | `com.dropdown.momo` |
| applicationId | `com.nworld.saju_app` | `com.dropdown.momo` |
| android:label | `saju_app` | `momo` |
| Kotlin package | `com.nworld.saju_app` | `com.dropdown.momo` |

**변경 파일:**
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/nworld/momo/MainActivity.kt` (디렉토리 이동)

### 4. Web 설정

| 항목 | Before | After |
|------|--------|-------|
| manifest name | `saju_app` | `momo` |
| manifest short_name | `saju_app` | `momo` |

**변경 파일:**
- `web/manifest.json`

### 5. Supabase 설정

| 항목 | Before | After |
|------|--------|-------|
| config.toml project_id | `saju-app` | `momo-app` |

**변경 파일:**
- `supabase/config.toml`

### 6. IDE 메타데이터

| 항목 | Before | After |
|------|--------|-------|
| Root .iml | `saju_app.iml` | `momo_app.iml` |
| Android .iml | `saju_app_android.iml` | `momo_app_android.iml` |
| modules.xml 참조 | saju_app → momo_app | 반영 |

### 7. GitHub 저장소

| 항목 | Before | After |
|------|--------|-------|
| Repository name | `unknownstarter/saju-app` | `unknownstarter/momo-app` |
| Remote URL | `https://github.com/unknownstarter/saju-app.git` | `https://github.com/unknownstarter/momo-app.git` |

### 8. 문서

| 항목 | Before | After |
|------|--------|-------|
| `README.md` 제목 | `# saju_app` | `# momo` |
| `CLAUDE.md` 제목 | `# Saju App — 사주 기반 소개팅 앱` | `# Momo — 사주 기반 소개팅 앱` |
| `MEMORY.md` 제목 | `# Saju App — 아리(Ari) 메모리` | `# Momo — 아리(Ari) 메모리` |

---

## 변경하지 않은 것

- **feature 이름** (`features/saju/`, `features/gwansang/` 등): 도메인 용어이므로 유지
- **위젯 prefix** (`Saju` prefix: `SajuButton`, `SajuCard` 등): 디자인 시스템 네이밍이므로 유지
- **docs/ 내 과거 문서들**: 기록 목적이므로 유지 (새 문서부터 Momo 사용)
- **Supabase Edge Function 이름** (`calculate-saju` 등): 기능 식별자이므로 유지
- **DB 테이블명** (`saju_profiles`, `gwansang_profiles` 등): 스키마 안정성 유지

---

## 빌드 검증

- `flutter pub get` ✅
- `flutter build ios --debug --simulator` ✅ (`com.dropdown.momo`)
- 시뮬레이터 실행 ✅

---

## 주의사항

- **로컬 프로젝트 폴더**: `~/saju-app/` → `~/momo-app/` 수동 변경 필요 (Claude Code 세션 외부에서)
- 폴더 변경 후 Claude Code의 메모리 디렉토리 경로(`-Users-noah-saju-app`)는 자동으로 새 세션에서 재생성됨
