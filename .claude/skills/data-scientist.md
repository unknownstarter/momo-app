---
name: data-scientist
description: 사주 기반 매칭 알고리즘 설계, A/B 테스트, 핵심 메트릭, 추천 시스템을 총괄하는 데이터 사이언티스트 스킬
---

# Data Scientist (데이터 사이언티스트)

> 사주 궁합이라는 도메인 지식을 실제로 동작하는 매칭 알고리즘으로 변환하고,
> 데이터 기반으로 지속적으로 개선하는 것이 이 역할의 핵심이다.

---

## 1. 매칭 알고리즘 설계 프레임워크

### 1.1 Overall Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Final Matching Score                      │
│                                                             │
│  Score = w1 * SajuScore                                     │
│        + w2 * PreferenceScore                               │
│        + w3 * AIBoostScore                                  │
│        + w4 * BehaviorScore                                 │
│                                                             │
│  Default weights: w1=0.40, w2=0.25, w3=0.20, w4=0.15       │
│  (weights are tuned via A/B testing)                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Layer 1: 사주 궁합 점수 (규칙 기반)

`fortune-master.md`에 정의된 궁합 점수 체계를 그대로 사용.

```typescript
interface SajuScore {
  total: number;           // 30-99 (정규화된 최종 점수)
  dayPillarHarmony: number;
  ohengComplement: number;
  sipsinRelation: number;
  yearPillarHarmony: number;
  monthPillarHarmony: number;
  hourPillarHarmony: number;
  overallBalance: number;
  specialFormations: number;
  penalties: number;
}

// 최종 사주 점수를 0-1 범위로 정규화
function normalizeSajuScore(score: SajuScore): number {
  return (score.total - 30) / 69; // 30~99 → 0~1
}
```

### 1.3 Layer 2: 사용자 선호도 반영 (Collaborative Filtering)

사용자의 명시적/암묵적 선호를 반영한다.

#### 명시적 선호 (Explicit Preferences)

```typescript
interface UserPreferences {
  // 기본 필터
  ageRange: { min: number; max: number };
  location: { lat: number; lng: number; radiusKm: number };
  gender: 'male' | 'female' | 'all';

  // 사주 관련 선호
  preferredOheng?: string[];       // 선호 오행 (예: 내가 부족한 오행)
  preferredDayGan?: string[];      // 선호 일간
  sajuImportance: number;          // 사주 중요도 (0-1, 사용자 설정)

  // 일반 선호
  values: string[];                // 중요 가치관 태그
  interests: string[];             // 관심사 태그
  relationshipGoal: 'casual' | 'serious' | 'marriage';
}
```

#### 암묵적 선호 (Implicit Preferences) — Collaborative Filtering

```typescript
// User-Item Matrix (사용자-프로필 상호작용)
// R[i][j] = 사용자 i가 프로필 j에 대해 보인 반응

// 반응 점수 체계:
// +3.0: 메시지 보냄
// +2.0: 매칭 수락 (좋아요)
// +1.0: 프로필 상세 조회 (3초 이상)
// +0.5: 프로필 클릭
//  0.0: 스킵 (무반응)
// -1.0: 명시적 거절 (싫어요)
// -2.0: 차단/신고

// Matrix Factorization (ALS or SGD)
// R ≈ U * V^T
// U: user latent factors (k dimensions)
// V: item latent factors (k dimensions)
// k = 50 (조정 가능)

interface CollaborativeScore {
  predictedRating: number;  // 0-1 정규화된 예측 평점
  confidence: number;       // 0-1 예측 신뢰도 (상호작용 수 기반)
}
```

### 1.4 Layer 3: AI 보강 점수

LLM을 활용한 추가 매칭 점수.

```typescript
interface AIBoostInput {
  // 사주 해석 텍스트 (두 사람의)
  person1SajuInterpretation: string;
  person2SajuInterpretation: string;

  // 사용자 프로필 텍스트
  person1Bio: string;
  person2Bio: string;

  // 가치관/라이프스타일 응답
  person1Values: Record<string, string>;
  person2Values: Record<string, string>;
}

// LLM 프롬프트 (structured output)
const prompt = `
두 사람의 사주 해석과 프로필을 분석하여 궁합을 평가하세요.

사람 1 사주 해석: {person1SajuInterpretation}
사람 1 프로필: {person1Bio}
사람 1 가치관: {person1Values}

