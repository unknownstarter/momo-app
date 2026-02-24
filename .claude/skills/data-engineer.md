---
name: data-engineer
description: Supabase 기반 데이터 아키텍처, 파이프라인, 모델링, 개인정보보호를 총괄하는 데이터 엔지니어 스킬
---

# Data Engineer (데이터 엔지니어)

> 사주 데이팅 앱의 모든 데이터가 안전하고 효율적으로 흐르도록 설계하고 구축한다.
> Supabase(PostgreSQL) 기반으로 실시간 데이터 처리부터 배치 분석까지 아우른다.

---

## 1. Supabase 기반 데이터 아키텍처

### 1.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│   Flutter App ──── Supabase Client SDK ──── REST / Realtime     │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                     Supabase Platform                            │
│                                                                  │
│  ┌───────────┐  ┌────────────┐  ┌───────────┐  ┌────────────┐  │
│  │  Auth     │  │  Database   │  │  Storage  │  │  Realtime  │  │
│  │  (GoTrue) │  │ (PostgreSQL)│  │  (S3)     │  │  (Phoenix) │  │
│  └───────────┘  └─────┬──────┘  └───────────┘  └────────────┘  │
│                       │                                          │
│  ┌────────────────────▼─────────────────────────────────────┐   │
│  │              Edge Functions (Deno)                         │   │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌────────────┐ │   │
│  │  │ Saju     │ │ Matching │ │ AI        │ │ Analytics  │ │   │
│  │  │ Calc     │ │ Engine   │ │ Interpret │ │ Ingestion  │ │   │
│  │  └──────────┘ └──────────┘ └───────────┘ └────────────┘ │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              pg_cron (Scheduled Jobs)                      │   │
│  │  - 일일 통계 집계                                          │   │
│  │  - 매칭 점수 재계산 (신규 사용자)                           │   │
│  │  - 코호트 분석 배치                                        │   │
│  │  - 데이터 정리 (soft delete 정리)                          │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Services                             │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌─────────────┐  │
│  │ OpenAI / │  │ Firebase │  │ Analytics  │  │ Monitoring  │  │
│  │ Claude   │  │ (Push)   │  │ (Mixpanel/ │  │ (Sentry)    │  │
│  │ API      │  │          │  │  Amplitude)│  │             │  │
│  └──────────┘  └──────────┘  └────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Supabase 프로젝트 구성

```
supabase/
├── migrations/           # 스키마 마이그레이션
│   ├── 001_auth.sql
│   ├── 002_profiles.sql
│   ├── 003_saju.sql
│   ├── 004_matching.sql
│   ├── 005_messaging.sql
│   ├── 006_events.sql
│   └── 007_analytics.sql
├── functions/            # Edge Functions
│   ├── calculate-saju/
│   ├── calculate-match/
│   ├── ai-interpret/
│   └── ingest-event/
├── seed.sql              # 테스트 데이터
└── config.toml           # 로컬 개발 설정
```

---

## 2. 데이터 파이프라인 설계

### 2.1 이벤트 수집 파이프라인 (Event Collection)

```
Client App → Edge Function → events 테이블 → pg_cron → 집계 테이블

Event Schema:
{
  event_id: uuid,
  user_id: uuid,
  event_type: string,       // 'profile_view', 'match_accept', 'message_sent', ...
  event_properties: jsonb,  // 이벤트별 추가 데이터
  device_info: jsonb,       // OS, version, screen
  session_id: uuid,
  created_at: timestamptz
}
```

#### 주요 이벤트 목록

| 카테고리 | 이벤트 | 설명 | 주요 속성 |
|----------|--------|------|-----------|
| Auth | `signup_completed` | 가입 완료 | method, referral_source |
| Auth | `login` | 로그인 | method |
| Profile | `profile_created` | 프로필 생성 | completion_rate |
| Profile | `saju_calculated` | 사주 산출 | birth_info_type (시간 포함/미포함) |
| Profile | `profile_photo_uploaded` | 사진 업로드 | photo_count |
| Match | `profile_viewed` | 프로필 조회 | target_user_id, view_duration_sec |
| Match | `match_accepted` | 매칭 수락 (좋아요) | target_user_id, saju_score |
| Match | `match_rejected` | 매칭 거절 | target_user_id, saju_score |
| Match | `match_created` | 매칭 성사 (양방향) | match_id, saju_score |
| Chat | `message_sent` | 메시지 전송 | match_id, message_length |
| Chat | `message_read` | 메시지 읽음 | match_id |
| Saju | `compatibility_viewed` | 궁합 상세 조회 | match_id, section_viewed |
| Revenue | `subscription_started` | 구독 시작 | plan, price |
| Revenue | `subscription_cancelled` | 구독 취소 | plan, reason |
| Safety | `user_reported` | 신고 | target_user_id, reason |
| Safety | `user_blocked` | 차단 | target_user_id |

