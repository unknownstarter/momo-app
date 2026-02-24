---
name: backend-developer
description: 사주 데이팅 앱의 Supabase 백엔드 전문가 — DB 설계, RLS, Edge Functions, Auth, Realtime, Storage
---

# Backend Developer (Supabase Specialist) — 사주 데이팅 앱

## 1. Supabase 아키텍처 개요

### 기술 스택
```
Database:     PostgreSQL 15+ (Supabase managed)
Auth:         Supabase Auth (GoTrue)
Storage:      Supabase Storage (S3 compatible)
Realtime:     Supabase Realtime (Phoenix Channels)
Edge Functions: Deno runtime (TypeScript)
API:          PostgREST (자동 REST API)
Migrations:   Supabase CLI (supabase db diff, supabase migration)
```

### 환경 구성
```
Local:      supabase start (Docker 기반 로컬 개발)
Staging:    Supabase 프로젝트 (staging)
Production: Supabase 프로젝트 (production)
```

### 프로젝트 구조
```
supabase/
├── config.toml              # Supabase 로컬 설정
├── seed.sql                 # 시드 데이터
├── migrations/
│   ├── 20260101000000_initial_schema.sql
│   ├── 20260102000000_add_saju_tables.sql
│   ├── 20260103000000_add_matching_system.sql
│   └── ...
├── functions/
│   ├── saju-analysis/
│   │   └── index.ts
│   ├── calculate-compatibility/
│   │   └── index.ts
│   ├── daily-matches/
│   │   └── index.ts
│   ├── process-payment-webhook/
│   │   └── index.ts
│   └── _shared/
│       ├── supabase-client.ts
│       ├── saju-engine.ts
│       └── cors.ts
└── tests/
    ├── database/
    └── functions/
```

---

## 2. 데이터베이스 스키마

### 핵심 테이블 설계

#### users (인증 연동)
```sql
-- Supabase auth.users와 연동되는 공개 프로필
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  birth_date DATE NOT NULL,
  birth_time TEXT, -- '子', '丑', ..., '亥' 또는 NULL (모름)
  birth_calendar TEXT NOT NULL DEFAULT 'solar' CHECK (birth_calendar IN ('solar', 'lunar')),

  -- 기본 정보
  height_cm SMALLINT,
  job_category TEXT,
  job_title TEXT,
  location_city TEXT,
  location_district TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  bio TEXT CHECK (char_length(bio) <= 500),

  -- 선호도
  drinking TEXT CHECK (drinking IN ('none', 'sometimes', 'often')),
  smoking TEXT CHECK (smoking IN ('none', 'sometimes', 'often')),
  religion TEXT,
  mbti TEXT CHECK (char_length(mbti) = 4),

  -- 매칭 설정
  preferred_gender TEXT NOT NULL CHECK (preferred_gender IN ('male', 'female', 'all')),
  preferred_age_min SMALLINT DEFAULT 20,
  preferred_age_max SMALLINT DEFAULT 40,
  preferred_distance_km SMALLINT DEFAULT 50,
  prefer_saju_match BOOLEAN DEFAULT true,

  -- 상태
  is_profile_complete BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  last_active_at TIMESTAMPTZ DEFAULT now(),

  -- 구독
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'vip')),
  subscription_expires_at TIMESTAMPTZ,

  -- 메타
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE INDEX idx_profiles_gender ON profiles(gender);
CREATE INDEX idx_profiles_location ON profiles(location_city, location_district);
CREATE INDEX idx_profiles_active ON profiles(is_active, last_active_at DESC);
CREATE INDEX idx_profiles_birth_date ON profiles(birth_date);
CREATE INDEX idx_profiles_geo ON profiles USING gist (
  ll_to_earth(latitude, longitude)
) WHERE latitude IS NOT NULL;
```