사람 2 사주 해석: {person2SajuInterpretation}
사람 2 프로필: {person2Bio}
사람 2 가치관: {person2Values}

다음 JSON 형식으로 응답하세요:
{
  "compatibilityScore": 0.0-1.0,
  "dimensions": {
    "emotionalSync": 0.0-1.0,    // 감정적 교감 가능성
    "intellectualMatch": 0.0-1.0, // 지적 교류 가능성
    "lifestyleAlign": 0.0-1.0,    // 라이프스타일 일치도
    "growthPotential": 0.0-1.0    // 함께 성장 가능성
  },
  "reasoning": "한 줄 요약"
}
`;
```

### 1.5 Layer 4: 행동 패턴 점수

사용자의 앱 내 행동에서 파악한 선호 패턴.

```typescript
interface BehaviorScore {
  // 프로필 유사도 (과거 좋아요한 프로필과의 유사도)
  profileSimilarity: number;   // 0-1

  // 활동 시간대 일치 (같은 시간에 활동하는 사용자)
  activityOverlap: number;     // 0-1

  // 메시지 스타일 유사도 (자연어 처리 기반)
  communicationStyle: number;  // 0-1

  // 응답률 가중 (서로 응답할 가능성)
  mutualResponseLikelihood: number; // 0-1
}
```

### 1.6 최종 매칭 점수 계산

```typescript
function calculateFinalMatchScore(
  saju: number,        // 0-1
  preference: number,  // 0-1
  aiBoost: number,     // 0-1
  behavior: number,    // 0-1
  weights: Weights = DEFAULT_WEIGHTS
): MatchResult {
  // Hard filters 먼저 적용 (나이, 거리, 성별)
  // → 이 단계에서 탈락하면 점수 계산 자체를 하지 않음

  const rawScore = weights.saju * saju
                 + weights.preference * preference
                 + weights.aiBoost * aiBoost
                 + weights.behavior * behavior;

  // Diversity bonus: 최근 추천에서 다양성 부족 시 +0.05
  const diversityBonus = calculateDiversityBonus(userId);

  // Recency penalty: 최근 거절당한 유사 프로필이면 -0.1
  const recencyPenalty = calculateRecencyPenalty(userId, targetId);

  const finalScore = Math.max(0, Math.min(1, rawScore + diversityBonus - recencyPenalty));

  return {
    score: finalScore,
    breakdown: { saju, preference, aiBoost, behavior },
    rank: scoreToRank(finalScore), // S, A, B+, B, C, D
  };
}

const DEFAULT_WEIGHTS: Weights = {
  saju: 0.40,       // 사주 궁합 (핵심 차별점)
  preference: 0.25,  // 사용자 선호
  aiBoost: 0.20,     // AI 보강
  behavior: 0.15,    // 행동 패턴
};
```

---

## 2. A/B 테스트 설계

### 2.1 테스트 인프라

```
┌──────────┐     ┌──────────────┐     ┌────────────┐
│ Feature  │────→│ Assignment   │────→│ Experiment │
│ Flags    │     │ Service      │     │ Tracker    │
└──────────┘     │ (hash-based) │     └────────────┘
                 └──────────────┘           │
                                           ↓
                                    ┌────────────┐
                                    │ Analytics  │
                                    │ Pipeline   │
                                    └────────────┘
```

**Assignment 방법**: Deterministic hashing
```typescript
function assignVariant(userId: string, experimentId: string, variants: string[]): string {
  const hash = murmurhash3(`${userId}:${experimentId}`);
  const bucket = hash % 100; // 0-99
  const variantIndex = Math.floor(bucket / (100 / variants.length));
  return variants[variantIndex];
}
```

### 2.2 실험 카탈로그

#### Experiment 1: 매칭 알고리즘 가중치

```yaml
experiment_id: EXP-001
name: "사주 점수 가중치 최적화"
hypothesis: "사주 점수 가중치를 50%로 올리면 매칭 수락률이 10% 증가한다"
variants:
  control:
    weights: { saju: 0.40, preference: 0.25, aiBoost: 0.20, behavior: 0.15 }
  treatment_a:
    weights: { saju: 0.50, preference: 0.20, aiBoost: 0.18, behavior: 0.12 }
  treatment_b:
    weights: { saju: 0.30, preference: 0.30, aiBoost: 0.25, behavior: 0.15 }
primary_metric: match_accept_rate
secondary_metrics: [message_rate, d7_retention]
guardrail_metrics: [block_rate, report_rate]
sample_size: 3000_per_variant
duration: 14_days
```

