---
name: data-analyst
description: 데이팅 앱 핵심 메트릭 분석, 코호트/퍼널 분석, SQL 쿼리, 시각화, 비즈니스 인사이트 도출을 담당하는 데이터 분석가 스킬
---

# Data Analyst (데이터 분석가)

> 데이터에서 의미를 읽어내고, 그것을 제품 결정으로 연결하는 역할.
> 사주 데이팅 앱이라는 독특한 도메인에서 무엇을 측정하고 어떻게 해석할 것인가.

---

## 1. 핵심 메트릭 대시보드

### 1.1 AARRR 프레임워크 적용

```
┌─────────────────────────────────────────────────────────────────┐
│                    SAJU DATING APP METRICS                       │
│                    ══════════════════════                        │
│                                                                 │
│  ┌─── Acquisition ────────────────────────────────────────────┐ │
│  │  Installs: ____       Signups: ____       Cost/Install: __ │ │
│  │  Profile Complete: ____%    Saju Calculated: ____%         │ │
│  │  Source: Organic __% / Paid __% / Referral __%             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           ↓                                     │
│  ┌─── Activation ─────────────────────────────────────────────┐ │
│  │  First Match View: ____%     First Like: ____%             │ │
│  │  First Mutual Match: ____%  First Message: ____%           │ │
│  │  Time to First Match: ____h  Saju View Rate: ____%        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           ↓                                     │
│  ┌─── Retention ──────────────────────────────────────────────┐ │
│  │  D1: ____%  D7: ____%  D30: ____%                         │ │
│  │  WAU: ____  MAU: ____  DAU/MAU: ____%                     │ │
│  │  Session/Day: ____  Avg Session Length: ____min            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           ↓                                     │
│  ┌─── Revenue ────────────────────────────────────────────────┐ │
│  │  Free→Paid Conversion: ____%   ARPU: ____원               │ │
│  │  ARPPU: ____원   LTV: ____원   Subscription Churn: ____%  │ │
│  │  MRR: ____원   Revenue/Match: ____원                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           ↓                                     │
│  ┌─── Referral ───────────────────────────────────────────────┐ │
│  │  K-Factor: ____  Invite Rate: ____%  Viral Coeff: ____    │ │
│  │  Referral Conversion: ____%  NPS: ____                    │ │
│  │  "궁합 공유" Rate: ____%  "사주 공유" Rate: ____%          │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 메트릭 상세 정의

#### Acquisition Metrics

| 메트릭 | 정의 | 계산 | 목표치 |
|--------|------|------|--------|
| **Install Count** | 앱 설치 수 | App Store + Play Store | - |
| **Signup Rate** | 설치 → 가입 전환율 | signups / installs | > 60% |
| **Profile Completion Rate** | 프로필 완성률 | completed_profiles / signups | > 70% |
| **Saju Calculation Rate** | 사주 산출률 | saju_calculated / signups | > 85% |
| **CAC** | 사용자 획득 비용 | total_spend / new_users | < LTV/3 |
| **Organic Rate** | 자연 유입 비율 | organic_installs / total | > 40% |

#### Activation Metrics

| 메트릭 | 정의 | "Aha Moment" | 목표치 |
|--------|------|-------------|--------|
| **Time to First Match** | 가입 → 첫 매칭까지 | "이 앱 궁합 재밌다!" | < 24h |
| **First Like Rate** | 첫 좋아요까지 | "이 사람 궁합 좋네!" | > 80% |
| **First Message Rate** | 매칭 → 첫 메시지 | "대화해볼까?" | > 40% |
| **Saju Detail View** | 사주 상세 조회 | "내 사주 흥미롭다!" | > 70% |
| **Compatibility Share** | 궁합 결과 공유 | "이거 친구한테 보여줘야지" | > 15% |

#### Retention Metrics

| 메트릭 | 정의 | 벤치마크 (데이팅 앱) | 우리 목표 |
|--------|------|---------------------|-----------|
| **D1 Retention** | 다음 날 재방문 | 25-35% | > 35% |
| **D7 Retention** | 7일 후 재방문 | 10-15% | > 18% |
| **D30 Retention** | 30일 후 재방문 | 5-8% | > 10% |
| **WAU** | 주간 활성 사용자 | - | 성장 추세 |
| **Stickiness (DAU/MAU)** | 일간/월간 활성 비율 | 20-30% | > 25% |

#### Revenue Metrics

| 메트릭 | 정의 | 계산 | 목표 |
|--------|------|------|------|
| **Conversion Rate** | 무료→유료 전환 | paid_users / total_users | > 5% |
| **ARPU** | 사용자당 평균 매출 | total_revenue / MAU | - |
| **ARPPU** | 결제 사용자당 매출 | total_revenue / paid_users | - |
| **LTV** | 생애 가치 | ARPPU * avg_lifetime_months | > 3x CAC |
| **MRR** | 월 반복 매출 | sum(active_subscriptions * price) | 성장 추세 |
| **Churn Rate** | 구독 이탈률 | cancelled / active_start | < 10%/월 |

#### Referral Metrics

| 메트릭 | 정의 | 계산 | 목표 |
|--------|------|------|------|
| **K-Factor** | 바이럴 계수 | invites_per_user * conversion_rate | > 0.5 |
| **Invite Rate** | 초대 전송률 | users_who_invited / total_users | > 20% |
| **Referral Conversion** | 초대받은 사람 전환률 | signup_from_invite / invites_sent | > 30% |
| **NPS** | 순추천지수 | promoters% - detractors% | > 30 |
| **궁합 공유율** | 궁합 결과 외부 공유 | shared_compatibilities / viewed | > 15% |

---

## 2. 코호트 분석 방법

### 2.1 가입 주차별 리텐션 코호트

```sql
-- 주차별 리텐션 코호트 분석
WITH cohorts AS (
  SELECT
    user_id,
    date_trunc('week', created_at)::date AS cohort_week
  FROM profiles
  WHERE created_at >= CURRENT_DATE - INTERVAL '12 weeks'
),
activity AS (
  SELECT
    user_id,
    date_trunc('week', created_at)::date AS activity_week
  FROM events
  WHERE created_at >= CURRENT_DATE - INTERVAL '12 weeks'
  GROUP BY 1, 2
)
SELECT
  c.cohort_week,
  COUNT(DISTINCT c.user_id) AS cohort_size,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + 7 THEN a.user_id END)::FLOAT
    / COUNT(DISTINCT c.user_id) AS week_1_retention,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + 14 THEN a.user_id END)::FLOAT
    / COUNT(DISTINCT c.user_id) AS week_2_retention,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + 21 THEN a.user_id END)::FLOAT
    / COUNT(DISTINCT c.user_id) AS week_3_retention,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + 28 THEN a.user_id END)::FLOAT
    / COUNT(DISTINCT c.user_id) AS week_4_retention