#### profile_photos
```sql
CREATE TABLE public.profile_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  display_order SMALLINT NOT NULL DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,
  width SMALLINT,
  height SMALLINT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_photos_user ON profile_photos(user_id, display_order);

-- 사용자당 최대 6장 제한
CREATE OR REPLACE FUNCTION check_photo_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM profile_photos WHERE user_id = NEW.user_id) >= 6 THEN
    RAISE EXCEPTION 'Maximum 6 photos per user';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_photo_limit
  BEFORE INSERT ON profile_photos
  FOR EACH ROW EXECUTE FUNCTION check_photo_limit();
```

#### saju_profiles (사주 분석 결과)
```sql
CREATE TABLE public.saju_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,

  -- 사주 원국 (천간/지지)
  year_heavenly TEXT NOT NULL,   -- 연간 (甲~癸)
  year_earthly TEXT NOT NULL,    -- 연지 (子~亥)
  month_heavenly TEXT NOT NULL,  -- 월간
  month_earthly TEXT NOT NULL,   -- 월지
  day_heavenly TEXT NOT NULL,    -- 일간 ★핵심★
  day_earthly TEXT NOT NULL,     -- 일지
  hour_heavenly TEXT,            -- 시간 (NULL if unknown)
  hour_earthly TEXT,             -- 시지

  -- 오행 분포 (0-100 비율)
  wood_ratio SMALLINT NOT NULL DEFAULT 0,
  fire_ratio SMALLINT NOT NULL DEFAULT 0,
  earth_ratio SMALLINT NOT NULL DEFAULT 0,
  metal_ratio SMALLINT NOT NULL DEFAULT 0,
  water_ratio SMALLINT NOT NULL DEFAULT 0,

  -- AI 분석 결과
  personality_summary TEXT,         -- 성격 요약 (자연어)
  love_style TEXT,                  -- 연애 스타일
  personality_keywords TEXT[],      -- 성격 키워드 배열
  strengths TEXT[],                 -- 강점
  weaknesses TEXT[],                -- 약점

  -- 일간 유형
  day_master_type TEXT NOT NULL,    -- 예: 'fire_yang' (丙)
  day_master_element TEXT NOT NULL, -- 예: 'fire'

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_saju_user ON saju_profiles(user_id);
CREATE INDEX idx_saju_day_master ON saju_profiles(day_master_element);
```

#### matches (매칭)
```sql
CREATE TYPE match_action AS ENUM ('like', 'pass', 'super_like');
CREATE TYPE match_status AS ENUM ('pending', 'matched', 'unmatched');

CREATE TABLE public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action match_action NOT NULL,
  compatibility_score SMALLINT, -- 0-100
  compatibility_summary TEXT,
  status match_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_match UNIQUE (user_id, target_id),
  CONSTRAINT no_self_match CHECK (user_id != target_id)
);

CREATE INDEX idx_matches_user ON matches(user_id, created_at DESC);
CREATE INDEX idx_matches_target ON matches(target_id, action);
CREATE INDEX idx_matches_status ON matches(status) WHERE status = 'matched';

-- 상호 좋아요 시 자동 매칭 성사
CREATE OR REPLACE FUNCTION check_mutual_match()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action IN ('like', 'super_like') THEN
    -- 상대방도 나를 좋아했는지 확인
    IF EXISTS (
      SELECT 1 FROM matches
      WHERE user_id = NEW.target_id
        AND target_id = NEW.user_id
        AND action IN ('like', 'super_like')
        AND status = 'pending'
    ) THEN
      -- 양쪽 모두 matched로 업데이트
      UPDATE matches SET status = 'matched'
      WHERE (user_id = NEW.target_id AND target_id = NEW.user_id)
         OR (user_id = NEW.user_id AND target_id = NEW.target_id);
      NEW.status := 'matched';

      -- 채팅방 자동 생성
      INSERT INTO chat_rooms (user1_id, user2_id, match_id)
      VALUES (
        LEAST(NEW.user_id, NEW.target_id),
        GREATEST(NEW.user_id, NEW.target_id),
        NEW.id
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_match_insert
  BEFORE INSERT ON matches
  FOR EACH ROW EXECUTE FUNCTION check_mutual_match();
```