#### Experiment 2: 궁합 표시 방식

```yaml
experiment_id: EXP-002
name: "궁합 점수 vs 텍스트 표시"
hypothesis: "점수 대신 텍스트 해석만 보여주면 매칭 수락률이 더 균등해진다"
variants:
  control: { display: "score_and_text" }      # "85점 - 찰떡궁합"
  treatment_a: { display: "text_only" }        # "서로를 빛나게 하는 관계"
  treatment_b: { display: "grade_and_text" }   # "A등급 - 서로를 빛나게 하는 관계"
  treatment_c: { display: "visual_gauge" }     # 시각적 게이지 + 텍스트
primary_metric: match_accept_rate_variance     # 점수별 수락률 분산 (낮을수록 좋음)
secondary_metrics: [overall_match_rate, profile_view_duration]
```

#### Experiment 3: 가격 실험

```yaml
experiment_id: EXP-003
name: "프리미엄 가격 최적화"
hypothesis: "9,900원이 14,900원보다 전환율 * ARPU가 높다"
variants:
  control: { monthly_price: 14900 }
  treatment_a: { monthly_price: 9900 }
  treatment_b: { monthly_price: 19900 }
  treatment_c: { monthly_price: 12900 }
primary_metric: revenue_per_user  # 전환율 * 가격
secondary_metrics: [conversion_rate, churn_rate, ltv_30d]
duration: 21_days
```

### 2.3 실험 의사결정 프레임워크

```
실험 결과 분석 시:

1. 통계적 유의성 확인 (p < 0.05)
2. 실용적 유의성 확인 (effect size > MDE)
3. Guardrail metric 확인 (악화 없는지)
4. 세그먼트별 분석 (특정 그룹에서만 효과 있는지)
5. 결정:
   ├─ 유의미한 개선 → Ship it
   ├─ 유의미하지 않음 → 실험 종료, 학습 기록
   ├─ Guardrail 위반 → 즉시 롤백
   └─ 혼재된 결과 → 추가 실험 설계
```

---

## 3. 핵심 메트릭 정의

### 3.1 North Star Metric

```
Meaningful Matches = 메시지 교환이 5회 이상인 매칭 수 (주간)
```

**Why 5회?**
- 1-2회: 인사 수준 (실질적 관심 불확실)
- 3-4회: 탐색 단계 (관심은 있지만 확정 아님)
- 5회+: 실질적 대화 (genuine interest)
- 이 기준은 데이터 축적 후 조정

### 3.2 Input Metrics (North Star을 구성하는 입력 지표)

```
NSM = Users × Match_Rate × Accept_Rate × Message_Rate × Sustain_Rate

Users:        주간 활성 사용자 수
Match_Rate:   사용자당 추천된 프로필 수
Accept_Rate:  추천된 프로필 중 좋아요 비율
Message_Rate: 매칭 성사 후 첫 메시지를 보낸 비율
Sustain_Rate: 첫 메시지 후 5회 이상 대화한 비율
```

### 3.3 전체 메트릭 체계