FROM cohorts c
LEFT JOIN activity a ON c.user_id = a.user_id
GROUP BY c.cohort_week
ORDER BY c.cohort_week;
```

**결과 해석 예시:**

```
cohort_week | cohort_size | W1     | W2     | W3     | W4
2026-01-06  |     500     | 35.2%  | 22.4%  | 18.1%  | 15.8%
2026-01-13  |     620     | 38.1%  | 25.0%  | 20.3%  | 17.5%  ← 개선!
2026-01-20  |     580     | 33.8%  | 21.2%  | 16.9%  | ???
2026-01-27  |     710     | 40.5%  | 27.3%  | ???    | ???    ← 최고!
```

분석 포인트:
- W1→W2 drop이 가장 큼 → "첫 주에 의미 있는 경험을 주는가?"
- 01-27 코호트가 좋은 이유? → 그 주에 무슨 변경이 있었는지 확인

### 2.2 사주 유형별 코호트

```sql
-- 일간(日干)별 리텐션 비교
-- "특정 사주 유형이 앱에 더 잘 맞는가?"
WITH saju_cohort AS (
  SELECT
    s.day_gan,
    c.name AS day_gan_name,
    p.user_id,
    p.created_at
  FROM saju s
  JOIN profiles p ON s.user_id = p.user_id
  JOIN cheongan c ON s.day_gan = c.id
)
SELECT
  sc.day_gan_name,
  COUNT(DISTINCT sc.user_id) AS users,
  AVG(CASE WHEN e7.user_id IS NOT NULL THEN 1 ELSE 0 END) AS d7_retention,
  AVG(CASE WHEN e30.user_id IS NOT NULL THEN 1 ELSE 0 END) AS d30_retention,
  AVG(um.match_accept_rate) AS avg_match_rate,
  AVG(um.meaningful_match_count) AS avg_meaningful_matches
FROM saju_cohort sc
LEFT JOIN (
  SELECT DISTINCT user_id
  FROM events
  WHERE created_at BETWEEN sc.created_at + INTERVAL '6 days'
    AND sc.created_at + INTERVAL '8 days'
) e7 ON sc.user_id = e7.user_id
LEFT JOIN (
  SELECT DISTINCT user_id
  FROM events
  WHERE created_at BETWEEN sc.created_at + INTERVAL '29 days'
    AND sc.created_at + INTERVAL '31 days'
) e30 ON sc.user_id = e30.user_id
LEFT JOIN user_metrics um ON sc.user_id = um.user_id
GROUP BY sc.day_gan_name
ORDER BY d30_retention DESC;
```

### 2.3 구독 코호트 (Revenue)

```sql
-- 구독 시작 월별 LTV 추적
SELECT
  date_trunc('month', subscription_started_at)::date AS sub_month,
  COUNT(*) AS subscribers,
  AVG(CASE WHEN subscription_ended_at IS NULL
           OR subscription_ended_at > subscription_started_at + INTERVAL '1 month'
      THEN 1 ELSE 0 END) AS month_1_survival,
  AVG(CASE WHEN subscription_ended_at IS NULL
           OR subscription_ended_at > subscription_started_at + INTERVAL '3 months'
      THEN 1 ELSE 0 END) AS month_3_survival,
  SUM(total_revenue_to_date) / COUNT(*) AS avg_ltv_to_date
