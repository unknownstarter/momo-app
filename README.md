# momo

사주 기반 소개팅 앱 — 운명적 만남을 찾아주는 momo.

---

## Quick Start (새 디바이스 세팅)

### 1. 필수 도구 설치

| 도구 | 설치 |
|------|------|
| **FVM** | `brew tap leoafarias/fvm && brew install fvm` |
| **CocoaPods** | `sudo gem install cocoapods` |
| **Supabase CLI** | `brew install supabase/tap/supabase` |

> Xcode 16+, Node.js 20+ 도 필요합니다.

### 2. 프로젝트 세팅

```bash
# 클론
git clone https://github.com/unknownstarter/momo-app.git momo
cd momo

# Flutter 버전 설치 (.fvmrc 기준 자동)
fvm install

# 의존성
fvm flutter pub get
cd ios && pod install && cd ..

# 코드 생성
fvm dart run build_runner build --delete-conflicting-outputs

# 빌드 검증
fvm flutter analyze lib/
fvm flutter build ios --no-codesign --debug
```

> **VS Code 사용 시**: `.vscode/settings.json`에 FVM SDK 경로가 자동 설정되어 있으므로, VS Code 터미널에서는 `fvm` 접두사 없이 그냥 `flutter`를 써도 됩니다.

### 3. 프로젝트 식별자

| 항목 | 값 |
|------|-----|
| iOS Bundle ID | `com.dropdown.momo` |
| Android App ID | `com.dropdown.momo` |
| Flutter SDK | **3.41.2** (FVM 고정) |
| Supabase Project | `ejngitwtzecqbhbqfnsc` |

---

## 이어서 작업할 때

1. `git pull`
2. `fvm install` (Flutter 버전 변경 시만)
3. `fvm flutter pub get`
4. **테스크 마스터** 확인: `docs/plans/2026-02-24-task-master.md`

---

## 주요 문서

| 문서 | 용도 |
|------|------|
| `CLAUDE.md` | 개발 규칙, 아키텍처, 코딩 컨벤션 |
| `docs/plans/2026-02-24-task-master.md` | 다음 할 일, 우선순위, 스프린트 현황 |
| `docs/dev-log/2026-02-24-progress.md` | 완료 내역, 레슨런 |
| `docs/guides/sprint-a-infra-setup.md` | Auth 인프라 설정 체크리스트 |