```
┌─────────────────────────────────────────────────────────┐
│                    METRIC HIERARCHY                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [L1] North Star: Meaningful Matches / Week             │
│                                                         │
│  [L2] Input Metrics:                                    │
│    ├── WAU (Weekly Active Users)                        │
│    ├── Match Accept Rate                                │
│    ├── First Message Rate                               │
│    ├── Response Rate                                    │
│    └── Conversation Sustain Rate (5+ messages)          │
│                                                         │
│  [L3] Health Metrics:                                   │
│    ├── Profile Completion Rate                          │
│    ├── Saju Accuracy Satisfaction (사주 정확도 만족도)    │
│    ├── D1/D7/D30 Retention                              │
│    ├── NPS (Net Promoter Score)                          │
│    └── Report/Block Rate (< 2% target)                  │
│                                                         │
│  [L4] Business Metrics:                                 │
│    ├── Conversion Rate (free → paid)                    │
│    ├── ARPU (Average Revenue Per User)                  │
│    ├── LTV (Lifetime Value)                             │
│    ├── CAC (Customer Acquisition Cost)                  │
│    ├── LTV:CAC Ratio (target > 3:1)                     │
│    └── Monthly Revenue                                  │
│                                                         │
│  [L5] Guardrail Metrics:                                │
│    ├── Crash Rate (< 0.1%)                              │
│    ├── API Latency (p95 < 500ms)                        │
│    ├── Saju Calculation Error Rate (< 0.01%)            │
│    └── CS Complaint Rate                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 4. 인과 추론: 사주 궁합이 실제 매칭 성공에 영향을 미치는가?

### 4.1 핵심 질문

```
H0: 사주 궁합 점수는 실제 매칭 성공(5+ 메시지)과 무관하다
H1: 사주 궁합 점수가 높을수록 매칭 성공률이 높다
```

### 4.2 분석 방법

#### Method 1: Observational Study (초기)

```sql
-- 사주 궁합 점수 구간별 매칭 성공률
SELECT
  CASE
    WHEN saju_score BETWEEN 30 AND 44 THEN 'D (30-44)'
    WHEN saju_score BETWEEN 45 AND 54 THEN 'C (45-54)'
    WHEN saju_score BETWEEN 55 AND 64 THEN 'B (55-64)'
    WHEN saju_score BETWEEN 65 AND 74 THEN 'B+ (65-74)'
    WHEN saju_score BETWEEN 75 AND 84 THEN 'A (75-84)'
    WHEN saju_score BETWEEN 85 AND 99 THEN 'S (85-99)'
  END AS score_tier,
  COUNT(*) AS total_matches,
  AVG(CASE WHEN message_count >= 5 THEN 1 ELSE 0 END) AS success_rate,
  AVG(message_count) AS avg_messages
FROM matches
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 1
ORDER BY 1;
```

**주의: Selection Bias**
- 높은 궁합 점수를 보여주면 사용자가 더 적극적 → 자기 실현적 예언
- 이를 제거하기 위해 "점수를 안 보여주는 그룹" A/B 테스트 필요

#### Method 2: RCT (Randomized Controlled Trial)

```yaml
experiment: "사주 궁합의 실제 효과 측정"
design:
  control: "실제 사주 궁합 점수 표시"
  treatment: "랜덤 궁합 점수 표시 (사용자 모르게)"
  # 윤리적 주의: 이 실험은 매우 제한적으로, 짧은 기간에만 수행

measure:
  - 실제 대화 지속률
  - 만족도 설문
  - 재방문율

expected_insight:
  - 사주 점수 자체가 행동에 영향을 미치는 정도 (labeling effect)
  - vs 실제 궁합의 효과 (underlying compatibility)
```

#### Method 3: Propensity Score Matching

```python
# 사주 궁합 점수 외 변수를 통제하여 인과효과 추정
from sklearn.linear_model import LogisticRegression
import numpy as np

# Propensity Score: P(high_saju | covariates)
covariates = ['age_diff', 'distance_km', 'preference_overlap',
              'activity_level_diff', 'profile_completeness']

# Step 1: Propensity score 계산
ps_model = LogisticRegression()
ps_model.fit(X[covariates], X['high_saju'])
X['propensity'] = ps_model.predict_proba(X[covariates])[:, 1]

# Step 2: Matching
# 유사한 propensity score를 가진 high/low saju 쌍을 매칭

# Step 3: ATE (Average Treatment Effect) 추정
# high_saju 그룹과 low_saju 그룹의 성공률 차이
```

### 4.3 예상 시나리오

```
시나리오 A: 사주 궁합이 실제로 유의미한 효과 있음
  → 사주 알고리즘 가중치를 더 올린다
  → "과학적으로 검증된 궁합" 마케팅 가능 (단, 과장 금지)

시나리오 B: Labeling effect만 있음 (점수를 보면 행동이 바뀜)
  → 사주는 "의미 부여 도구"로 포지셔닝
  → 점수 표시 방식이 핵심 (높은 점수 강조, 낮은 점수 완화)

시나리오 C: 효과 없음
  → 사주는 순수 엔터테인먼트로 포지셔닝
  → 매칭에는 다른 요소를 더 활용
  → 그래도 사주 콘텐츠의 재미/공유 가치는 유지