FROM subscriptions
GROUP BY 1
ORDER BY 1;
```

---

## 3. 퍼널 분석

### 3.1 핵심 퍼널: 가입 → 첫 Meaningful Match

```
┌──────────────────────────────────────────────────────────────┐
│                    CORE FUNNEL                                │
│                                                              │
│  앱 설치         ████████████████████████████████  100%       │
│                                                              │
│  가입 완료       ████████████████████████          65%        │
│                  ↓ (-35%: 가입 과정 이탈)                      │
│                                                              │
│  사주 산출       ██████████████████████            60%        │
│                  ↓ (-5%: 생년월일 입력 거부)                    │
│                                                              │
│  프로필 완성     █████████████████████             55%        │
│                  ↓ (-5%: 사진/자기소개 미완)                    │
│                                                              │
│  첫 프로필 조회  ████████████████████              52%        │
│                  ↓ (-3%: 추천 대기)                            │
│                                                              │
│  첫 좋아요       ██████████████████                45%        │
│                  ↓ (-7%: 마음에 드는 프로필 없음)               │
│                                                              │
│  매칭 성사       ████████████                      30%        │
│                  ↓ (-15%: 상대방 미응답)                       │
│                                                              │
│  첫 메시지       █████████                         22%        │
│                  ↓ (-8%: 매칭됐지만 대화 안 함)                 │
│                                                              │
│  5+ 메시지       ██████                            15%        │
│  (Meaningful)    ↓ (-7%: 대화 이어지지 않음)                   │
│                                                              │
│  실제 만남       ███                                7%        │
│  (추정)                                                      │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 퍼널 분석 SQL

```sql
-- 일별 퍼널 분석
WITH funnel AS (
  SELECT
    date_trunc('day', p.created_at)::date AS signup_date,

    -- Stage 1: 가입
    COUNT(DISTINCT p.user_id) AS signups,

    -- Stage 2: 사주 산출
    COUNT(DISTINCT s.user_id) AS saju_calculated,

    -- Stage 3: 프로필 완성
    COUNT(DISTINCT CASE WHEN p.profile_completion >= 0.8 THEN p.user_id END)
      AS profile_completed,

    -- Stage 4: 첫 좋아요
    COUNT(DISTINCT CASE WHEN fl.user_id IS NOT NULL THEN fl.user_id END)
      AS first_liked,

    -- Stage 5: 매칭 성사
    COUNT(DISTINCT CASE WHEN fm.user_id IS NOT NULL THEN fm.user_id END)
      AS first_matched,

    -- Stage 6: 첫 메시지
    COUNT(DISTINCT CASE WHEN fmsg.user_id IS NOT NULL THEN fmsg.user_id END)
      AS first_messaged,

    -- Stage 7: Meaningful Match (5+ messages)
    COUNT(DISTINCT CASE WHEN mm.user_id IS NOT NULL THEN mm.user_id END)
      AS meaningful_matched

  FROM profiles p
  LEFT JOIN saju s ON p.user_id = s.user_id
  LEFT JOIN (
    SELECT actor_id AS user_id, MIN(created_at) AS first_at
    FROM swipe_actions WHERE action = 'like'
    GROUP BY 1
  ) fl ON p.user_id = fl.user_id
    AND fl.first_at <= p.created_at + INTERVAL '7 days'
  LEFT JOIN (
    SELECT unnest(participant_ids) AS user_id, MIN(matched_at) AS first_at
    FROM matches
    GROUP BY 1
  ) fm ON p.user_id = fm.user_id
    AND fm.first_at <= p.created_at + INTERVAL '14 days'
  LEFT JOIN (
    SELECT sender_id AS user_id, MIN(created_at) AS first_at
    FROM messages
    GROUP BY 1
  ) fmsg ON p.user_id = fmsg.user_id
    AND fmsg.first_at <= p.created_at + INTERVAL '14 days'
  LEFT JOIN (
    SELECT
      unnest(m.participant_ids) AS user_id,
      MIN(m.matched_at) AS first_at
    FROM matches m
    WHERE m.message_count >= 5
    GROUP BY 1
  ) mm ON p.user_id = mm.user_id
    AND mm.first_at <= p.created_at + INTERVAL '30 days'

  WHERE p.created_at >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY 1
  ORDER BY 1
)
SELECT
  signup_date,
  signups,
  ROUND(saju_calculated::NUMERIC / NULLIF(signups, 0) * 100, 1) AS saju_rate,
  ROUND(profile_completed::NUMERIC / NULLIF(signups, 0) * 100, 1) AS profile_rate,
  ROUND(first_liked::NUMERIC / NULLIF(signups, 0) * 100, 1) AS like_rate,
  ROUND(first_matched::NUMERIC / NULLIF(signups, 0) * 100, 1) AS match_rate,
  ROUND(first_messaged::NUMERIC / NULLIF(signups, 0) * 100, 1) AS message_rate,
  ROUND(meaningful_matched::NUMERIC / NULLIF(signups, 0) * 100, 1) AS meaningful_rate
FROM funnel;
```

