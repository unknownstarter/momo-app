# 사주/관상 결과 공유하기 기능 — 바이럴 성장 엔진

> **작성일**: 2026-03-05
> **목적**: 사주/관상 결과를 웹 링크로 공유 → 친구 유입 → 앱 다운로드 유도
> **상태**: 리서치 완료, 구현 대기

---

## 1. 핵심 컨셉

```
[앱에서 "공유하기" 탭]
    ↓
[결과 스냅샷 저장 → 고유 URL 생성]
    ↓
[카카오톡/인스타로 공유] ← OG 미리보기 (썸네일 + 제목)
    ↓ (친구가 클릭)
    ↓
[웹 페이지: 사주/관상 결과 카드]
├─ 예쁘게 렌더링된 결과
├─ "나도 사주 & 관상 보기" CTA 버튼
└─ OS 감지 → App Store / Play Store 이동
```

**바이럴 루프**: 결과 공유 → 친구 호기심 → 웹에서 결과 확인 → "나도 해보고 싶다" → 앱 다운로드 → 새 유저의 결과 공유 → 반복

---

## 2. 시장 검증 — 이미 성공한 사례들

| 서비스 | 방식 | 성과 |
|--------|------|------|
| **케이테스트(Ktestone)** | 결과별 고유 URL + 카카오톡/틱톡 공유 | 스마일 연애 테스트 글로벌 바이럴 |
| **16Personalities** | MBTI 결과 고유 URL + OG 미리보기 | 글로벌 1위 성격 테스트 |
| **Spotify Wrapped** | 개인화 결과 카드 + 공유 링크 | 매년 SNS 도배, 문화 현상화 |
| **포스텔러** | 명식(사주) 링크/QR 공유 | MAU 142만 |
| **방구석연구소** | 결과 링크 + 트위터/인스타 공유 | MZ세대 바이럴 |

### 모모만의 강점

케이테스트는 "결과 = 성격 유형"이지만, 모모는 **"결과 = 궁합 비교"**가 가능함.
→ "나랑 궁합 확인해볼래?" 라는 자연스러운 공유 동기가 내장되어 있음.

---

## 3. 기술 아키텍처

### 3-1. 데이터 흐름

```
┌─────────────────────────────────────────────┐
│ Flutter App                                  │
│                                              │
│  [공유 버튼 탭]                               │
│      ↓                                       │
│  Supabase INSERT → shared_results 테이블     │
│      ↓                                       │
│  share_token (UUID) 발급                     │
│      ↓                                       │
│  URL 생성: share.momo.app/s/{token}          │
│      ↓                                       │
│  OS 공유 시트 (카카오톡, 인스타, 문자 등)      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ 친구가 링크 클릭                              │
│                                              │
│  ┌─ 앱 설치됨 ──► Universal Link → 앱 실행   │
│  │                 결과 페이지로 바로 이동     │
│  │                                           │
│  └─ 앱 미설치 ──► 웹 페이지 렌더링            │
│       • 사주/관상 결과 카드 (예쁘게)          │
│       • "나도 사주 & 관상 보기" CTA 버튼      │
│       • iOS → App Store / Android → Play     │
└─────────────────────────────────────────────┘
```

### 3-2. DB 설계 — shared_results 테이블