```

---

## 5. Cold Start 문제 해결

### 5.1 신규 사용자 매칭 전략

```
Phase 1: 사주 기반 매칭 (Day 0)
  ├── 사주팔자만으로 궁합 계산 가능 (행동 데이터 불필요)
  ├── 오행 상호보완성 기반 추천
  └── 기본 선호도 필터 (나이, 거리)

Phase 2: 하이브리드 (Day 1-7)
  ├── 사주 + 초기 행동 데이터
  ├── 어떤 프로필을 클릭하는지 학습
  └── Explore vs Exploit: 70% 사주 기반 + 30% 탐색

Phase 3: 풀 모델 (Day 7+)
  ├── 4개 레이어 모두 활용
  ├── Collaborative Filtering 본격 적용
  └── 개인화된 가중치 조정
```

### 5.2 Cold Start에서 사주의 강점

```
기존 데이팅 앱의 Cold Start:
  "이 사용자에 대해 아무것도 모른다"
  → 인기 있는 프로필 추천 (popularity bias)
  → 매력적이지만 안 맞는 사람 추천

사주 데이팅 앱의 Cold Start:
  "생년월일시만 알면 사주팔자를 안다"
  → 사주 궁합 기반 추천 (day 0부터 개인화 가능!)
  → 이것이 사주 앱의 핵심 경쟁 우위
```

### 5.3 새로운 아이템(프로필) Cold Start

```typescript
// 새 사용자의 프로필이 추천에 노출되려면:
// 1. 사주 산출 즉시 궁합 테이블 pre-compute
// 2. 활성 사용자 상위 N명과의 궁합을 미리 계산

async function onNewUserRegistered(user: User): Promise<void> {
  const saju = calculateSaju(user.birthInfo);

  // 활성 사용자 중 기본 필터 통과하는 후보
  const candidates = await getActiveCandidates(user.preferences);

  // 사주 궁합 batch 계산
  const compatibilities = candidates.map(candidate => ({
    userId: user.id,
    candidateId: candidate.id,
    sajuScore: calculateSajuCompatibility(saju, candidate.saju),
  }));

  // DB에 저장 (매칭 후보 테이블)
  await batchInsertCompatibilities(compatibilities);
}
```

---

## 6. 추천 시스템 설계

### 6.1 Two-Stage Retrieval + Ranking

```
Stage 1: Candidate Retrieval (빠르게 후보 축소)
  │
  ├── Hard Filters: 나이, 거리, 성별, 차단 목록
  ├── Saju Pre-filter: 궁합 점수 하위 10% 제외
  └── → 수천 명 → 수백 명으로 축소
  │
Stage 2: Ranking (정밀 점수 계산)
  │
  ├── 4-Layer 매칭 점수 계산
  ├── Diversity injection (다양성 주입)
  ├── Position bias 보정
  └── → 상위 20명을 오늘의 추천으로
```

### 6.2 다양성 보장 (Diversity)

```typescript
function injectDiversity(rankedList: MatchResult[]): MatchResult[] {
  // 문제: 상위 20명이 모두 비슷한 유형이면 지루함
  // 해결: MMR (Maximal Marginal Relevance)

  const selected: MatchResult[] = [];
  const lambda = 0.7; // relevance vs diversity trade-off

  while (selected.length < 20 && rankedList.length > 0) {
    let bestScore = -Infinity;
    let bestIdx = -1;

    for (let i = 0; i < rankedList.length; i++) {
      const relevance = rankedList[i].score;
      const maxSimilarity = selected.length > 0
        ? Math.max(...selected.map(s => profileSimilarity(s, rankedList[i])))
        : 0;

      const mmrScore = lambda * relevance - (1 - lambda) * maxSimilarity;

      if (mmrScore > bestScore) {
        bestScore = mmrScore;
        bestIdx = i;
      }
    }

    selected.push(rankedList.splice(bestIdx, 1)[0]);
  }

  return selected;
}
```

### 6.3 추천 Refresh 전략

```
일일 추천: 매일 아침 새로운 20명 추천
  ├── 이전에 본 프로필은 제외
  ├── 새로 가입한 사용자 우선 노출 (신선도)
  └── 주말에는 더 많은 추천 (30명)

실시간 보충: 모두 확인하면 추가 추천
  ├── "보너스 추천" (사주 특별 궁합 프레이밍)
  └── 프리미엄: 무제한 추천
