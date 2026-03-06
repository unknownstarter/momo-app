# Matching Recommendation & Monetization Design

> **작성일**: 2026-03-06
> **상태**: 승인됨 (노아님 확인)
> **모델**: Model B "소개팅형" — 넓은 퍼널 + 사진 게이팅

---

## 1. 핵심 원칙

### 욕망 퍼널 (Desire Funnel)
```
궁합 점수 + 정보 (흥미) → 사진 (매력) → 좋아요 (호감) → 채팅 (만남) → 실제 만남
```

- **궁합 점수와 프로필 정보는 무료** — 흥미를 최대한 키움
- **사진이 핵심 과금 포인트** — "궁합 92점인데 어떻게 생겼지?"
- 사진 블러(sigma 25) + 캐릭터(80px) 오버레이로 호기심 유발

### 경쟁사 벤치마크
| 앱 | 추천 | 과금 포인트 | 매출 |
|----|------|------------|------|
| 위피 | 4명/일 무료 | 프로필 열람 자체 | 1위 |
| 글램 | 무제한 | 좋아요/프리미엄 좋아요 | 중위권 |
| 스카이피플 | 10장 무료/12h | 프로필 열기 | 상위권 |
| **Momo** | **20~30명/일** | **사진 열람** | - |

### Momo 차별점
- 추천 기준이 **궁합 점수** (운명적 내러티브)
- 궁합 카드를 넉넉히 보여줘 "아까운 사람"을 쌓는 구조
- 캐릭터 모드 → 사진 열람이 자연스러운 전환

---

## 2. 궁합 계산 비용 구조

### calculate-compatibility Edge Function
- **순수 수학 공식** (Claude API 호출 없음, 비용 $0)
- 천간합(+10), 지지육합(+8), 삼합(+6), 충(-5), 형(-3), 오행상생/상극
- 배점: 일주(40pt) + 오행(35pt) + 기타 기둥(20pt) + 기본(5pt)
- **사주 불변성**: 생년월일시 변경 없음 → 궁합 점수 영구 캐시 가능

### 비용 최적화
- 신규 유저 가입 시 기존 전체 유저와 궁합 배치 계산 (서버리스, 비동기)
- 결과를 `compatibility_scores` 테이블에 캐시
- 홈 추천 시 캐시된 점수에서 조회만 → DB 쿼리 비용만

---

## 3. 최초 궁합 매칭 (온보딩 직후)

### 플로우
```
온보딩 완료 → 사주&관상 분석 → 추가 정보 입력
  → 로딩 연출 ("운명의 인연을 찾고 있어요...")
  → "당신의 운명적 인연을 찾았어요!"
  → 최대 5명 표시 (궁합 점수 높은 순)
```

### 설계
- 궁합 점수 상위 5명을 선별
- 특별한 첫 만남 UI 연출 (카드 한 장씩 공개 등)
- 이 5명에 대해서는 **사진 열람 1회 무료 제공** (첫 경험 최적화)
- CTA: "더 많은 인연 만나기" → 홈 화면으로

---

## 4. 일일 홈 추천 구조

### 섹션 구성
| 섹션 | 최대 인원 | 추천 기준 | 비고 |
|------|----------|----------|------|
| 오늘의 운명 매칭 | 3~5명 | 궁합 85%+ | 프리미엄 느낌 |
| 궁합이 좋은 인연들 | 10~15명 | 궁합 점수 높은 순 | 2열 그리드 |
| 관상으로 통하는 인연 | 5~8명 | 동물상/traits 유사도 | 관상 데이터 기반 |
| 새로 가입한 인연 | 5~10명 | 가입일 최신순 | 신규 유저 노출 |

### 규칙
- **총 합산 최대 ~30명/일**
- **추천 대상 0명인 섹션 → 섹션 자체 숨김**
- 매일 자정 리셋 (또는 정오 리셋 — A/B 테스트)
- 이미 좋아요/패스한 유저는 재노출 안 함

### 카드 표시 정보 (무료)
```
┌──────────────────────┐
│  [캐릭터 오버레이]      │  ← 사진 블러 + 오행 캐릭터
│                        │
│  궁합 92%              │  ← 궁합 점수 (무료)
│  나른한 고양이상         │  ← 동물상 (무료)
│  27세 · 강남구          │  ← 나이/지역 (무료)
│  ENFP · 디자이너        │  ← 성격/직업 (무료)
│                        │
│  [사진 보기 🔒]         │  ← 유료 (3회/일 무료)
└──────────────────────┘
```

---

## 5. 과금 구조

### 일일 무료 한도 + 포인트 과금
| 액션 | 무료 한도 | 추가 과금 | 예상 단가 |
|------|----------|----------|----------|
| 궁합 카드 열람 | **전체 무료** | - | - |
| 사진 열람 (블러 해제) | 3회/일 | 30pt/회 | ~300원 |
| 좋아요 보내기 | 3회/일 | 50pt/회 | ~500원 |
| 프리미엄 좋아요 (상위 노출) | 0회 | 100pt/회 | ~1,000원 |