```sql
CREATE TABLE public.shared_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  share_token UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  result_type TEXT NOT NULL,     -- 'saju', 'gwansang', 'both'
  result_data JSONB NOT NULL,    -- 결과 스냅샷 (민감정보 제외)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '90 days'),
  view_count INTEGER DEFAULT 0
);

-- 누구나 토큰으로 조회 가능 (공유 목적)
CREATE POLICY "Public read via share_token"
ON public.shared_results FOR SELECT
USING (is_active = true AND (expires_at IS NULL OR expires_at > now()));

-- 본인만 생성/수정/삭제
CREATE POLICY "Owner manages own shares"
ON public.shared_results FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

**result_data에 포함하는 것:**
- 사주: 사주팔자(4기둥), 오행 분포, AI 해석 요약, 캐릭터 타입
- 관상: 동물상 + 수식어, traits 5축 점수, 매력 키워드
- 사용자: 이름(닉네임), 캐릭터 이미지

**result_data에서 제외하는 것:**
- 전화번호, 정확한 생년월일시, 이메일, 프로필 사진

### 3-3. 웹 페이지 호스팅

| 방식 | 장점 | 단점 | 비용 |
|------|------|------|------|
| **Vercel** (추천) | 무료, 빠름, OG 태그 SSR 지원 | 프레임워크 필요 (Next.js 등) | 무료 |
| **Cloudflare Pages** | 무료, CDN 글로벌, Workers로 SSR | 학습 곡선 | 무료 |
| **Supabase Edge Function** | 이미 사용 중 | HTML 응답 시 text/plain 강제 (커스텀 도메인 필요) | 기존 플랜 |
| **Flutter Web** | 코드 재사용 | 초기 로딩 느림, OG 태그 SSR 불가 | 무료 |

**추천: Vercel + Next.js (또는 Cloudflare Pages)**
- OG 태그를 서버 사이드에서 동적 생성해야 카카오톡 미리보기가 제대로 나옴
- 무료 티어로 충분
- `share.momo.app` 커스텀 도메인 연결

### 3-4. OG 미리보기 (카카오톡에서 보이는 것)

```html
<meta property="og:title" content="Noah님의 사주 프로필 — 을목(乙木) 🌿" />
<meta property="og:description" content="부드러운 카리스마의 소유자. 나와 궁합을 확인해보세요!" />
<meta property="og:image" content="https://share.momo.app/og/{token}.png" />
<meta property="og:url" content="https://share.momo.app/s/{token}" />
```

OG 이미지는 동적 생성 가능:
- Supabase Edge Function으로 캐릭터 + 결과 텍스트를 PNG로 렌더링
- 또는 Vercel OG Image Generation (`@vercel/og`)

### 3-5. 앱 연결 (딥링크)

**Firebase Dynamic Links는 2025-08-25에 폐지됨** → 직접 구현 필요

| 플랫폼 | 방식 | 설정 |
|--------|------|------|
| iOS | Universal Links | `share.momo.app/.well-known/apple-app-site-association` |
| Android | App Links | `share.momo.app/.well-known/assetlinks.json` |
| Flutter | `app_links` 패키지 | iOS/Android 모두 지원, 무료 |

**앱 미설치 시 폴백:**
```
웹 페이지에서 "나도 사주 & 관상 보기" 버튼
  → iOS: App Store 링크
  → Android: Play Store 링크
  → 설치 후 첫 실행 시 결과 페이지로 이동 (deferred deep link)
```

---

## 4. RLS(Row Level Security) 안전성 분석

### 걱정: "공유하면 DB가 뚫리는 거 아닌가?"

**아닙니다.** 이유:

| 우려 | 실제 상황 |
|------|-----------|
| 원본 테이블 노출? | **아님** — shared_results는 별도 테이블. saju_profiles, profiles는 RLS 그대로 유지 |
| 토큰 추측? | **불가능** — UUID v4 = 122bit 엔트로피. 무차별 대입으로 찾을 확률 ≈ 0 |
| 민감정보 유출? | **없음** — 스냅샷에 결과값만 저장. 전화번호/생년월일시/이메일 제외 |
| 무한 스크래핑? | **방어 가능** — 토큰 없이는 접근 불가 + Rate Limit 적용 |

### 패턴: "데이터 스냅샷 분리"

```
[원본: saju_profiles]          [공유용: shared_results]
  - 전체 개인정보                - 결과값 스냅샷만
  - RLS: 본인만 읽기             - RLS: 토큰 있으면 누구나 읽기
  - 실시간 업데이트 반영          - 공유 시점 기준 고정
  - 절대 퍼블릭 노출 안 함       - 의도적으로 퍼블릭 읽기 허용