### 3.3 퍼널 병목 진단

```sql
-- 가장 큰 이탈 구간 자동 감지
WITH funnel_rates AS (
  -- (위 쿼리에서 가져온 전환율 데이터)
  SELECT
    'Install → Signup' AS step,
    65.0 AS conversion_rate, 35.0 AS drop_rate
  UNION ALL SELECT 'Signup → Saju', 92.3, 7.7
  UNION ALL SELECT 'Saju → Profile', 91.7, 8.3
  UNION ALL SELECT 'Profile → First Like', 81.8, 18.2
  UNION ALL SELECT 'First Like → Match', 66.7, 33.3    -- ← 가장 큰 이탈!
  UNION ALL SELECT 'Match → Message', 73.3, 26.7
  UNION ALL SELECT 'Message → Meaningful', 68.2, 31.8
)
SELECT *
FROM funnel_rates
ORDER BY drop_rate DESC;

-- 결과: "First Like → Match" 구간이 33.3% 이탈 (가장 높음)
-- 의미: 좋아요를 눌렀지만 상대가 좋아요를 안 함
-- 액션: 프로필 품질 개선, 추천 알고리즘 튜닝, 상호 관심 시그널 강화
```

---

## 4. 사주별 행동 분석

### 4.1 오행별 활동 패턴

```sql
-- 어떤 오행 조합이 앱에서 가장 활발한가?
SELECT
  CASE
    WHEN s.oheng_mok >= s.oheng_hwa AND s.oheng_mok >= s.oheng_to
         AND s.oheng_mok >= s.oheng_geum AND s.oheng_mok >= s.oheng_su THEN '목(木)'
    WHEN s.oheng_hwa >= s.oheng_mok AND s.oheng_hwa >= s.oheng_to
         AND s.oheng_hwa >= s.oheng_geum AND s.oheng_hwa >= s.oheng_su THEN '화(火)'
    WHEN s.oheng_to >= s.oheng_mok AND s.oheng_to >= s.oheng_hwa
         AND s.oheng_to >= s.oheng_geum AND s.oheng_to >= s.oheng_su THEN '토(土)'
    WHEN s.oheng_geum >= s.oheng_mok AND s.oheng_geum >= s.oheng_hwa
         AND s.oheng_geum >= s.oheng_to AND s.oheng_geum >= s.oheng_su THEN '금(金)'
    ELSE '수(水)'
  END AS dominant_oheng,
  COUNT(DISTINCT s.user_id) AS user_count,
  AVG(um.match_accept_rate) AS avg_match_accept_rate,
  AVG(um.message_count_sent) AS avg_messages_sent,
  AVG(um.meaningful_match_count) AS avg_meaningful_matches,
  AVG(EXTRACT(EPOCH FROM (um.last_active_at - p.created_at)) / 86400) AS avg_active_days
FROM saju s
JOIN profiles p ON s.user_id = p.user_id
LEFT JOIN user_metrics um ON s.user_id = um.user_id
GROUP BY 1
ORDER BY avg_meaningful_matches DESC;
```

### 4.2 궁합별 실제 대화 이어짐 분석

```sql
-- 궁합 등급별 실제 매칭 성공률 (자기 실현적 예언 효과 포함)
SELECT
  cs.grade,
  COUNT(*) AS total_matches,
  AVG(CASE WHEN m.message_count >= 1 THEN 1 ELSE 0 END) AS message_start_rate,
  AVG(CASE WHEN m.message_count >= 5 THEN 1 ELSE 0 END) AS meaningful_rate,
  AVG(CASE WHEN m.message_count >= 20 THEN 1 ELSE 0 END) AS deep_conversation_rate,
  AVG(m.message_count) AS avg_message_count,
  AVG(EXTRACT(EPOCH FROM (m.last_message_at - m.matched_at)) / 86400) AS avg_conversation_days
FROM matches m
JOIN compatibility_scores cs ON m.compatibility_id = cs.id
WHERE m.matched_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY cs.grade
ORDER BY
  CASE cs.grade
    WHEN 'S' THEN 1
    WHEN 'A' THEN 2
    WHEN 'B+' THEN 3
    WHEN 'B' THEN 4
    WHEN 'C' THEN 5
    WHEN 'D' THEN 6
  END;
```

**예상 결과 해석:**

```
grade | total | msg_start | meaningful | deep_conv | avg_msgs | avg_days
S     |   150 |    82.0%  |    48.0%   |   22.0%   |   15.3   |   8.2
A     |   800 |    75.0%  |    38.0%   |   15.0%   |   11.8   |   6.1
B+    |  2000 |    68.0%  |    30.0%   |   10.0%   |    8.5   |   4.3
B     |  3500 |    55.0%  |    22.0%   |    7.0%   |    5.2   |   2.8
C     |  2000 |    42.0%  |    15.0%   |    5.0%   |    3.1   |   1.5
D     |   500 |    35.0%  |    12.0%   |    4.0%   |    2.5   |   1.1
```