### 포인트 패키지 (예시)
| 패키지 | 포인트 | 가격 | 단가 |
|--------|--------|------|------|
| 소량 | 100pt | 1,200원 | 12원/pt |
| 기본 | 300pt | 3,300원 | 11원/pt |
| 인기 | 500pt | 4,900원 | 9.8원/pt |
| 대량 | 1,000pt | 8,900원 | 8.9원/pt |

### 구독 (추후)
| 플랜 | 가격 | 혜택 |
|------|------|------|
| 프리미엄 | 월 14,900원 | 사진 열람 무제한 + 좋아요 10회/일 |
| VIP | 월 29,900원 | 전체 무제한 + 프리미엄 좋아요 5회/일 + 프로필 상위 노출 |

---

## 6. 전환 심리 설계

### 사진 열람 전환 트리거
```
유저가 궁합 카드 스크롤 (무료)
  → 궁합 높은 프로필 발견 "92점?"
  → 정보 확인 (나이, 지역, 성격... 다 괜찮네)
  → "어떻게 생겼지?" → 사진 열람 클릭
  → 무료 3회 빠르게 소진
  → 4번째부터 "30포인트로 확인하기"
  → 💰
```

### 핵심 심리 원리
| 원리 | 적용 |
|------|------|
| Zeigarnik Effect | 궁합 점수를 봤으니 사진도 봐야 완결 |
| FOMO | "궁합 95점인데 안 보면 후회할 것 같아" |
| 매몰비용 | "이미 3명 봤는데, 1명 더..." |
| 비교 욕구 | 여러 궁합 점수 비교 → "제일 높은 사람은?" |
| 불확실성-매력 | 캐릭터만 보이니 상상력 자극 |

---

## 7. 데이터 모델 (신규 테이블)

### compatibility_scores
```sql
CREATE TABLE compatibility_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  target_user_id UUID REFERENCES profiles(id),
  total_score INTEGER NOT NULL,        -- 0~100
  day_pillar_score INTEGER,
  five_elements_score INTEGER,
  other_pillars_score INTEGER,
  details JSONB,                       -- 상세 궁합 데이터
  calculated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, target_user_id)
);
```

### daily_recommendations
```sql
CREATE TABLE daily_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  recommended_user_id UUID REFERENCES profiles(id),
  section TEXT NOT NULL,               -- 'destiny', 'compatibility', 'gwansang', 'new'
  score INTEGER,
  date DATE DEFAULT CURRENT_DATE,
  viewed BOOLEAN DEFAULT false,
  photo_revealed BOOLEAN DEFAULT false,
  UNIQUE(user_id, recommended_user_id, date)
);
```

### user_actions
```sql
CREATE TABLE user_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  target_user_id UUID REFERENCES profiles(id),
  action_type TEXT NOT NULL,           -- 'photo_reveal', 'like', 'premium_like', 'pass'
  points_spent INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### user_points
```sql
CREATE TABLE user_points (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  balance INTEGER DEFAULT 0,
  total_earned INTEGER DEFAULT 0,
  total_spent INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 8. 배치 처리 설계

### 궁합 점수 사전 계산
```
신규 유저 가입 (사주 분석 완료)
  → 배치 트리거: 기존 이성 유저 전체와 궁합 계산
  → compatibility_scores 테이블에 INSERT
  → 순수 수학 (Claude API 없음, 비용 $0)
```

### 일일 추천 생성
```
매일 자정 (또는 유저 홈 접속 시 lazy)
  → compatibility_scores에서 상위 N명 추출
  → 섹션별 분배 (운명/궁합/관상/신규)
  → daily_recommendations에 INSERT
```

### 스케일링
| 유저 수 | 궁합 계산 수 | 소요 시간 (예상) |
|---------|-------------|----------------|
| 100명 | ~5,000건 | < 1분 |
| 1,000명 | ~500,000건 | < 10분 |
| 10,000명 | ~50,000,000건 | 배치 최적화 필요 |

> 10,000명 이상 시: 나이/지역 필터 선적용 → 후보군 축소 → 궁합 계산

---

## 9. 구현 우선순위

### Phase 1 (MVP)
1. `compatibility_scores` 테이블 + 궁합 배치 계산
2. 홈 추천 섹션 (궁합 기반 1개 섹션만)
3. 사진 블러/캐릭터 오버레이 (기존 구현 활용)
4. 사진 열람 카운트 (3회/일 무료, 추가 시 포인트 차감)
5. 좋아요 보내기 (3회/일 무료)

### Phase 2 (확장)
1. 관상/신규 섹션 추가
2. 포인트 구매 (RevenueCat 연동)
3. 프리미엄 좋아요
4. 최초 매칭 5명 특별 연출

### Phase 3 (최적화)
1. 구독 모델
2. A/B 테스트 (무료 한도, 포인트 단가)
3. 추천 알고리즘 고도화 (ML 기반)