#### daily_recommendations (일일 추천)
```sql
CREATE TABLE public.daily_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recommended_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  compatibility_score SMALLINT,
  reason TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  is_seen BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_daily_rec UNIQUE (user_id, recommended_id, date)
);

CREATE INDEX idx_daily_rec_user_date ON daily_recommendations(user_id, date DESC);
```

#### chat_rooms & messages
```sql
CREATE TABLE public.chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matches(id),
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_chat_room UNIQUE (user1_id, user2_id),
  CONSTRAINT ordered_users CHECK (user1_id < user2_id)
);

CREATE INDEX idx_chatrooms_users ON chat_rooms(user1_id, user2_id);
CREATE INDEX idx_chatrooms_last_msg ON chat_rooms(last_message_at DESC) WHERE is_active = true;

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 2000),
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'saju_icebreaker', 'system')),
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_room ON messages(room_id, created_at DESC);
CREATE INDEX idx_messages_unread ON messages(room_id, is_read) WHERE is_read = false;

-- 마지막 메시지 자동 업데이트
CREATE OR REPLACE FUNCTION update_chat_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms
  SET last_message_at = NEW.created_at,
      last_message_preview = LEFT(NEW.content, 100)
  WHERE id = NEW.room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_insert
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_room_last_message();
```

#### blocks & reports
```sql
CREATE TABLE public.blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id)
);

CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id),
  reported_id UUID NOT NULL REFERENCES profiles(id),
  reason TEXT NOT NULL CHECK (reason IN (
    'fake_profile', 'inappropriate_photo', 'harassment',
    'spam', 'underage', 'scam', 'other'
  )),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks(blocked_id);
CREATE INDEX idx_reports_status ON reports(status) WHERE status = 'pending';
```

#### subscriptions (RevenueCat webhook 동기화)
```sql
CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rc_customer_id TEXT NOT NULL, -- RevenueCat customer ID
  product_id TEXT NOT NULL,     -- 'premium_monthly', 'vip_monthly' 등
  tier TEXT NOT NULL CHECK (tier IN ('premium', 'vip')),
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled', 'billing_retry')),
  starts_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_trial BOOLEAN DEFAULT false,
  store TEXT CHECK (store IN ('app_store', 'play_store')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_rc ON subscriptions(rc_customer_id);
CREATE INDEX idx_subscriptions_active ON subscriptions(user_id, status) WHERE status = 'active';
```

---

## 3. Row Level Security (RLS)

### 원칙
```
1. 모든 테이블에 RLS 활성화
2. 기본적으로 모든 접근 차단 (DENY ALL)
3. 명시적으로 허용하는 정책만 추가
4. SECURITY DEFINER 함수는 최소한으로 사용
5. 민감한 정보(생년월일시)는 직접 노출 금지
```

### RLS 정책

#### profiles
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 자신의 프로필 읽기/수정
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 활성 사용자의 공개 프로필 읽기 (차단한/된 사용자 제외)
CREATE POLICY "Users can read active profiles"
  ON profiles FOR SELECT
  USING (
    is_active = true
    AND is_profile_complete = true
    AND id != auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM blocks
      WHERE (blocker_id = auth.uid() AND blocked_id = profiles.id)
         OR (blocker_id = profiles.id AND blocked_id = auth.uid())
    )
  );

-- 프로필 생성 (가입 시)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

#### profile_photos
```sql
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;

-- 자신의 사진 CRUD
CREATE POLICY "Users can manage own photos"
  ON profile_photos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 다른 사용자의 사진 읽기 (차단 제외)
CREATE POLICY "Users can view others photos"
  ON profile_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = profile_photos.user_id
        AND profiles.is_active = true
        AND NOT EXISTS (
          SELECT 1 FROM blocks
          WHERE (blocker_id = auth.uid() AND blocked_id = profiles.id)
             OR (blocker_id = profiles.id AND blocked_id = auth.uid())
        )
    )
  );
```