```

---

## 7. 실험 파이프라인

### 7.1 Hypothesis → Experiment → Analysis → Decision

```
┌──────────────┐
│  가설 수립    │  "사주 궁합 85점 이상만 보여주면 매칭 품질이 올라갈까?"
└──────┬───────┘
       ↓
┌──────────────┐
│  실험 설계    │  MDE, 샘플 사이즈, 기간, 메트릭 정의
└──────┬───────┘
       ↓
┌──────────────┐
│  구현 & 배포  │  Feature flag, 실험 그룹 할당
└──────┬───────┘
       ↓
┌──────────────┐
│  데이터 수집  │  최소 2주 (주말 2번 포함)
└──────┬───────┘
       ↓
┌──────────────┐
│  분석         │  통계 검정, 세그먼트 분석, guardrail 확인
└──────┬───────┘
       ↓
┌──────────────┐
│  의사결정     │  Ship / Iterate / Kill
└──────┬───────┘
       ↓
┌──────────────┐
│  기록 & 공유  │  실험 결과 문서화, 팀 공유
└──────────────┘
```

### 7.2 샘플 사이즈 계산

```python
from scipy import stats
import numpy as np

def required_sample_size(
    baseline_rate: float,     # 현재 전환율 (예: 0.15)
    mde: float,               # Minimum Detectable Effect (예: 0.02 = 2%p 개선)
    alpha: float = 0.05,      # 유의수준
    power: float = 0.80,      # 검정력
    n_variants: int = 2       # variant 수
) -> int:
    """각 variant당 필요한 샘플 수"""
    p1 = baseline_rate
    p2 = baseline_rate + mde
    pooled_p = (p1 + p2) / 2

    z_alpha = stats.norm.ppf(1 - alpha / (2 if n_variants == 2 else n_variants))
    z_beta = stats.norm.ppf(power)

    n = ((z_alpha * np.sqrt(2 * pooled_p * (1 - pooled_p))
        + z_beta * np.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2) / (p2 - p1) ** 2

    # Bonferroni correction for multiple comparisons
    if n_variants > 2:
        n *= np.log(n_variants)

    return int(np.ceil(n))

# 예시: 매칭 수락률 15% → 17% 개선 감지
# required_sample_size(0.15, 0.02) ≈ 3,600 per variant
```

---

## 8. 통계적 유의성 검증

### 8.1 기본 검정 방법

```python
# 비율 비교: Chi-squared test 또는 Z-test
from scipy.stats import chi2_contingency, norm

def proportion_test(
    n_control: int, success_control: int,
    n_treatment: int, success_treatment: int
) -> dict:
    p_control = success_control / n_control
    p_treatment = success_treatment / n_treatment
    p_pooled = (success_control + success_treatment) / (n_control + n_treatment)

    se = np.sqrt(p_pooled * (1 - p_pooled) * (1/n_control + 1/n_treatment))
    z_stat = (p_treatment - p_control) / se
    p_value = 2 * (1 - norm.cdf(abs(z_stat)))

    return {
        'control_rate': p_control,
        'treatment_rate': p_treatment,
        'lift': (p_treatment - p_control) / p_control,
        'z_statistic': z_stat,
        'p_value': p_value,
        'significant': p_value < 0.05,
        'confidence_interval': (
            p_treatment - p_control - 1.96 * se,
            p_treatment - p_control + 1.96 * se
        )
    }
```

### 8.2 Sequential Testing (Peeking 방지)

```python
# 실험 도중 결과를 확인하는 "peeking" 문제 해결
# → Group Sequential Testing 또는 Always Valid Inference

def sequential_test(
    daily_results: list[dict],  # [{'control': n, 'treatment': n, 'day': d}, ...]
    alpha_spending: str = 'obrien_fleming'  # alpha spending function
) -> dict:
    """
    O'Brien-Fleming alpha spending:
    - 초반에는 유의성 기준을 매우 엄격하게
    - 후반에는 점점 완화
    - 전체 alpha = 0.05를 유지하면서 중간 분석 허용
    """
    # Implementation: 실제로는 statsmodels의 GroupSequential 사용
    pass
```

### 8.3 Multiple Testing Correction

```python
# 여러 메트릭을 동시에 검정할 때
from statsmodels.stats.multitest import multipletests

def correct_multiple_tests(p_values: list[float], method: str = 'fdr_bh') -> list:
    """
    method options:
    - 'bonferroni': 가장 보수적
    - 'fdr_bh': Benjamini-Hochberg (권장)
    - 'holm': Holm-Bonferroni
    """
    reject, corrected_pvalues, _, _ = multipletests(p_values, method=method)
    return list(zip(corrected_pvalues, reject))
```

---

## 9. 편향 감지 및 공정성

### 9.1 사주 편향 모니터링

```sql
-- 특정 사주 조합이 체계적으로 불이익을 받는지 확인
SELECT
  day_gan,                    -- 일간 (甲~癸)
  COUNT(*) AS user_count,
  AVG(avg_match_score) AS avg_score_received,
  AVG(match_accept_rate) AS avg_accept_rate,
  AVG(message_rate) AS avg_message_rate
FROM users u
JOIN user_metrics um ON u.id = um.user_id
GROUP BY day_gan
ORDER BY avg_accept_rate;

-- 이상적: 모든 일간의 수락률이 비슷해야 함
-- 편향 감지: 특정 일간의 수락률이 평균 대비 20% 이상 낮으면 알럿
```

### 9.2 공정성 메트릭

```typescript
interface FairnessMetrics {
  // Demographic Parity: 모든 사주 그룹이 비슷한 매칭률을 받는가
  demographicParity: number;  // max - min match rate across oheng groups

  // Equal Opportunity: 실제 좋은 매칭일 때 추천될 확률이 균등한가
  equalOpportunity: number;

  // Calibration: 점수 85점은 정말 85%의 성공률을 의미하는가
  calibration: { predictedBin: string; actualRate: number }[];
}

// 공정성 모니터링 (주간)
function fairnessAudit(): FairnessAuditResult {
  const ohengGroups = ['목', '화', '토', '금', '수'];
  const matchRates = ohengGroups.map(g => getMatchRateForGroup(g));

  const maxRate = Math.max(...matchRates);
  const minRate = Math.min(...matchRates);

  return {
    demographicParity: maxRate - minRate,
    alert: maxRate - minRate > 0.10, // 10%p 이상 차이나면 경고
    details: ohengGroups.map((g, i) => ({ group: g, rate: matchRates[i] })),
  };
}
```

### 9.3 편향 완화 전략

```
발견된 편향 → 원인 분석 → 완화 적용

예: "수(水) 일간 사용자의 매칭률이 낮다"
  ├── 원인 1: 수 일간이 소수 → 매칭 풀이 작음
  │   → 해결: 수 일간 사용자에게 더 넓은 범위 추천
  │
  ├── 원인 2: 궁합 알고리즘이 수 일간에 불리한 구조
  │   → 해결: 점수 체계 재검토, 상극 감점 완화
  │
  └── 원인 3: 수 일간 해석이 매력적이지 않음
      → 해결: 해석 텍스트 개선, 강점 부각
```

---

## 10. 데이터 기반 의사결정 프레임워크

### 10.1 Decision Matrix

| 상황 | 데이터 기반 결정 | 직관 기반 결정 |
|------|-----------------|---------------|
| 트래픽 충분, 명확한 메트릭 | A/B 테스트 | X |
| 트래픽 부족 (초기) | 정성 리서치 + 소규모 테스트 | 경험 기반 판단 |
| 새로운 카테고리 | 사용자 인터뷰 + MVP | 비전 기반 결정 |
| 윤리적 결정 | 데이터 참고, 원칙 우선 | 철학적 판단 |

### 10.2 Weekly Data Review

```
매주 월요일 데이터 리뷰:

1. North Star Metric 추이 (주간 meaningful matches)
2. Input Metrics 분해 (어디서 병목이 생기는가)
3. 실험 진행 상황 (진행 중 실험 중간 결과)
4. 공정성 감사 (편향 모니터링)
5. 이상치 탐지 (봇, 어뷰징)
6. Action Items 도출
```

---

## Quick Reference: 알고리즘 치트시트

```
매칭 점수 = 0.40 * Saju + 0.25 * Preference + 0.20 * AI + 0.15 * Behavior

NSM = Meaningful Matches (5+ messages) / Week

Sample Size = ~3,600/variant (15% baseline, 2%p MDE)

공정성 기준: 모든 오행 그룹의 매칭률 차이 < 10%p

Cold Start 강점: Day 0부터 사주 기반 개인화 가능

실험 원칙: p < 0.05 AND effect size > MDE AND guardrail OK → Ship
```