분석: S→D로 갈수록 모든 지표 하락 → 사주 궁합이 (labeling effect 포함) 실제 행동에 영향

### 4.3 일간 조합별 베스트/워스트 매칭

```sql
-- 어떤 일간(日干) 조합이 가장 좋은/나쁜 결과를 보이는가?
SELECT
  c1.name AS person1_daygan,
  c2.name AS person2_daygan,
  COUNT(*) AS match_count,
  AVG(cs.total_score) AS avg_saju_score,
  AVG(CASE WHEN m.message_count >= 5 THEN 1 ELSE 0 END) AS meaningful_rate,
  AVG(m.message_count) AS avg_messages
FROM matches m
JOIN compatibility_scores cs ON m.compatibility_id = cs.id
JOIN saju s1 ON cs.user_id_1 = s1.user_id
JOIN saju s2 ON cs.user_id_2 = s2.user_id
JOIN cheongan c1 ON s1.day_gan = c1.id
JOIN cheongan c2 ON s2.day_gan = c2.id
WHERE m.matched_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c1.name, c2.name
HAVING COUNT(*) >= 10  -- 최소 표본
ORDER BY meaningful_rate DESC
LIMIT 20;
```

---

## 5. SQL 쿼리 패턴 (Supabase PostgreSQL)

### 5.1 일일 핵심 지표 스냅샷

```sql
-- 오늘의 핵심 지표 한눈에 보기
SELECT
  -- DAU
  (SELECT COUNT(DISTINCT user_id) FROM events
   WHERE created_at >= CURRENT_DATE) AS dau_today,

  -- 신규 가입
  (SELECT COUNT(*) FROM profiles
   WHERE created_at >= CURRENT_DATE) AS new_signups_today,

  -- 매칭 성사
  (SELECT COUNT(*) FROM matches
   WHERE matched_at >= CURRENT_DATE) AS matches_today,

  -- Meaningful Matches
  (SELECT COUNT(DISTINCT id) FROM matches
   WHERE matched_at >= CURRENT_DATE AND message_count >= 5) AS meaningful_today,

  -- 메시지 수
  (SELECT COUNT(*) FROM messages
   WHERE created_at >= CURRENT_DATE) AS messages_today,

  -- 신고 건수
  (SELECT COUNT(*) FROM events
   WHERE event_type = 'user_reported'
   AND created_at >= CURRENT_DATE) AS reports_today,

  -- 오늘 매출 (구독)
  (SELECT COALESCE(SUM(amount), 0) FROM payments
   WHERE created_at >= CURRENT_DATE
   AND status = 'completed') AS revenue_today;
```

### 5.2 사용자 세그먼트별 분석

```sql
-- 파워 유저 vs 일반 유저 vs 이탈 위험 유저
WITH user_segments AS (
  SELECT
    p.user_id,
    um.meaningful_match_count,
    um.last_active_at,
    CASE
      WHEN um.last_active_at < NOW() - INTERVAL '14 days' THEN 'churned'
      WHEN um.last_active_at < NOW() - INTERVAL '7 days' THEN 'at_risk'
      WHEN um.meaningful_match_count >= 3 THEN 'power'
      WHEN um.meaningful_match_count >= 1 THEN 'engaged'
      ELSE 'casual'
    END AS segment
  FROM profiles p
  LEFT JOIN user_metrics um ON p.user_id = um.user_id
  WHERE p.is_active = TRUE
)
SELECT
  segment,
  COUNT(*) AS user_count,
  ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM user_segments
GROUP BY segment
ORDER BY
  CASE segment
    WHEN 'power' THEN 1
    WHEN 'engaged' THEN 2
    WHEN 'casual' THEN 3
    WHEN 'at_risk' THEN 4
    WHEN 'churned' THEN 5
  END;
```

### 5.3 시간대별 활동 패턴

```sql
-- 언제 사용자가 가장 활발한가?
SELECT
  EXTRACT(DOW FROM created_at) AS day_of_week,  -- 0=일, 6=토
  EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Seoul') AS hour_kst,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY event_count DESC;

-- 인사이트: "일요일 밤 10시에 가장 활발" → 이 시간에 푸시 알림
```

### 5.4 이탈 예측 시그널

```sql
-- 이탈 위험 사용자 조기 감지
SELECT
  p.user_id,
  p.display_name,
  um.last_active_at,
  EXTRACT(DAY FROM NOW() - um.last_active_at) AS days_inactive,
  um.match_accept_rate,
  um.meaningful_match_count,
  p.premium_until,
  CASE
    WHEN um.meaningful_match_count = 0
         AND EXTRACT(DAY FROM NOW() - p.created_at) > 7 THEN '의미 있는 매칭 없음'
    WHEN um.match_accept_rate < 0.1 THEN '매칭 수락률 매우 낮음'
    WHEN um.message_count_received = 0
         AND um.message_count_sent > 5 THEN '보낸 메시지에 응답 없음'
    ELSE '활동 감소'
  END AS churn_reason
FROM profiles p
JOIN user_metrics um ON p.user_id = um.user_id
WHERE p.is_active = TRUE
  AND um.last_active_at < NOW() - INTERVAL '3 days'
  AND um.last_active_at > NOW() - INTERVAL '14 days'  -- 아직 완전 이탈 전
ORDER BY days_inactive DESC;
```