#### saju_profiles
```sql
ALTER TABLE saju_profiles ENABLE ROW LEVEL SECURITY;

-- 자신의 사주 프로필 읽기/수정
CREATE POLICY "Users can read own saju"
  ON saju_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- 다른 사용자의 사주는 제한된 정보만 (뷰를 통해)
-- 직접 접근은 차단, Edge Function에서 필요한 정보만 제공
CREATE POLICY "No direct access to others saju"
  ON saju_profiles FOR SELECT
  USING (auth.uid() = user_id);
```

#### matches
```sql
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- 자신이 보낸/받은 매칭 읽기
CREATE POLICY "Users can read own matches"
  ON matches FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = target_id);

-- 좋아요/패스 보내기
CREATE POLICY "Users can create matches"
  ON matches FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 매칭 해제 (자신이 관련된 것만)
CREATE POLICY "Users can unmatch"
  ON matches FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = target_id)
  WITH CHECK (status = 'unmatched');
```

#### messages
```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 자신이 속한 채팅방의 메시지만 읽기
CREATE POLICY "Users can read messages in their rooms"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = messages.room_id
        AND (chat_rooms.user1_id = auth.uid() OR chat_rooms.user2_id = auth.uid())
        AND chat_rooms.is_active = true
    )
  );

-- 자신이 속한 채팅방에 메시지 전송
CREATE POLICY "Users can send messages to their rooms"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = messages.room_id
        AND (chat_rooms.user1_id = auth.uid() OR chat_rooms.user2_id = auth.uid())
        AND chat_rooms.is_active = true
    )
  );
```

---

## 4. Supabase Auth 통합

### 지원 로그인 방법
```
1. 카카오 (OAuth) — 한국 시장 필수
2. Apple (OAuth) — iOS 필수 (앱스토어 정책)
3. Google (OAuth) — Android 주요
4. 전화번호 (OTP) — 대안 수단
```

### 카카오 로그인 설정
```sql
-- Supabase Dashboard → Authentication → Providers → Kakao
-- Client ID: {KAKAO_REST_API_KEY}
-- Client Secret: {KAKAO_CLIENT_SECRET}
-- Redirect URL: {SUPABASE_URL}/auth/v1/callback
```

### Auth 후 프로필 자동 생성
```sql
-- auth.users에 새 사용자가 생기면 profiles에 자동 삽입
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname, gender, birth_date, preferred_gender)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nickname', 'User_' || LEFT(NEW.id::text, 8)),
    'male', -- 온보딩에서 업데이트
    '2000-01-01', -- 온보딩에서 업데이트
    'female' -- 온보딩에서 업데이트
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Auth 미들웨어 (Edge Function)
```typescript
// supabase/functions/_shared/supabase-client.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export function getSupabaseClient(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new Error('No authorization header');

  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: { Authorization: authHeader },
      },
    }
  );
}

export function getSupabaseAdmin() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
}
```

---

## 5. Realtime (채팅)

### 채팅 구독 설정
```sql
-- Realtime을 messages 테이블에 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 채팅방 수준의 필터링은 클라이언트에서 처리
-- RLS가 자동으로 보안을 담당
```

### 클라이언트 구독 패턴 (참고)
```dart
// Flutter에서의 구독 (참고용 — flutter-developer.md에서 상세)
final subscription = supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('room_id', roomId)
  .order('created_at')
  .listen((messages) {
    // 새 메시지 처리
  });