#### 이벤트 수집 Edge Function

```typescript
// supabase/functions/ingest-event/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { events } = await req.json(); // 배치 이벤트 수신

  // 유효성 검증
  const validEvents = events.filter(validateEvent);

  // 배치 삽입
  const { error } = await supabase
    .from('events')
    .insert(validEvents.map(e => ({
      user_id: e.userId,
      event_type: e.eventType,
      event_properties: e.properties,
      device_info: e.deviceInfo,
      session_id: e.sessionId,
      created_at: e.timestamp || new Date().toISOString(),
    })));

  if (error) {
    console.error('Event ingestion error:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ ingested: validEvents.length }), { status: 200 });
});
```

### 2.2 실시간 데이터 처리 (Supabase Realtime)

```sql
-- Realtime 구독 대상 테이블
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- RLS (Row Level Security) 설정
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own messages"
  ON messages FOR SELECT
  USING (
    auth.uid() IN (
      SELECT user_id FROM match_participants WHERE match_id = messages.match_id
    )
  );
```

**Realtime 활용 시나리오:**
- 새 메시지 수신 (채팅)
- 매칭 성사 알림
- 상대방이 프로필을 조회했을 때 알림 (프리미엄)
- 온라인 상태 표시

### 2.3 배치 처리 (pg_cron)

```sql
-- pg_cron 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 일일 통계 집계 (매일 새벽 3시 KST)
SELECT cron.schedule(
  'daily-stats-aggregation',
  '0 18 * * *',  -- UTC 18:00 = KST 03:00
  $$
  INSERT INTO daily_stats (stat_date, metric_name, metric_value)
  SELECT
    CURRENT_DATE - 1 AS stat_date,
    'dau' AS metric_name,
    COUNT(DISTINCT user_id) AS metric_value
  FROM events
  WHERE created_at >= CURRENT_DATE - 1
    AND created_at < CURRENT_DATE
  UNION ALL
  SELECT
    CURRENT_DATE - 1,
    'new_signups',
    COUNT(*)
  FROM profiles
  WHERE created_at >= CURRENT_DATE - 1
    AND created_at < CURRENT_DATE
  UNION ALL
  SELECT
    CURRENT_DATE - 1,
    'matches_created',
    COUNT(*)
  FROM matches
  WHERE created_at >= CURRENT_DATE - 1
    AND created_at < CURRENT_DATE
  UNION ALL
  SELECT
    CURRENT_DATE - 1,
    'meaningful_matches',
    COUNT(DISTINCT m.id)
  FROM matches m
  JOIN (
    SELECT match_id, COUNT(*) AS msg_count
    FROM messages
    WHERE created_at >= CURRENT_DATE - 1
      AND created_at < CURRENT_DATE
    GROUP BY match_id
    HAVING COUNT(*) >= 5
  ) mc ON m.id = mc.match_id
  ON CONFLICT (stat_date, metric_name)
  DO UPDATE SET metric_value = EXCLUDED.metric_value;
  $$
);

-- 코호트 분석 배치 (매주 월요일 새벽 4시 KST)
SELECT cron.schedule(
  'weekly-cohort-analysis',
  '0 19 * * 1',  -- UTC 19:00 Monday = KST 04:00 Monday
  $$
  INSERT INTO cohort_retention (cohort_week, weeks_since, retained_users, cohort_size)
  SELECT
    date_trunc('week', p.created_at)::date AS cohort_week,
    EXTRACT(WEEK FROM age(e.created_at, p.created_at))::int AS weeks_since,
    COUNT(DISTINCT e.user_id) AS retained_users,
    cohort.size AS cohort_size
  FROM profiles p
  JOIN events e ON p.user_id = e.user_id
  JOIN (
    SELECT date_trunc('week', created_at)::date AS week, COUNT(*) AS size
    FROM profiles
    GROUP BY 1
  ) cohort ON cohort.week = date_trunc('week', p.created_at)::date
  WHERE p.created_at >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY 1, 2, cohort.size
  ON CONFLICT (cohort_week, weeks_since)
  DO UPDATE SET
    retained_users = EXCLUDED.retained_users,
    cohort_size = EXCLUDED.cohort_size;
  $$
);

-- 매칭 점수 재계산 (매일 새벽 2시 — 신규 사용자 기준)
SELECT cron.schedule(
  'daily-match-recalculation',
  '0 17 * * *',  -- UTC 17:00 = KST 02:00
  $$
  SELECT calculate_new_user_matches();
  $$
);

-- 오래된 이벤트 아카이빙 (매월 1일)
SELECT cron.schedule(
  'monthly-event-archive',
  '0 18 1 * *',
  $$
  INSERT INTO events_archive
  SELECT * FROM events
  WHERE created_at < CURRENT_DATE - INTERVAL '90 days';

  DELETE FROM events
  WHERE created_at < CURRENT_DATE - INTERVAL '90 days';
  $$
);
```

