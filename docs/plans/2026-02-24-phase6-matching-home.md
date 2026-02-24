# Phase 6: 홈 + 매칭 + 궁합 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 홈 화면(캐릭터 인사 + 추천 매칭), 매칭 카드 UI, 궁합 프리뷰, 좋아요/수락 플로우, 포인트 시스템을 구현한다.

**Architecture:** Supabase 미연결 상태에서도 동작하도록 Mock 데이터를 제공하는 Repository 패턴. 나중에 Supabase 연결 시 구현체만 교체하면 된다. 홈은 캐주얼 모드(라이트), 궁합 상세는 신비 모드(다크).

**Tech Stack:** Flutter 3.38+, Riverpod 2.x, go_router, 한지 디자인 시스템

**Existing Entities (already created):**
- `lib/features/matching/domain/entities/like_entity.dart`: Like, LikeStatus
- `lib/features/matching/domain/entities/match_entity.dart`: Match
- `lib/features/points/domain/entities/point_entity.dart`: UserPoints, PointTransaction, DailyUsage
- `lib/features/saju/domain/entities/saju_entity.dart`: SajuProfile, FiveElements, Compatibility, CompatibilityGrade
- `lib/core/constants/app_constants.dart`: AppLimits (dailyFreeLikeLimit=3, likeCost=100, etc.)

---

## Task 25: SajuMatchCard 위젯 + CompatibilityGauge 위젯

**개요:** 매칭 추천 카드(사진+캐릭터+궁합점수)와 원형 궁합 게이지 위젯을 구현한다.

**Files:**
- Create: `lib/core/widgets/saju_match_card.dart`
- Create: `lib/core/widgets/compatibility_gauge.dart`
- Modify: `lib/core/widgets/widgets.dart` — barrel export 추가

**SajuMatchCard 스펙:**
- 사진 영역 (상단 2/3), 정보 영역 (하단 1/3)
- 사진 위 좌상단: 상대 오행 캐릭터 아이콘 (32px 원)
- 사진 위 우상단: 궁합 점수 뱃지 (SajuBadge)
- 하단: 이름 + 나이 + 한줄소개
- 하단 태그: 오행 칩 (SajuChip)
- 프리미엄 좋아요 표시: 골드 테두리 + ✨
- onTap → 궁합 프리뷰로 이동

**CompatibilityGauge 스펙:**
- 원형 프로그레스 인디케이터 (0~100)
- 중앙에 점수 숫자 (큰 글씨)
- 하단에 등급 텍스트 (CompatibilityGrade.label)
- 등급별 색상 (AppTheme.compatibilityExcellent/Good/Normal/Low)
- 진입 애니메이션 (0→score, 1초)

---

## Task 26: 매칭 Data Layer + Providers

**개요:** 매칭/궁합/포인트/좋아요의 Repository 인터페이스 + Mock 구현체 + Riverpod Providers.

**Files:**
- Create: `lib/features/matching/domain/repositories/matching_repository.dart`
- Create: `lib/features/matching/data/repositories/matching_repository_impl.dart`
- Create: `lib/features/matching/data/models/match_profile_model.dart`
- Create: `lib/features/matching/presentation/providers/matching_provider.dart`
- Create: `lib/features/matching/presentation/providers/matching_provider.g.dart`

**MatchingRepository 인터페이스:**
- `Future<List<MatchProfile>> getDailyRecommendations()` — 오늘의 추천 리스트
- `Future<Compatibility> getCompatibilityPreview(String partnerId)` — 궁합 프리뷰
- `Future<void> sendLike(String receiverId, {bool isPremium = false})` — 좋아요
- `Future<void> acceptLike(String likeId)` — 수락
- `Future<List<Like>> getReceivedLikes()` — 받은 좋아요 리스트

**MatchProfile 모델:** 추천 카드에 필요한 데이터 묶음
- userId, name, age, bio, photoUrl, characterName, characterAsset, elementType, compatibilityScore

**Mock 구현:** 5명의 가상 프로필 + 궁합 점수 하드코딩. Supabase 연결 전까지 사용.

---

## Task 27: 홈 화면 (HomePage)

**개요:** 앱의 메인 화면. 캐릭터 인사 + 추천 매칭 카드 + 받은 좋아요 + 오늘의 한마디.

**Files:**
- Create: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/app/routes/app_router.dart` — home placeholder 교체

**레이아웃 (스크롤 가능):**
1. 캐릭터 인사 섹션: SajuCharacterBubble (내 캐릭터 + "안녕, [이름]님! 오늘의 운명적 인연을 찾아봐~")
2. 오늘의 추천 매칭 섹션: 가로 스크롤 SajuMatchCard 리스트 (3~5장)
3. 나를 좋아한 사람 섹션: 블러 처리된 캐릭터 아이콘 + 수 표시 (SajuCard)
4. 오늘의 사주 한마디 섹션: SajuCharacterBubble (일일 포춘)
- 라이트 모드 (캐주얼), 한지 배경

---

## Task 28: 매칭 탭 + 궁합 프리뷰 페이지

**개요:** 매칭 탭(추천 프로필 그리드 + 좋아요 보내기)과 궁합 프리뷰 바텀시트.

**Files:**
- Create: `lib/features/matching/presentation/pages/matching_page.dart`
- Create: `lib/features/matching/presentation/pages/compatibility_preview_page.dart`
- Modify: `lib/app/routes/app_router.dart` — matching placeholder 교체

**MatchingPage:**
- 상단: 필터 칩 (전체/목/화/토/금/수) — SajuChip 사용
- 중앙: 프로필 카드 그리드 (2열) — SajuMatchCard
- 하단: 무료 좋아요 잔여 표시 ("오늘 2/3회 남음")
- 카드 탭 → CompatibilityPreviewPage (바텀시트)

**CompatibilityPreviewPage (모달 바텀시트):**
- 상단: 두 캐릭터 나란히 (내 캐릭터 + 상대 캐릭터)
- 중앙: CompatibilityGauge (궁합 점수 + 등급)
- 강점 3개 + 도전 3개 (리스트)
- 하단: "좋아요 보내기" 버튼 (무료 잔여 or 포인트 표시)
- 상세 궁합 리포트 → "500P로 상세 보기" (유료)

---

## Task 29: 좋아요/포인트 Providers + 매칭 탭 연결

**개요:** 좋아요 전송/수락 상태, 포인트 잔액, 일일 사용량 추적 Providers.

**Files:**
- Create: `lib/features/points/presentation/providers/points_provider.dart`
- Create: `lib/features/points/presentation/providers/points_provider.g.dart`
- Modify: matching_provider에 좋아요 액션 연동

**PointsProvider:**
- `userPointsProvider`: 현재 포인트 잔액 (Mock: 500P)
- `dailyUsageProvider`: 오늘 무료 사용량
- `sendLikeProvider`: 좋아요 전송 로직 (무료 체크 → 포인트 차감)

---

## Summary

| Task | 내용 | 산출물 |
|------|------|--------|
| 25 | SajuMatchCard + CompatibilityGauge | `core/widgets/` 2개 위젯 |
| 26 | Matching data layer + providers | `features/matching/` data+providers |
| 27 | 홈 화면 | `features/home/presentation/pages/home_page.dart` |
| 28 | 매칭 탭 + 궁합 프리뷰 | `features/matching/presentation/pages/` 2개 |
| 29 | 포인트/좋아요 providers | `features/points/presentation/providers/` |