```

### Realtime 성능 최적화
```
1. 채팅방별 구독: room_id 필터로 불필요한 메시지 수신 방지
2. 연결 관리: 앱이 백그라운드일 때 구독 해제 → 포그라운드 복귀 시 재구독 + 누락 메시지 fetch
3. 메시지 배치: 빠른 연타 메시지는 클라이언트에서 debounce
4. Presence: 온라인/오프라인 상태 (선택적 — 리소스 고려)
```

---

## 6. Edge Functions

### 사주 분석 함수
```typescript
// supabase/functions/saju-analysis/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { getSupabaseClient } from '../_shared/supabase-client.ts';
import { calculateSaju } from '../_shared/saju-engine.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = getSupabaseClient(req);
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) throw new Error('Unauthorized');

    const { birth_date, birth_time, birth_calendar } = await req.json();

    // 1. 만세력 기반 사주 계산
    const sajuResult = calculateSaju({
      date: birth_date,
      time: birth_time,
      calendar: birth_calendar,
    });

    // 2. AI 성격 분석 (OpenAI or Anthropic)
    const personalityAnalysis = await analyzePersonality(sajuResult);

    // 3. DB 저장
    const { error: upsertError } = await supabase
      .from('saju_profiles')
      .upsert({
        user_id: user.id,
        ...sajuResult.pillars,
        ...sajuResult.elementRatios,
        ...personalityAnalysis,
        day_master_type: sajuResult.dayMasterType,
        day_master_element: sajuResult.dayMasterElement,
      });

    if (upsertError) throw upsertError;

    return new Response(
      JSON.stringify({
        success: true,
        saju: sajuResult,
        personality: personalityAnalysis,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### 궁합 계산 함수
```typescript
// supabase/functions/calculate-compatibility/index.ts
serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = getSupabaseClient(req);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { target_user_id } = await req.json();

    // 두 사용자의 사주 프로필 가져오기
    const [mySaju, targetSaju] = await Promise.all([
      supabase.from('saju_profiles').select('*').eq('user_id', user.id).single(),
      supabase.from('saju_profiles').select('*').eq('user_id', target_user_id).single(),
    ]);

    if (!mySaju.data || !targetSaju.data) {
      throw new Error('Saju profile not found');
    }

    // 궁합 계산
    const compatibility = calculateCompatibility(mySaju.data, targetSaju.data);

    return new Response(
      JSON.stringify({
        score: compatibility.score,
        summary: compatibility.summary,
        details: compatibility.details,
        strengths: compatibility.strengths,
        challenges: compatibility.challenges,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: corsHeaders }
    );
  }
});
```

### 일일 매칭 추천 함수 (Cron Job)
```typescript
// supabase/functions/daily-matches/index.ts
// pg_cron으로 매일 새벽 4시 실행
serve(async (req: Request) => {
  // Cron 인증 확인
  const authHeader = req.headers.get('Authorization');
  if (authHeader !== `Bearer ${Deno.env.get('CRON_SECRET')}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  const supabaseAdmin = getSupabaseAdmin();

  // 활성 사용자 목록
  const { data: users } = await supabaseAdmin
    .from('profiles')
    .select('id, preferred_gender, preferred_age_min, preferred_age_max, preferred_distance_km, latitude, longitude')
    .eq('is_active', true)
    .eq('is_profile_complete', true);

  for (const user of users || []) {
    // 이미 매칭/패스한 사용자 제외
    const { data: existingMatches } = await supabaseAdmin
      .from('matches')
      .select('target_id')
      .eq('user_id', user.id);

    const excludeIds = (existingMatches || []).map(m => m.target_id);
    excludeIds.push(user.id);

    // 차단 목록 제외
    const { data: blocks } = await supabaseAdmin
      .from('blocks')
      .select('blocked_id, blocker_id')
      .or(`blocker_id.eq.${user.id},blocked_id.eq.${user.id}`);

    const blockIds = (blocks || []).flatMap(b =>
      [b.blocked_id, b.blocker_id].filter(id => id !== user.id)
    );
    excludeIds.push(...blockIds);

    // 후보자 조회 + 궁합 점수 계산 + 상위 N명 추천
    // (실제 구현에서는 더 정교한 매칭 알고리즘 사용)
    const recommendations = await generateRecommendations(
      supabaseAdmin, user, excludeIds
    );

    // 추천 저장
    if (recommendations.length > 0) {
      await supabaseAdmin
        .from('daily_recommendations')
        .insert(recommendations.map(rec => ({
          user_id: user.id,
          recommended_id: rec.userId,
          compatibility_score: rec.score,
          reason: rec.reason,
          date: new Date().toISOString().split('T')[0],
        })));
    }
  }

  return new Response(JSON.stringify({ success: true }));
});
```

### RevenueCat Webhook 처리
```typescript
// supabase/functions/process-payment-webhook/index.ts
serve(async (req: Request) => {
  // RevenueCat webhook 인증
  const signature = req.headers.get('X-RevenueCat-Signature');
  // signature 검증 로직...

  const event = await req.json();
  const supabaseAdmin = getSupabaseAdmin();

  const rcCustomerId = event.app_user_id;
  const eventType = event.type;

  // user_id 조회 (RevenueCat customer ID → Supabase user ID)
  const { data: profile } = await supabaseAdmin
    .from('subscriptions')
    .select('user_id')
    .eq('rc_customer_id', rcCustomerId)
    .limit(1)
    .single();

  switch (eventType) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
      await supabaseAdmin.from('subscriptions').upsert({
        user_id: profile?.user_id || rcCustomerId,
        rc_customer_id: rcCustomerId,
        product_id: event.product_id,
        tier: event.product_id.includes('vip') ? 'vip' : 'premium',
        status: 'active',
        starts_at: event.purchase_date,
        expires_at: event.expiration_date,
        is_trial: event.is_trial_period === true,
        store: event.store,
      });

      // profiles 테이블 구독 상태 동기화
      if (profile?.user_id) {
        await supabaseAdmin.from('profiles').update({
          subscription_tier: event.product_id.includes('vip') ? 'vip' : 'premium',
          subscription_expires_at: event.expiration_date,
        }).eq('id', profile.user_id);
      }
      break;

    case 'CANCELLATION':
    case 'EXPIRATION':
      await supabaseAdmin.from('subscriptions').update({
        status: eventType === 'CANCELLATION' ? 'cancelled' : 'expired',
      }).eq('rc_customer_id', rcCustomerId).eq('status', 'active');

      if (profile?.user_id) {
        await supabaseAdmin.from('profiles').update({
          subscription_tier: 'free',
          subscription_expires_at: null,
        }).eq('id', profile.user_id);
      }
      break;
  }

  return new Response(JSON.stringify({ received: true }));
});
```

---

## 7. Storage (프로필 사진)

### 버킷 설정
```sql
-- 프로필 사진 버킷
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-photos',
  'profile-photos',
  true,  -- 공개 (프로필 사진은 URL로 접근)
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);
```

### Storage RLS
```sql
-- 자신의 폴더에만 업로드
CREATE POLICY "Users can upload own photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 자신의 사진 삭제
CREATE POLICY "Users can delete own photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 모든 사진 읽기 (공개)
CREATE POLICY "Anyone can view profile photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-photos');
```

### 이미지 변환 (Supabase Image Transformation)
```
프로필 목록 썸네일: ?width=200&height=250&resize=cover
프로필 상세: ?width=600&height=750&resize=cover
채팅 아바타: ?width=80&height=80&resize=cover
공유 카드용: ?width=400&height=400&resize=cover
```

---

## 8. 성능 최적화

### 인덱스 전략
```sql
-- 복합 인덱스 (자주 함께 조회되는 컬럼)
CREATE INDEX idx_profiles_matching ON profiles(
  gender, is_active, is_profile_complete, last_active_at DESC
) WHERE is_active = true AND is_profile_complete = true;