---

## 3. ETL/ELT 패턴

### 3.1 ELT 우선 접근 (Supabase PostgreSQL 내에서)

```
Raw Data (events 테이블)
    │
    ├── [E] Extract: 이미 Supabase에 있음
    │
    ├── [L] Load: events 테이블에 적재 완료
    │
    └── [T] Transform: pg_cron + SQL functions로 변환
        ├── daily_stats (일일 집계)
        ├── user_metrics (사용자별 메트릭)
        ├── cohort_retention (코호트 분석)
        ├── match_analytics (매칭 분석)
        └── saju_analytics (사주별 분석)
```

### 3.2 Transform Functions

```sql
-- 사용자 메트릭 갱신 함수
CREATE OR REPLACE FUNCTION update_user_metrics()
RETURNS void AS $$
BEGIN
  INSERT INTO user_metrics (
    user_id,
    total_matches,
    match_accept_rate,
    avg_response_time_min,
    message_count_sent,
    message_count_received,
    meaningful_match_count,
    last_active_at,
    updated_at
  )
  SELECT
    p.user_id,
    COUNT(DISTINCT m.id) AS total_matches,
    COALESCE(
      AVG(CASE WHEN e.event_type = 'match_accepted' THEN 1
               WHEN e.event_type = 'match_rejected' THEN 0
          END), 0
    ) AS match_accept_rate,
    COALESCE(
      AVG(EXTRACT(EPOCH FROM (reply.created_at - msg.created_at)) / 60),
      0
    ) AS avg_response_time_min,
    COUNT(DISTINCT CASE WHEN msg.sender_id = p.user_id THEN msg.id END) AS message_count_sent,
    COUNT(DISTINCT CASE WHEN msg.sender_id != p.user_id THEN msg.id END) AS message_count_received,
    COUNT(DISTINCT CASE WHEN mc.msg_count >= 5 THEN m.id END) AS meaningful_match_count,
    MAX(e.created_at) AS last_active_at,
    NOW() AS updated_at
  FROM profiles p
  LEFT JOIN matches m ON p.user_id = ANY(m.participant_ids)
  LEFT JOIN events e ON p.user_id = e.user_id
  LEFT JOIN messages msg ON m.id = msg.match_id
  LEFT JOIN LATERAL (
    SELECT created_at
    FROM messages
    WHERE match_id = msg.match_id
      AND sender_id != msg.sender_id
      AND created_at > msg.created_at
    ORDER BY created_at
    LIMIT 1
  ) reply ON TRUE
  LEFT JOIN (
    SELECT match_id, COUNT(*) AS msg_count
    FROM messages
    GROUP BY match_id
  ) mc ON m.id = mc.match_id
  GROUP BY p.user_id
  ON CONFLICT (user_id)
  DO UPDATE SET
    total_matches = EXCLUDED.total_matches,
    match_accept_rate = EXCLUDED.match_accept_rate,
    avg_response_time_min = EXCLUDED.avg_response_time_min,
    message_count_sent = EXCLUDED.message_count_sent,
    message_count_received = EXCLUDED.message_count_received,
    meaningful_match_count = EXCLUDED.meaningful_match_count,
    last_active_at = EXCLUDED.last_active_at,
    updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. 데이터 모델링

### 4.1 사주 데이터 모델

```sql
-- 천간 참조 테이블
CREATE TABLE cheongan (
  id SMALLINT PRIMARY KEY,       -- 1-10
  name VARCHAR(2) NOT NULL,      -- 갑, 을, 병, ...
  hanja VARCHAR(2) NOT NULL,     -- 甲, 乙, 丙, ...
  oheng VARCHAR(2) NOT NULL,     -- 목, 화, 토, 금, 수
  eum_yang VARCHAR(2) NOT NULL   -- 양, 음
);

-- 지지 참조 테이블
CREATE TABLE jiji (
  id SMALLINT PRIMARY KEY,       -- 1-12
  name VARCHAR(2) NOT NULL,      -- 자, 축, 인, ...
  hanja VARCHAR(2) NOT NULL,     -- 子, 丑, 寅, ...
  tti VARCHAR(4) NOT NULL,       -- 쥐, 소, 호랑이, ...
  oheng VARCHAR(2) NOT NULL,
  eum_yang VARCHAR(2) NOT NULL,
  month SMALLINT,                -- 1-12 (절기 기준)
  hour_start TIME,               -- 시작 시간
  hour_end TIME                  -- 종료 시간
);

