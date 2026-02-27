# Glassmorphism 플로팅 하단 네비게이션 바 — 구현 가이드

> 작성일: 2026-02-27 | 파일: `lib/app/routes/app_router.dart`

## 개요

iOS 스타일 Glassmorphism(프로스티드 글래스) 효과를 적용한 플로팅 하단 네비바.
단순 블러가 아닌 **5레이어 스택**으로 실제 유리판 느낌을 구현한다.

## 레퍼런스

iOS 홈화면 Dock — `UIVisualEffectView` + `UIBlurEffect` 조합의 프로스티드 글래스.

## 최종 레이어 구조 (아래→위)

```
┌─────────────────────────────────────┐
│  5. Shadow (DecoratedBox)           │  ← 떠있는 깊이감
│  ┌─────────────────────────────────┐│
│  │  4. Border (0.5px)              ││  ← 유리 테두리
│  │  ┌─────────────────────────────┐││
│  │  │  3. Inner Highlight (0.5px) │││  ← 상단 빛 반사
│  │  │  ┌─────────────────────────┐│││
│  │  │  │  2. Tint Gradient       ││││  ← 유리 굴절 (상 밝 / 하 어둡)
│  │  │  │  ┌─────────────────────┐│││││
│  │  │  │  │  1. Backdrop Blur   ││││││  ← 배경 흐림 (sigma 18)
│  │  │  │  └─────────────────────┘│││││
│  │  │  └─────────────────────────┘││││
│  │  └─────────────────────────────┘│││
│  └─────────────────────────────────┘││
└─────────────────────────────────────┘│
```

## 레이어별 스펙

### Layer 1: Backdrop Blur

| 속성 | 라이트 | 다크 |
|------|--------|------|
| sigmaX/Y | 18.0 | 18.0 |

### Layer 2: Tint Gradient (유리 굴절)

단색이 아닌 **세로 그라디언트**로 빛이 위에서 내려오는 유리판 효과.

| 속성 | 라이트 | 다크 |
|------|--------|------|
| 상단 색상 | `Colors.white` alpha 0.25 | `Colors.white` alpha 0.12 |
| 하단 색상 | `Colors.white` alpha 0.10 | `Colors.white` alpha 0.05 |

### Layer 3: Inner Highlight (빛 반사)

유리 상단에 빛이 반사되는 0.5px 라인. "평면 박스"와 "유리"의 결정적 차이.

| 속성 | 라이트 | 다크 |
|------|--------|------|
| 색상 | `Colors.white` alpha 0.8 | `#C8A96E` (금빛) alpha 0.4 |
| 두께 | 0.5px | 0.5px |

### Layer 4: Border (유리 테두리)

| 속성 | 라이트 | 다크 |
|------|--------|------|
| 색상 | `Colors.white` alpha 0.7 | `#C8A96E` alpha 0.25 |
| 두께 | 0.5px | 0.5px |

### Layer 5: Shadow (깊이감)

| 속성 | 라이트 | 다크 |
|------|--------|------|
| 색상 | `Colors.black` alpha 0.06 | `Colors.black` alpha 0.30 |
| blurRadius | 16.0 | 20.0 |
| offset | (0, 4) | (0, 6) |

## 형태 치수

| 속성 | 값 |
|------|-----|
| 높이 | 64px |
| 좌우 마진 | 16px |
| 하단 마진 | safeArea.bottom + 8px |
| 모서리 | borderRadius 24px (전방향) |

## 위젯 트리

```dart
Scaffold(extendBody: true)
  body: navigationShell
  bottomNavigationBar: SizedBox
    └─ Padding (좌16 우16 하safeArea+8)
       └─ DecoratedBox (shadow)
          └─ ClipRRect (borderRadius: 24)
             └─ BackdropFilter (blur sigma 18)
                └─ Container (tint gradient + border)
                   └─ Stack
                      ├─ Positioned (inner highlight 0.5px)
                      └─ Row (_NavItem × 4)
```

## BackdropFilter 동작 조건 (핵심!)