-- 부분 인덱스 (조건부 쿼리 최적화)
CREATE INDEX idx_matches_pending ON matches(target_id, action)
  WHERE status = 'pending' AND action IN ('like', 'super_like');

-- GiST 인덱스 (위치 기반 검색)
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

CREATE INDEX idx_profiles_location_geo ON profiles
  USING gist (ll_to_earth(latitude, longitude))
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
```

### 쿼리 최적화 패턴
```sql
-- 거리 기반 검색 (earthdistance 사용)
SELECT p.*,
  earth_distance(
    ll_to_earth(p.latitude, p.longitude),
    ll_to_earth($1, $2)  -- 사용자 위치
  ) / 1000 AS distance_km
FROM profiles p
WHERE p.is_active = true
  AND p.is_profile_complete = true
  AND earth_box(ll_to_earth($1, $2), $3 * 1000) @> ll_to_earth(p.latitude, p.longitude)
  AND earth_distance(ll_to_earth(p.latitude, p.longitude), ll_to_earth($1, $2)) < $3 * 1000
ORDER BY distance_km
LIMIT 50;

-- 페이지네이션 (cursor 기반, offset 금지)
SELECT * FROM messages
WHERE room_id = $1
  AND created_at < $2  -- cursor: 마지막 메시지 시각