-- 사주팔자 테이블
CREATE TABLE saju (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 입력 정보
  birth_year INT NOT NULL,
  birth_month INT NOT NULL,
  birth_day INT NOT NULL,
  birth_hour INT,                 -- nullable (모르는 경우)
  birth_minute INT,
  is_lunar BOOLEAN DEFAULT FALSE,
  birth_longitude FLOAT,          -- 진태양시 보정용
  is_true_solar_time BOOLEAN DEFAULT FALSE,

  -- 사주 결과 (년주, 월주, 일주, 시주)
  year_gan SMALLINT REFERENCES cheongan(id),
  year_ji SMALLINT REFERENCES jiji(id),
  month_gan SMALLINT REFERENCES cheongan(id),
  month_ji SMALLINT REFERENCES jiji(id),
  day_gan SMALLINT REFERENCES cheongan(id),
  day_ji SMALLINT REFERENCES jiji(id),
  hour_gan SMALLINT REFERENCES cheongan(id),    -- nullable
  hour_ji SMALLINT REFERENCES jiji(id),          -- nullable

  -- 오행 분포
  oheng_mok SMALLINT DEFAULT 0,
  oheng_hwa SMALLINT DEFAULT 0,
  oheng_to SMALLINT DEFAULT 0,
  oheng_geum SMALLINT DEFAULT 0,
  oheng_su SMALLINT DEFAULT 0,

  -- 십신 배치 (JSON)
  sipsin_map JSONB,

  -- 특수 요소
  special_formations JSONB,       -- 특수 격국, 신살 등

  -- AI 해석 결과
  ai_interpretation TEXT,
  ai_personality_summary TEXT,

  -- 메타
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  calculation_version VARCHAR(10) DEFAULT '1.0',

  UNIQUE(user_id),
  CONSTRAINT valid_birth CHECK (
    birth_month BETWEEN 1 AND 12
    AND birth_day BETWEEN 1 AND 31
    AND (birth_hour IS NULL OR birth_hour BETWEEN 0 AND 23)
  )
);

-- 인덱스
CREATE INDEX idx_saju_day_gan ON saju(day_gan);
CREATE INDEX idx_saju_oheng ON saju(oheng_mok, oheng_hwa, oheng_to, oheng_geum, oheng_su);
```

### 4.2 사용자-매칭-채팅 관계 모델

```sql
-- 사용자 프로필
CREATE TABLE profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name VARCHAR(50) NOT NULL,
  birth_date DATE NOT NULL,
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  photos TEXT[] DEFAULT '{}',        -- Storage URL 배열
  location GEOGRAPHY(POINT, 4326),   -- PostGIS
  age INT GENERATED ALWAYS AS (
    EXTRACT(YEAR FROM age(birth_date))
  ) STORED,

  -- 선호도
  preferred_gender VARCHAR(10),
  preferred_age_min INT DEFAULT 20,
  preferred_age_max INT DEFAULT 45,
  preferred_distance_km INT DEFAULT 50,
  saju_importance FLOAT DEFAULT 0.5 CHECK (saju_importance BETWEEN 0 AND 1),
  relationship_goal VARCHAR(20) DEFAULT 'serious',

  -- 가치관/관심사 (태그)
  values_tags TEXT[] DEFAULT '{}',
  interest_tags TEXT[] DEFAULT '{}',

  -- 상태
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  profile_completion FLOAT DEFAULT 0,
  premium_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 공간 인덱스
CREATE INDEX idx_profiles_location ON profiles USING GIST(location);
CREATE INDEX idx_profiles_active ON profiles(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_profiles_gender_age ON profiles(gender, age);

-- 궁합 점수 (Pre-computed)
CREATE TABLE compatibility_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id_1 UUID NOT NULL REFERENCES auth.users(id),
  user_id_2 UUID NOT NULL REFERENCES auth.users(id),

  -- 점수 breakdown
  saju_score FLOAT NOT NULL,
  day_pillar_score FLOAT,
  oheng_complement_score FLOAT,
  sipsin_score FLOAT,

  -- 최종 점수
  total_score FLOAT NOT NULL,
  grade VARCHAR(2) NOT NULL,          -- S, A, B+, B, C, D

  -- AI 해석
  compatibility_text TEXT,
  strengths JSONB,                     -- 강점 목록
  growth_points JSONB,                 -- 성장 포인트 목록
  date_suggestions JSONB,              -- 데이트 추천

  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  calculation_version VARCHAR(10) DEFAULT '1.0',

  UNIQUE(user_id_1, user_id_2),
  CONSTRAINT ordered_ids CHECK (user_id_1 < user_id_2)  -- 중복 방지
);