---

## 6. 일일/주간/월간 리포트 구조

### 6.1 일일 리포트 (자동 생성)

```
═══════════════════════════════════
  사주연분 일일 리포트 | 2026-02-20
═══════════════════════════════════

[핵심 지표]
  DAU: 5,230 (전일 대비 +3.2%)
  신규 가입: 180 (전일 대비 -5.0%)
  매칭 성사: 420 (전일 대비 +8.5%)
  Meaningful Matches: 85 (전일 대비 +12.0%) ← GOOD
  일 매출: 1,250,000원 (전일 대비 +2.1%)

[주의 사항]
  ⚠ 프로필 완성률 하락 (68% → 63%) — 온보딩 점검 필요
  ⚠ 신고 15건 (평소 8건) — CS팀 확인 필요

[실험 현황]
  EXP-001 (매칭 가중치): Day 5/14, 유의미한 차이 아직 없음
  EXP-002 (궁합 표시): Day 12/14, Treatment B가 +5.2% 우세 (p=0.08)

[사주 인사이트]
  오늘 가장 많이 매칭된 조합: 갑(甲)-기(己) (천간합!)
  가장 활발한 오행: 화(火) 사용자 (봄이 다가오면서?)
```

### 6.2 주간 리포트

```
[주간 트렌드]
  WAU: 12,500 (전주 대비 +4.8%)
  주간 Meaningful Matches: 520 (전주 대비 +7.2%)

[코호트 업데이트]
  이번 주 코호트 D7 리텐션: 36.5% (목표 35% 달성!)

[퍼널 변화]
  가입→프로필 완성: 68% → 71% (+3%p) — 온보딩 개선 효과

[세그먼트 분석]
  Power Users: 820명 (+12% 성장)
  At Risk Users: 350명 (지난 주 대비 동일)

[다음 주 액션]
  1. EXP-002 결과 분석 및 ship 결정
  2. 이탈 위험 사용자 대상 re-engagement 캠페인
  3. 봄 시즌 프로모션 데이터 준비
```

### 6.3 월간 리포트

```
[월간 요약]
  MAU: 25,000 (전월 대비 +15.2%)
  MRR: 32,500,000원 (전월 대비 +22.0%)
  LTV:CAC: 3.2:1 (전월 3.0:1 → 개선)

[코호트 리텐션 히트맵]
  (코호트별 W1-W4 리텐션 테이블)

[실험 결과 종합]
  완료된 실험: 3건
  Ship한 실험: 2건
  학습: (주요 인사이트 3줄 요약)

[사주 도메인 인사이트]
  - 가장 많은 사용자 일간: 갑(甲) 15.2%
  - 가장 높은 리텐션 일간: 정(丁) D30 18.5%
  - 가장 인기 있는 궁합 등급: A (조회수 기준)
  - 사주 정확도 만족도: 4.2/5.0

[다음 달 계획]
  1. 매칭 알고리즘 v2 출시
  2. 프리미엄 가격 실험
  3. 사주 해석 AI 모델 개선
```

---

## 7. 이상치 탐지 (봇, 어뷰징)

### 7.1 봇 탐지 규칙

```sql
-- 의심스러운 활동 패턴 감지
WITH suspicious_users AS (
  SELECT
    user_id,
    -- 비정상적으로 많은 좋아요
    COUNT(CASE WHEN event_type = 'match_accepted' THEN 1 END) AS likes_24h,
    -- 비정상적으로 빠른 프로필 조회
    AVG(CASE WHEN event_type = 'profile_viewed'
         THEN (event_properties->>'view_duration_sec')::FLOAT END) AS avg_view_sec,
    -- 동일 메시지 반복
    COUNT(DISTINCT CASE WHEN event_type = 'message_sent'
          THEN event_properties->>'content' END) AS unique_messages,
    COUNT(CASE WHEN event_type = 'message_sent' THEN 1 END) AS total_messages,
    -- 세션당 활동 수
    COUNT(*) AS events_24h
  FROM events
  WHERE created_at >= NOW() - INTERVAL '24 hours'
  GROUP BY user_id
)
SELECT
  user_id,
  likes_24h,
  avg_view_sec,
  CASE WHEN total_messages > 0
       THEN unique_messages::FLOAT / total_messages
       ELSE 1 END AS message_uniqueness,
  events_24h,
  CASE
    WHEN likes_24h > 200 THEN 'BOT: 과도한 좋아요'
    WHEN avg_view_sec < 0.5 THEN 'BOT: 프로필 즉시 넘김'
    WHEN total_messages > 50
         AND unique_messages::FLOAT / total_messages < 0.3 THEN 'SPAM: 반복 메시지'
    WHEN events_24h > 1000 THEN 'BOT: 비정상 활동량'
    ELSE NULL
  END AS flag
FROM suspicious_users
WHERE likes_24h > 200
   OR avg_view_sec < 0.5
   OR (total_messages > 50 AND unique_messages::FLOAT / total_messages < 0.3)
   OR events_24h > 1000;
```