ORDER BY created_at DESC
LIMIT 30;
```

### Connection Pooling
```
Supabase Dashboard → Settings → Database → Connection Pooling
Mode: Transaction (Edge Functions용)
Pool Size: 기본값 유지 (Pro 플랜 기준 adequate)
```

---

## 9. Migration 관리

### 마이그레이션 워크플로우
```bash
# 1. 로컬에서 스키마 변경
supabase db diff --use-migra -f add_new_feature

# 2. 마이그레이션 파일 확인/수정
# supabase/migrations/20260220000000_add_new_feature.sql

# 3. 로컬에서 테스트
supabase db reset  # 모든 마이그레이션 재실행

# 4. Staging에 배포
supabase db push --linked  # staging 프로젝트에 적용

# 5. 테스트 후 Production에 배포
supabase db push --linked  # production 프로젝트에 적용
```

### 마이그레이션 규칙
- 마이그레이션은 항상 **forward-only** (롤백 마이그레이션은 별도 파일)
- 데이터 손실 가능 DDL은 주의 (DROP COLUMN 등)
- 큰 테이블 변경 시 동시 인덱스 생성 (`CREATE INDEX CONCURRENTLY`)
- 시드 데이터는 `supabase/seed.sql`에 별도 관리

---

## 10. 환경 관리

### 환경 변수
```bash
# .env.local (로컬 개발)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Edge Function 환경 변수 (Supabase Dashboard에서 설정)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
REVENUECAT_WEBHOOK_SECRET=...
CRON_SECRET=...
KAKAO_REST_API_KEY=...
```

### 환경별 차이
| 설정 | Local | Staging | Production |
|-----|-------|---------|------------|
| Auth Providers | 이메일만 | 카카오+Apple | 카카오+Apple+Google+Phone |
| Edge Functions | 로컬 serve | 배포 | 배포 |
| Storage | 로컬 S3 호환 | Supabase Storage | Supabase Storage |
| Realtime | 활성 | 활성 | 활성 |
| 로깅 | 상세 | 상세 | 요약 |
| Rate Limiting | 비활성 | 활성 | 활성 |

### 보안 체크리스트
- [ ] RLS가 모든 테이블에 활성화되어 있는가?
- [ ] Service Role Key가 클라이언트에 노출되지 않는가?
- [ ] Edge Function에서 입력 유효성 검증을 하는가?
- [ ] CORS가 올바르게 설정되어 있는가?
- [ ] API rate limiting이 적용되어 있는가?
- [ ] SQL injection 방지가 되어 있는가? (parameterized queries)
- [ ] 민감 데이터(생년월일시) 접근이 제한되어 있는가?
- [ ] Storage 업로드 파일 타입/크기가 제한되어 있는가?