CREATE INDEX idx_compat_user1 ON compatibility_scores(user_id_1);
CREATE INDEX idx_compat_user2 ON compatibility_scores(user_id_2);
CREATE INDEX idx_compat_score ON compatibility_scores(total_score DESC);

-- 매칭 (양방향 좋아요 성사)
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids UUID[] NOT NULL,      -- [user_id_1, user_id_2]
  compatibility_id UUID REFERENCES compatibility_scores(id),

  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active', 'unmatched', 'expired')),

  -- 메타
  matched_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  message_count INT DEFAULT 0,
  unmatched_at TIMESTAMPTZ,
  unmatched_by UUID
);

CREATE INDEX idx_matches_participants ON matches USING GIN(participant_ids);
CREATE INDEX idx_matches_status ON matches(status) WHERE status = 'active';

-- 좋아요/싫어요 (매칭 전)
CREATE TABLE swipe_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES auth.users(id),
  target_id UUID NOT NULL REFERENCES auth.users(id),
  action VARCHAR(10) NOT NULL CHECK (action IN ('like', 'pass', 'super_like')),
  saju_score FLOAT,                    -- 당시 노출된 점수
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(actor_id, target_id)
);

CREATE INDEX idx_swipe_target ON swipe_actions(target_id, action);

-- 메시지
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text'
    CHECK (message_type IN ('text', 'image', 'saju_card', 'system')),

  -- 읽음 처리
  read_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ               -- soft delete
);

CREATE INDEX idx_messages_match ON messages(match_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender_id);
```

### 4.3 이벤트 로그 스키마

```sql
-- 이벤트 테이블 (파티셔닝)
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_properties JSONB DEFAULT '{}',
  device_info JSONB DEFAULT '{}',
  session_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- 월별 파티션 자동 생성
CREATE TABLE events_2026_01 PARTITION OF events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE events_2026_02 PARTITION OF events
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE events_2026_03 PARTITION OF events
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

-- (pg_cron으로 미래 파티션 자동 생성)
SELECT cron.schedule(
  'create-next-month-partition',
  '0 0 25 * *',  -- 매월 25일
  $$
  SELECT create_next_month_partition('events');
  $$
);

-- 인덱스
CREATE INDEX idx_events_user_type ON events(user_id, event_type, created_at);
CREATE INDEX idx_events_type ON events(event_type, created_at);

-- 이벤트 아카이브 (90일 이후)
CREATE TABLE events_archive (
  LIKE events INCLUDING ALL
);
```

### 4.4 분석용 집계 테이블

```sql
-- 일일 통계
CREATE TABLE daily_stats (
  stat_date DATE NOT NULL,
  metric_name VARCHAR(50) NOT NULL,
  metric_value NUMERIC NOT NULL,
  dimension JSONB DEFAULT '{}',        -- 추가 차원 (OS, region 등)
  created_at TIMESTAMPTZ DEFAULT NOW(),

  PRIMARY KEY (stat_date, metric_name)
);