### 7.2 어뷰징 패턴

```sql
-- 로맨스 스캠 의심 패턴
SELECT
  u.user_id,
  u.display_name,
  COUNT(DISTINCT CASE WHEN e.event_type = 'user_reported'
                      AND e.event_properties->>'target_user_id' = u.user_id::TEXT
                 THEN e.id END) AS report_count,
  COUNT(DISTINCT CASE WHEN e.event_type = 'user_blocked'
                      AND e.event_properties->>'target_user_id' = u.user_id::TEXT
                 THEN e.id END) AS block_count,
  -- 프로필 생성 직후 대량 메시지
  CASE WHEN p.created_at > NOW() - INTERVAL '3 days'
       AND um.message_count_sent > 50 THEN TRUE ELSE FALSE END AS rapid_messaging,
  -- 외부 링크 전송 시도
  (SELECT COUNT(*) FROM messages m
   WHERE m.sender_id = u.user_id
   AND m.content ~ 'https?://|bit\.ly|t\.co') AS external_links_sent
FROM auth.users u
JOIN profiles p ON u.id = p.user_id
LEFT JOIN user_metrics um ON u.id = um.user_id
LEFT JOIN events e ON TRUE
WHERE report_count >= 2 OR block_count >= 3 OR rapid_messaging = TRUE
GROUP BY u.user_id, u.display_name, p.created_at, um.message_count_sent;
```

### 7.3 자동 조치

```
Rule 1: 24시간 내 좋아요 200+ → 계정 일시 정지 + 관리자 검토
Rule 2: 신고 3건 이상 → 자동 프로필 숨김 + 관리자 검토
Rule 3: 외부 링크 3개 이상 전송 → 메시지 차단 + 경고
Rule 4: 차단 5건 이상 → 계정 정지
Rule 5: 동일 메시지 10회 이상 → 스팸 경고 + 일시 제한
```

---

## 8. 시각화 가이드라인

### 8.1 차트 유형 선택

| 분석 목적 | 추천 차트 | 이유 |
|-----------|-----------|------|
| 시간별 트렌드 | Line Chart | 변화 추이 한눈에 |
| 퍼널 분석 | Funnel Chart / Horizontal Bar | 단계별 이탈 시각화 |
| 코호트 리텐션 | Heatmap | 2차원 패턴 인식 |
| 세그먼트 비교 | Grouped Bar Chart | 그룹 간 비교 |
| 분포 분석 | Histogram / Box Plot | 데이터 분포 파악 |
| 상관관계 | Scatter Plot | 두 변수 관계 |
| 비율/구성 | Pie / Donut (≤5개) | 전체 대비 비율 |
| 오행 분포 | Radar Chart (Pentagon) | 5개 축 균형 시각화 |
| 사주 궁합 매트릭스 | Heatmap (10x10) | 일간 조합별 성과 |

### 8.2 색상 가이드

```
오행 색상 (앱 전체 일관성):
  목(木): #4CAF50 (Green)
  화(火): #F44336 (Red)
  토(土): #FFC107 (Amber)
  금(金): #9E9E9E (Grey) 또는 #FFD700 (Gold)
  수(水): #2196F3 (Blue)

메트릭 상태:
  좋음/달성:  #4CAF50 (Green)
  주의:       #FFC107 (Amber)
  위험/미달:  #F44336 (Red)
  중립:       #9E9E9E (Grey)

트렌드:
  상승:  #4CAF50 (Green) + ▲
  하락:  #F44336 (Red) + ▼
  유지:  #9E9E9E (Grey) + ─
```

### 8.3 대시보드 레이아웃 원칙

```
1. 가장 중요한 메트릭을 좌측 상단에 (F-pattern reading)
2. 관련 메트릭을 그룹핑 (AARRR 순서)
3. 수치 + 트렌드 + 맥락을 함께 표시
4. 드릴다운 가능한 구조 (요약 → 상세)
5. 실시간 데이터는 명시적으로 표시 ("5분 전 업데이트")
```

---

## 9. 비즈니스 인사이트 도출 프레임워크

### 9.1 분석 → 인사이트 → 액션 파이프라인