BackdropFilter가 실제로 블러를 렌더링하려면 다음 조건이 **모두** 충족되어야 한다:

### 1. `Scaffold.extendBody: true` 필수
body 콘텐츠가 bottomNavigationBar 영역 뒤로 확장되어야 블러할 대상이 존재함.

### 2. 내부 페이지 Scaffold 배경 투명
각 탭 페이지의 `Scaffold(backgroundColor: Colors.transparent)` 필수.
불투명 배경이면 BackdropFilter가 같은 색만 블러해서 효과 안 보임.

```dart
// 홈, 매칭, 채팅, 프로필 모든 탭 페이지
Scaffold(
  backgroundColor: Colors.transparent,  // 필수!
  body: SafeArea(bottom: false, ...),   // bottom: false도 필수!
)
```

### 3. 각 페이지 스크롤뷰 하단 패딩
콘텐츠 마지막이 네비바에 가리지 않도록:
```dart
SizedBox(height: MediaQuery.of(context).padding.bottom + 88)
```

### 4. `bottomNavigationBar`에 배치 (Stack 아님!)
`Stack > Positioned`로 오버레이하면 `RepaintBoundary` 때문에 BackdropFilter가 body 픽셀을 못 봄.
반드시 `Scaffold.bottomNavigationBar`에 배치해야 Flutter가 올바른 컴포지팅 레이어를 생성함.

### 5. `ImageFilter.compose` + `ColorFilter` 주의
Impeller 렌더러에서 `ImageFilter.compose(outer: ColorFilter.matrix(...), inner: ImageFilter.blur(...))`가
조용히 무시될 수 있음 (채도 부스트 적용 안 됨). 블러만 단독 사용이 안전.

## 터치 인터랙션

`_NavItem`은 `StatefulWidget`으로, 탭 시 **바운스 애니메이션** 적용:

- **누를 때**: scale 0.85, 100ms, easeInOut
- **복귀**: scale 1.0, 350ms, elasticOut (튀는 바운스)
- **햅틱**: `HapticFeedback.selectionClick()` (기존 유지)
- **아이콘 전환**: `AnimatedSwitcher` 150ms crossfade (기존 유지)

## 삽질 기록 (Lessons Learned)

| 시도 | 결과 | 원인 |
|------|------|------|
| `Scaffold.bottomNavigationBar` + alpha 0.82 | 불투명, 블러 안 보임 | alpha 너무 높음 + 내부 Scaffold 배경 불투명 |
| `Stack > Positioned > BackdropFilter` | 블러 완전 미작동 | RepaintBoundary가 body 픽셀 차단 |
| `Material > Stack` (Scaffold 제거) | 블러 미작동 | 동일 RepaintBoundary 이슈 |
| `ImageFilter.compose(ColorFilter + blur)` | 아무 변화 없음 | Impeller에서 ColorFilter 합성 무시 |
| `bottomNavigationBar` + 투명 내부 Scaffold | 블러 동작! | Flutter 공식 컴포지팅 경로 사용 |

**핵심 교훈**: Flutter의 `BackdropFilter`는 반드시 `Scaffold.bottomNavigationBar` (또는 `appBar`) 슬롯에 배치해야 `extendBody`와 함께 정상 동작한다. 임의의 Stack 오버레이에서는 RepaintBoundary 때문에 작동하지 않는다.

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `lib/app/routes/app_router.dart` | 5레이어 글래시 네비바 + _NavItem 바운스 |
| `lib/features/home/presentation/pages/home_page.dart` | Scaffold transparent + SafeArea bottom:false + 하단 패딩 |
| `lib/features/matching/presentation/pages/matching_page.dart` | 동일 + GridView 하단 패딩 + 필터 라벨 변경 |
| `lib/features/chat/presentation/pages/chat_list_page.dart` | Scaffold transparent + ListView 하단 패딩 |
| `lib/features/profile/presentation/pages/profile_page.dart` | Scaffold transparent + SafeArea bottom:false + 하단 패딩 |