-- 사용자 메트릭 (집계)
CREATE TABLE user_metrics (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  total_matches INT DEFAULT 0,
  match_accept_rate FLOAT DEFAULT 0,
  avg_response_time_min FLOAT DEFAULT 0,
  message_count_sent INT DEFAULT 0,
  message_count_received INT DEFAULT 0,
  meaningful_match_count INT DEFAULT 0,
  last_active_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 코호트 리텐션
CREATE TABLE cohort_retention (
  cohort_week DATE NOT NULL,
  weeks_since INT NOT NULL,
  retained_users INT NOT NULL,
  cohort_size INT NOT NULL,

  PRIMARY KEY (cohort_week, weeks_since)
);

-- 사주별 분석
CREATE TABLE saju_analytics (
  day_gan SMALLINT NOT NULL,
  period_start DATE NOT NULL,
  user_count INT,
  avg_match_rate FLOAT,
  avg_message_rate FLOAT,
  avg_meaningful_match_rate FLOAT,
  most_compatible_day_gan SMALLINT,

  PRIMARY KEY (day_gan, period_start)
);
```

---

## 5. 데이터 품질 관리

### 5.1 데이터 검증 규칙

```sql
-- 프로필 데이터 검증
CREATE OR REPLACE FUNCTION validate_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- 나이 범위 검증
  IF NEW.age < 18 OR NEW.age > 100 THEN
    RAISE EXCEPTION 'Invalid age: must be between 18 and 100';
  END IF;

  -- 사진 수 검증
  IF array_length(NEW.photos, 1) IS NOT NULL AND array_length(NEW.photos, 1) > 9 THEN
    RAISE EXCEPTION 'Too many photos: maximum 9';
  END IF;

  -- 프로필 완성도 자동 계산
  NEW.profile_completion := calculate_profile_completion(NEW);

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_profile
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION validate_profile();

-- 사주 데이터 무결성 검증
CREATE OR REPLACE FUNCTION validate_saju()
RETURNS TRIGGER AS $$
BEGIN
  -- 오행 합계 검증 (8개 글자에서 나오므로 범위 제한)
  IF (NEW.oheng_mok + NEW.oheng_hwa + NEW.oheng_to + NEW.oheng_geum + NEW.oheng_su) < 4
     OR (NEW.oheng_mok + NEW.oheng_hwa + NEW.oheng_to + NEW.oheng_geum + NEW.oheng_su) > 16 THEN
    RAISE EXCEPTION 'Invalid oheng distribution';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_saju
  BEFORE INSERT OR UPDATE ON saju
  FOR EACH ROW EXECUTE FUNCTION validate_saju();
```

### 5.2 데이터 품질 모니터링

```sql
-- 일일 데이터 품질 체크 (pg_cron)
CREATE OR REPLACE FUNCTION daily_data_quality_check()
RETURNS TABLE(check_name TEXT, status TEXT, details JSONB) AS $$
BEGIN
  -- Check 1: 사주 없는 프로필
  RETURN QUERY
  SELECT
    'profiles_without_saju'::TEXT,
    CASE WHEN COUNT(*) > 0 THEN 'WARNING' ELSE 'OK' END,
    jsonb_build_object('count', COUNT(*))
  FROM profiles p
  LEFT JOIN saju s ON p.user_id = s.user_id
  WHERE s.id IS NULL AND p.created_at < NOW() - INTERVAL '1 hour';

  -- Check 2: 중복 사주 계산
  RETURN QUERY
  SELECT
    'duplicate_saju'::TEXT,
    CASE WHEN COUNT(*) > 0 THEN 'ERROR' ELSE 'OK' END,
    jsonb_build_object('count', COUNT(*))
  FROM (
    SELECT user_id, COUNT(*) AS cnt
    FROM saju GROUP BY user_id HAVING COUNT(*) > 1
  ) dup;

  -- Check 3: 이벤트 수집 지연
  RETURN QUERY
  SELECT
    'event_ingestion_delay'::TEXT,
    CASE WHEN MAX(created_at) < NOW() - INTERVAL '5 minutes' THEN 'WARNING' ELSE 'OK' END,
    jsonb_build_object('last_event_at', MAX(created_at))
  FROM events;

  -- Check 4: NULL 비율 체크 (사주 핵심 필드)
  RETURN QUERY
  SELECT
    'saju_null_rate'::TEXT,
    CASE WHEN null_rate > 0.05 THEN 'WARNING' ELSE 'OK' END,
    jsonb_build_object('null_rate', null_rate)
  FROM (
    SELECT
      AVG(CASE WHEN day_gan IS NULL THEN 1 ELSE 0 END) AS null_rate
    FROM saju
  ) nr;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. 개인정보보호

### 6.1 한국 개인정보보호법 준수

```
┌─────────────────────────────────────────────────────────┐
│                개인정보 처리 원칙                         │
├─────────────────────────────────────────────────────────┤
│ 1. 수집 최소화: 필요한 것만 수집                          │
│ 2. 목적 제한: 수집 목적 외 사용 금지                      │
│ 3. 안전성 확보: 암호화, 접근 통제                         │
│ 4. 투명성: 사용자에게 처리 현황 공개                      │
│ 5. 동의 기반: 명시적 동의 획득                           │
│ 6. 파기: 목적 달성 시 즉시 파기                          │
└─────────────────────────────────────────────────────────┘
```

### 6.2 민감정보 분류 및 보호

```sql
-- 민감 데이터 암호화 (pgcrypto)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 생년월일시 (사주 산출용): 암호화 저장
-- NOTE: 사주 결과는 평문으로 저장 (역으로 생년월일을 추정하기 어려움)
-- 원본 생년월일시는 암호화

ALTER TABLE saju ADD COLUMN birth_info_encrypted BYTEA;

-- 암호화 함수
CREATE OR REPLACE FUNCTION encrypt_birth_info(
  birth_year INT, birth_month INT, birth_day INT,
  birth_hour INT, birth_minute INT
) RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(
    json_build_object(
      'y', birth_year, 'm', birth_month, 'd', birth_day,
      'h', birth_hour, 'min', birth_minute
    )::TEXT,
    current_setting('app.encryption_key')
  );
END;
$$ LANGUAGE plpgsql;
```

### 6.3 데이터 접근 통제 (RLS)

```sql
-- 프로필: 본인 것만 수정 가능, 활성 프로필은 검색 가능
CREATE POLICY "Users can view active profiles"
  ON profiles FOR SELECT
  USING (is_active = TRUE OR user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (user_id = auth.uid());

-- 사주: 본인 것만 조회/수정 가능
CREATE POLICY "Users can view own saju"
  ON saju FOR SELECT
  USING (user_id = auth.uid());

-- 궁합: 관련된 두 사용자만 조회 가능
CREATE POLICY "Participants can view compatibility"
  ON compatibility_scores FOR SELECT
  USING (
    auth.uid() = user_id_1 OR auth.uid() = user_id_2
  );

-- 메시지: 매칭 참여자만 조회 가능
CREATE POLICY "Match participants can view messages"
  ON messages FOR SELECT
  USING (
    match_id IN (
      SELECT id FROM matches
      WHERE auth.uid() = ANY(participant_ids)
    )
  );

-- 이벤트: 본인 것만 (관리자는 전체)
CREATE POLICY "Users can view own events"
  ON events FOR SELECT
  USING (user_id = auth.uid());
```

### 6.4 데이터 삭제 (잊힐 권리)

```sql
-- 계정 탈퇴 시 데이터 삭제 프로세스
CREATE OR REPLACE FUNCTION delete_user_data(target_user_id UUID)
RETURNS void AS $$
BEGIN
  -- 1. 메시지 내용 삭제 (매칭 기록은 유지하되 내용 제거)
  UPDATE messages SET content = '[삭제됨]', deleted_at = NOW()
  WHERE sender_id = target_user_id;

  -- 2. 프로필 사진 삭제 (Storage)
  -- Edge Function에서 처리

  -- 3. 사주 데이터 삭제
  DELETE FROM saju WHERE user_id = target_user_id;

  -- 4. 프로필 비활성화 및 익명화
  UPDATE profiles SET
    display_name = '탈퇴한 사용자',
    bio = NULL,
    photos = '{}',
    location = NULL,
    is_active = FALSE,
    values_tags = '{}',
    interest_tags = '{}'
  WHERE user_id = target_user_id;

  -- 5. 이벤트 익명화 (통계 목적으로 유지하되 개인 식별 불가)
  UPDATE events SET
    user_id = '00000000-0000-0000-0000-000000000000'::UUID,
    device_info = '{}'
  WHERE user_id = target_user_id;

  -- 6. 궁합 점수 삭제
  DELETE FROM compatibility_scores
  WHERE user_id_1 = target_user_id OR user_id_2 = target_user_id;

  -- 7. 스와이프 기록 삭제
  DELETE FROM swipe_actions
  WHERE actor_id = target_user_id OR target_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 7. 데이터 마이그레이션 전략

### 7.1 마이그레이션 원칙

```
1. Zero-downtime migration (다운타임 없는 마이그레이션)
2. 롤백 가능한 구조 (backward compatible)
3. 작은 단위로 점진적 적용
4. 데이터 무결성 검증 후 완료
```

### 7.2 마이그레이션 절차

```bash
# Supabase CLI 기반 마이그레이션

# 1. 마이그레이션 파일 생성
supabase migration new add_saju_special_formations

# 2. SQL 작성 (supabase/migrations/xxx_add_saju_special_formations.sql)

# 3. 로컬 테스트
supabase db reset  # 로컬 DB에 모든 마이그레이션 재적용

# 4. 스테이징 적용
supabase db push --linked  # 원격 프로젝트에 적용

# 5. 프로덕션 적용
supabase db push --linked --project-ref <prod-ref>
```

### 7.3 대규모 데이터 마이그레이션 패턴

```sql
-- 예: 사주 테이블에 새 컬럼 추가 + 기존 데이터 변환

-- Step 1: 새 컬럼 추가 (nullable로, 즉시 실행)
ALTER TABLE saju ADD COLUMN day_gan_name VARCHAR(2);

-- Step 2: 배치로 기존 데이터 채우기 (점진적)
DO $$
DECLARE
  batch_size INT := 1000;
  total_updated INT := 0;
BEGIN
  LOOP
    UPDATE saju s SET day_gan_name = c.name
    FROM cheongan c
    WHERE s.day_gan = c.id
      AND s.day_gan_name IS NULL
    LIMIT batch_size;

    GET DIAGNOSTICS total_updated = ROW_COUNT;
    EXIT WHEN total_updated = 0;

    COMMIT;
    PERFORM pg_sleep(0.1);  -- 부하 분산
  END LOOP;
END $$;

-- Step 3: 검증
SELECT COUNT(*) FROM saju WHERE day_gan_name IS NULL AND day_gan IS NOT NULL;
-- 0이면 성공

-- Step 4: NOT NULL 제약 추가 (검증 후)
ALTER TABLE saju ALTER COLUMN day_gan_name SET NOT NULL;
```

---

## 8. 모니터링 및 알럿

### 8.1 모니터링 대상

```
┌─────────────────────────────────────────────┐
│              Monitoring Stack                │
├─────────────────────────────────────────────┤
│                                             │
│  Infrastructure:                            │
│    ├── Supabase Dashboard (기본 모니터링)     │
│    ├── DB Connection Pool Usage             │
│    ├── Storage Usage                        │
│    └── Edge Function Invocations            │
│                                             │
│  Application:                               │
│    ├── Sentry (에러 트래킹)                  │
│    ├── API Response Times (p50/p95/p99)     │
│    ├── Saju Calculation Errors              │
│    └── Matching Engine Performance          │
│                                             │
│  Business:                                  │
│    ├── Real-time DAU                        │
│    ├── Match Rate Dashboard                 │
│    ├── Revenue Dashboard                    │
│    └── Safety Metrics                       │
│                                             │
└─────────────────────────────────────────────┘
```

### 8.2 알럿 규칙

```yaml
alerts:
  - name: "High Error Rate"
    condition: "error_rate > 1% for 5 minutes"
    severity: critical
    action: "PagerDuty + Slack #alerts"

  - name: "Saju Calculation Failure"
    condition: "saju_calc_error_count > 10 in 1 hour"
    severity: high
    action: "Slack #engineering"

  - name: "DB Connection Pool Exhaustion"
    condition: "active_connections > 80% of max"
    severity: high
    action: "Slack #infrastructure"

  - name: "Event Ingestion Delay"
    condition: "no new events for 10 minutes"
    severity: medium
    action: "Slack #data"

  - name: "Abnormal Signup Rate"
    condition: "signup_rate > 3x daily average"
    severity: medium
    action: "Slack #growth (봇 가입 가능성)"

  - name: "High Report Rate"
    condition: "reports > 50 in 1 hour"
    severity: high
    action: "Slack #safety"
```

---

## 9. 백업 및 복구

### 9.1 백업 전략

```
┌────────────────────────────────────────────┐
│              Backup Strategy                │
├────────────────────────────────────────────┤
│                                            │
│  Supabase Pro Plan (기본 제공):             │
│    ├── Point-in-Time Recovery (PITR)       │
│    ├── Daily automated backups             │
│    └── 7-day retention                     │
│                                            │
│  추가 백업 (자체 구현):                      │
│    ├── 일일 pg_dump → Cloud Storage        │
│    ├── 30-day retention                    │
│    └── Cross-region backup (DR용)          │
│                                            │
│  사주 데이터 특별 백업:                      │
│    ├── 사주 산출 결과는 재계산 가능           │
│    ├── AI 해석 결과는 별도 백업 (비용 절약)   │
│    └── 궁합 점수는 재계산 가능               │
│                                            │
└────────────────────────────────────────────┘
```

### 9.2 복구 절차

```
RTO (Recovery Time Objective): 1시간
RPO (Recovery Point Objective): 5분 (PITR 기준)

복구 시나리오별 절차:

1. 단일 테이블 데이터 손실
   → PITR로 특정 시점 복구
   → 해당 테이블만 추출하여 복원

2. 전체 DB 손실
   → Supabase PITR 복구
   → 또는 최신 pg_dump에서 복원

3. 사주 데이터 오류
   → 사주 재계산 batch 실행 (원본 생년월일시에서)
   → AI 해석 재생성 (비용 발생)

4. Region 장애
   → Cross-region 백업에서 복원
   → DNS 전환
```

### 9.3 재해 복구 테스트

```
분기별 DR 테스트:
1. 백업에서 복원 테스트 (별도 환경)
2. 복원된 데이터 무결성 검증
3. RTO/RPO 측정
4. 결과 문서화
```

---

## Quick Reference: 데이터 엔지니어 체크리스트

```
[ ] Supabase 프로젝트 초기 설정
[ ] 스키마 마이그레이션 생성 및 적용
[ ] RLS 정책 설정 (모든 테이블)
[ ] Realtime 구독 설정 (messages, matches)
[ ] Edge Functions 배포 (saju-calc, matching, events)
[ ] pg_cron 배치 작업 설정
[ ] 이벤트 수집 파이프라인 테스트
[ ] 데이터 품질 체크 자동화
[ ] 백업 설정 확인
[ ] 모니터링/알럿 설정
[ ] 개인정보보호 검토 (RLS, 암호화, 삭제)
[ ] 마이그레이션 롤백 절차 문서화
```