```
[데이터 관찰]
  "D7 리텐션이 지난 주 대비 3%p 하락"
      │
      ▼
[Why 분석] (5 Whys 또는 세그먼트 분석)
  "신규 사용자 중 '시주 미입력' 그룹의 리텐션이 특히 낮음"
  "이 그룹은 궁합 정확도가 낮다고 느껴 이탈하는 것으로 추정"
      │
      ▼
[인사이트]
  "시주를 입력하지 않은 사용자에게는 '간이 궁합'만 제공되어
   경험 품질이 떨어지며, 이것이 이탈의 주요 원인"
      │
      ▼
[액션 제안]
  1. 시주 미입력자 대상 "출생 시간 입력 유도" 캠페인
  2. 간이 궁합 해석 품질 개선
  3. "시간 모르면 어머니께 물어보세요" nudge 추가
      │
      ▼
[예상 임팩트]
  시주 입력률 20% 증가 → D7 리텐션 2%p 개선 예상
      │
      ▼
[실험 설계]
  A/B 테스트: 시주 입력 유도 UI → D7 리텐션 측정
```

### 9.2 인사이트 품질 체크리스트

```
[ ] Actionable: 이 인사이트로 구체적 액션을 취할 수 있는가?
[ ] Significant: 통계적으로/비즈니스적으로 유의미한가?
[ ] Causal: 상관관계가 아닌 인과관계인가?
[ ] Timely: 지금 행동해야 하는가?
[ ] Novel: 이미 알고 있는 것이 아닌 새로운 발견인가?
```

### 9.3 사주 도메인 특화 인사이트 예시

```
1. "목(木) 일간 사용자는 첫 메시지 전송률이 가장 높다 (52%)"
   → 목의 진취적 성격이 반영? 흥미로운 마케팅 소재

2. "천간합 조합의 D7 리텐션이 비합 조합보다 15%p 높다"
   → 사주 궁합이 실제 사용자 행동에 영향 (labeling effect 가능성)
   → 천간합 매칭을 더 적극적으로 추천?

3. "궁합 결과를 공유한 사용자의 D30 리텐션이 2배 높다"
   → 공유 = 재미를 느꼈다는 시그널
   → 공유 기능을 더 눈에 띄게 배치

4. "프리미엄 전환은 '사주 상세 해석' 조회 후 3일 이내에 68% 발생"
   → 사주 해석이 프리미엄 전환의 핵심 트리거
   → 무료 사용자에게 사주 해석 일부 미리보기 제공
```

---

## 10. 경쟁사 벤치마크 메트릭

### 10.1 한국 데이팅 앱 벤치마크

| 메트릭 | 글림 | 위피 | 아만다 | 정오의데이트 | 우리 목표 |
|--------|------|------|--------|-------------|-----------|
| MAU | ~200만 | ~150만 | ~80만 | ~50만 | 1만 (초기) |
| D1 Retention | ~35% | ~30% | ~28% | ~32% | > 35% |
| D30 Retention | ~8% | ~6% | ~7% | ~10% | > 10% |
| Conversion | ~5% | ~4% | ~8% | ~12% | > 5% |
| ARPU | ~3,000원 | ~2,500원 | ~5,000원 | ~8,000원 | > 3,000원 |
| NPS | ? | ? | ? | ? | > 30 |

### 10.2 우리만의 차별화 메트릭

| 메트릭 | 정의 | 경쟁사에 없는 이유 | 우리 목표 |
|--------|------|-------------------|-----------|
| **사주 산출률** | 가입자 중 사주 산출 비율 | 사주 기반 앱만의 메트릭 | > 85% |
| **궁합 조회율** | 매칭당 궁합 상세 조회 비율 | 사주 궁합이 핵심 | > 60% |
| **궁합 공유율** | 궁합 결과 외부 공유 비율 | 바이럴 루프 | > 15% |
| **사주 만족도** | 사주 해석 정확도 만족도 | 도메인 특화 | > 4.0/5.0 |
| **Saju-Match Correlation** | 사주 점수와 매칭 성공 상관 | 알고리즘 유효성 | r > 0.3 |

### 10.3 글로벌 데이팅 앱 벤치마크

| 메트릭 | Tinder | Bumble | Hinge | 우리 지향점 |
|--------|--------|--------|-------|-------------|
| D1 Ret | 25% | 30% | 35% | Hinge 수준 |
| Match→Msg | 30% | 45% | 50% | Hinge 수준 |
| Meaningful | 10% | 15% | 25% | > Hinge |
| Conversion | 5% | 8% | 12% | Hinge 수준 |

> Hinge를 벤치마크하는 이유: "designed to be deleted" — 우리와 철학이 유사.
> 양보다 질, 스와이프보다 의미 있는 연결.

---

## Quick Reference: 분석가의 일일 루틴

```
매일 아침:
  1. 일일 메트릭 스냅샷 확인 (이상치 있는지)
  2. 진행 중인 실험 중간 결과 확인 (guardrail 위반 없는지)
  3. 이상 탐지 알럿 확인 (봇, 어뷰징)
  4. 전날 대비 주요 변화 3줄 요약 작성

매주 월요일:
  5. 주간 코호트 리텐션 업데이트
  6. 퍼널 병목 진단
  7. 실험 결과 분석 및 의사결정
  8. 공정성 감사 (오행별 메트릭 편차)

매월 초:
  9. 월간 리포트 작성
  10. LTV/CAC 업데이트
  11. 경쟁사 벤치마크 업데이트
  12. 다음 달 실험 로드맵 수립
```
