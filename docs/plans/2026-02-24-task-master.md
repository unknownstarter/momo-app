# 테스크 마스터 — 2026-02-24

> **작성일**: 2026-02-24  
> **목적**: 다음에 할 일을 한곳에 정리해, 다른 디바이스에서 보고 연속으로 작업할 수 있게 함.  
> **참조**: PRD `docs/plans/2026-02-24-app-design.md`, 개선 제안서 `docs/plans/2026-02-24-saju-궁합-engine-improvement-proposal.md`, dev-log `docs/dev-log/2026-02-24-progress.md`

---

## 1. 오늘(2026-02-24) 완료된 것

| # | 항목 | 상태 |
|---|------|------|
| 1 | 사주 엔진 만세력 기준 전환 (`calculate-saju` → @fullstackfamily/manseryeok, KASI) | ✅ |
| 2 | 실궁합 Edge Function `calculate-compatibility` 구현 (오행+일주 기반) | ✅ |
| 3 | RLS `saju_select_recommended` 추가, Saju `getSajuForCompatibility` | ✅ |
| 4 | MatchingRepositoryImpl 연동, DI 전환 (궁합만 실연동, 추천/좋아요 Mock 유지) | ✅ |
| 5 | Phase 1 스펙·dev-log·문서 반영 | ✅ |

---

## 2. 다음에 할 일 (우선순위순)

### 즉시 (High) — 매칭·궁합 실데이터 연동

| # | Task | 담당 관점 | 산출물/참고 | 상태 |
|---|------|-----------|-------------|------|
| 1 | **daily_matches 실데이터** | Backend + Data | cron 또는 API로 오늘의 추천 생성, `getDailyRecommendations` Mock 제거 후 Supabase 연동 | ⬜ |
| 2 | **프로필·사주 저장 연동** | Backend + Flutter | 온보딩/사주 분석 완료 시 `saju_profiles` 저장, `profiles.saju_profile_id` 갱신 | ✅ |
| 3 | **궁합 프리뷰 실사용 검증** | QA | 실제 유저 2명 사주 저장 후 궁합 프리뷰 호출 → 점수·강점/도전 문구 확인 | ⬜ |

### 단기 (Medium) — 궁합·매칭 고도화 (Phase 2)

| # | Task | 담당 관점 | 산출물/참고 | 상태 |
|---|------|-----------|-------------|------|
| 4 | **데이팅용 궁합 규칙집 + 상세 리포트** | PM + 도메인 전문가 + Backend | 전문가 검수 규칙 문서화, 상세 궁합(500P)에 반영 | ⬜ |
| 5 | **십신 기반 커플 궁합 보강** | Backend + 도메인 | 일간 대 일간 십신 관계 테이블, 스토리 문구 추가 | ⬜ |
| 6 | **받은 좋아요 목록 페이지** | Flutter | 현재 카드만 있음 → 상세 페이지/수락·거절 플로우 | ⬜ |
| 7 | **프로필 편집 페이지** | Flutter | 온보딩 후 프로필 수정 UI | ⬜ |

### 중기 (Phase 7·8)

| # | Task | 담당 관점 | 산출물/참고 | 상태 |
|---|------|-----------|-------------|------|
| 8 | **Phase 7: Chat** | Backend + Flutter | Supabase Realtime 1:1 채팅, 매칭 성사 시 채팅방 생성, 사주 아이스브레이커 | ⬜ |
| 9 | **Phase 8: Payment** | Backend + Flutter | RevenueCat 인앱 결제, 구독·포인트·상세 궁합 유료 | ⬜ |
| 10 | **Supabase 실연동 전반** | Backend | Auth(Apple/Google/Kakao), Mock Repository → Real 전환 | ⬜ |

### 장기 (Phase 3·그 외)

| # | Task | 담당 관점 | 산출물/참고 | 상태 |
|---|------|-----------|-------------|------|
| 11 | **궁합 가중치 A/B 테스트** | Data + Backend | 오행/일주/십신 비율 파라미터화, 실험 플래그·가중치 저장소 | ⬜ |
| 12 | **푸시 알림** | Backend + Flutter | 새 매칭, 좋아요, 채팅 알림 | ⬜ |
| 13 | **바이럴·분석** | Growth | 사주 카드 SNS 공유, Mixpanel A/B 인프라 | ⬜ |

---

## 3. 참조 문서 (다른 디바이스에서 연속 작업 시 먼저 볼 것)

| 문서 | 용도 |
|------|------|
| **본 파일** `docs/plans/2026-02-24-task-master.md` | 다음 할 일·우선순위·담당 관점 |
| `docs/dev-log/2026-02-24-progress.md` | 오늘 완료 내역, 아키텍처 현황, 레슨런 |
| `docs/plans/2026-02-24-app-design.md` | PRD·MVP 플로우·화면 설계 |
| `docs/plans/2026-02-24-saju-궁합-engine-improvement-proposal.md` | 궁합 엔진 Phase 2/3 로드맵 |
| `docs/plans/2026-02-24-phase1-calculate-compatibility-spec.md` | 궁합 API 스펙·배점·규칙집 |
| `CLAUDE.md` | 개발자룰·아키텍처·에셋·라우팅 규칙 |

---

## 4. 연속 작업 시 체크리스트

- [ ] 위 "다음에 할 일"에서 한 개 이상 Task 선택
- [ ] 참조 문서에서 해당 Task 관련 스펙·의존성 확인
- [ ] `lib/core/di/providers.dart` 확인 (새 Repository/DataSource 추가 시 반드시 등록)
- [ ] 작업 완료 시 본 테스크 마스터 상태(⬜→✅) 및 dev-log 업데이트