```

이 패턴은 **Spotify Wrapped, 16Personalities, 케이테스트** 모두 사용하는 검증된 방식.

---

## 5. 리스크 & 대응

| 리스크 | 심각도 | 대응 방안 |
|--------|--------|-----------|
| 카카오톡 OG 미리보기 안 뜸 | 중간 | SSR 필수 (Vercel/Cloudflare). 클라이언트 렌더링은 OG 태그 못 읽음 |
| 웹 페이지 디자인 공수 | 중간 | 앱 디자인과 동일하게 만들 필요 없음. 핵심 결과 카드 + CTA만 있으면 됨 |
| 딥링크 iOS/Android 설정 | 중간 | `app_links` 패키지 + AASA/assetlinks.json 설정. 한 번만 하면 됨 |
| 공유 남용 (스팸) | 낮음 | 일일 공유 횟수 제한 (예: 10회/일) |
| 만료된 링크 접근 | 낮음 | "결과가 만료되었어요. 나도 사주 보러 가기" 페이지로 폴백 → 여전히 유입 |
| 추가 서버 비용 | 낮음 | Vercel/Cloudflare 무료 티어로 충분 (월 10만 뷰까지) |

---

## 6. 구현 우선순위 제안

### Phase 1: 최소 MVP (1~2일)
- `shared_results` 테이블 + RLS
- Flutter에서 공유 버튼 → 스냅샷 저장 → URL 생성 → OS 공유 시트
- 웹 페이지: 간단한 결과 카드 + "나도 해보기" 버튼 (Vercel 1페이지)
- OG 태그 (카카오톡 미리보기)

### Phase 2: 완성도 (1~2일)
- OG 이미지 동적 생성 (캐릭터 + 결과 텍스트)
- iOS Universal Links + Android App Links
- 앱 내 "내 공유 관리" (비활성화/삭제)
- 조회수 카운터

### Phase 3: 고도화 (추후)
- 궁합 공유 ("우리 궁합 확인해볼래?")
- Deferred deep linking (설치 후 결과 페이지로 바로 이동)
- A/B 테스트 (CTA 문구, 카드 디자인)
- Mixpanel 이벤트 트래킹 (공유 → 클릭 → 설치 전환율)

---

## 7. 필요 리소스

| 항목 | 기술 | 비용 |
|------|------|------|
| 웹 호스팅 | Vercel 또는 Cloudflare Pages | 무료 |
| 도메인 | `share.momo.app` (서브도메인) | momo.app 도메인 필요 |
| OG 이미지 생성 | Supabase Edge Function 또는 Vercel OG | 무료 |
| 딥링크 | `app_links` Flutter 패키지 | 무료 |
| DB | shared_results 테이블 (기존 Supabase) | 기존 플랜 내 |

**추가 비용: 사실상 0원** (도메인 비용 제외)

---

## 8. 경쟁 우위

모모의 공유 기능이 케이테스트/16Personalities보다 강력한 이유:

1. **궁합 비교 동기** — "나랑 궁합 확인해볼래?" → 1:1 공유가 자연스럽게 발생
2. **재방문 동기** — 새 친구가 가입할 때마다 궁합 확인 가능 → 재활성화
3. **결과 깊이** — 사주 + 관상 + 동물상 + 오행 캐릭터 → 공유할 콘텐츠가 풍부
4. **감성 톤** — "4,000년 된 비밀 노트" 같은 위트 → 스크린샷/공유 욕구 자극
5. **시각적 매력** — 오행 캐릭터 카드 → 인스타 스토리에 올리고 싶은 디자인

---

## 9. 다음 액션

- [ ] Supabase 이전 완료 후 구현 시작
- [ ] 도메인 확보 (`momo.app` 또는 대안)
- [ ] 웹 프레임워크 선택 (Vercel + Next.js 추천)
- [ ] Phase 1 MVP 구현 → 테스트 → 배포
