# Matching Recommendation & Monetization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace mock matching data with real Supabase-backed recommendations: batch compatibility calculation, sectioned daily recommendations, photo reveal gating with daily free limits + point costs.

**Architecture:** Edge Functions handle server-side batch calculations (compatibility scoring, daily recommendation generation). Flutter client fetches sectioned results via Supabase queries and manages photo reveal / like limits through providers backed by `daily_usage` and `user_points` tables. All compatibility calculations are pure math (no Claude API, $0 cost).

**Tech Stack:** Supabase Edge Functions (Deno/TypeScript), PostgreSQL migrations, Flutter/Riverpod, existing `calculate-compatibility` formula.

**Design Doc:** `docs/plans/2026-03-06-matching-recommendation-monetization-design.md`

---

## Existing Infrastructure (DO NOT recreate)

These tables already exist in `20260224000001_initial_schema.sql`:
- `saju_compatibility` (궁합 캐시: user_id, partner_id, total_score, strengths[], challenges[])
- `daily_matches` (일일 추천: user_id, recommended_id, match_date, is_viewed)
- `likes` (좋아요: sender_id, receiver_id, status, is_premium)
- `matches` (매칭 성사)
- `user_points` (포인트 잔액: balance, total_earned, total_spent)
- `point_transactions` (포인트 거래 내역)
- `daily_usage` (일일 무료 사용: free_likes_used, free_accepts_used)

These RLS policies already exist:
- `profiles_select_own` (자기 프로필만)
- `saju_select_recommended` (daily_matches에 있는 상대 사주 조회)
- `compat_select` (자기 궁합만)
- `daily_matches_select` (자기 추천만)
- `likes_select/insert/update`
- `points_select`, `daily_usage_select`

---

## Task 1: DB Migration — Schema Enhancements

**Files:**
- Create: `supabase/migrations/20260306000001_matching_recommendation_schema.sql`

**Step 1: Write the migration SQL**

```sql
-- ============================================================
-- 매칭 추천 & 수익화 스키마 확장
-- ============================================================

-- 1. daily_matches에 섹션 + 사진 열람 컬럼 추가
ALTER TABLE public.daily_matches
  ADD COLUMN IF NOT EXISTS section text NOT NULL DEFAULT 'compatibility'
    CHECK (section IN ('destiny', 'compatibility', 'gwansang', 'new')),
  ADD COLUMN IF NOT EXISTS photo_revealed boolean NOT NULL DEFAULT false;

-- 2. daily_usage에 사진 열람 무료 사용량 추가
ALTER TABLE public.daily_usage
  ADD COLUMN IF NOT EXISTS free_photo_reveals_used int NOT NULL DEFAULT 0
    CHECK (free_photo_reveals_used BETWEEN 0 AND 3);

-- 3. user_actions 테이블 (사진 열람/좋아요 등 행위 추적)
CREATE TABLE IF NOT EXISTS public.user_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  target_user_id uuid NOT NULL REFERENCES public.profiles(id),
  action_type text NOT NULL CHECK (action_type IN ('photo_reveal', 'like', 'premium_like', 'pass')),
  points_spent int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_actions_user ON public.user_actions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_actions_target ON public.user_actions(target_user_id);

-- 4. RLS for user_actions
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_actions_select_own" ON public.user_actions
  FOR SELECT USING (user_id = public.current_profile_id());
CREATE POLICY "user_actions_insert_own" ON public.user_actions
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

-- 5. profiles SELECT 정책 확장 — 매칭 추천 대상 프로필 읽기 허용
-- (기존 profiles_select_own은 자기 것만 → 추천 대상도 읽을 수 있게)
CREATE POLICY "profiles_select_for_matching" ON public.profiles
  FOR SELECT USING (
    auth.uid() IS NOT NULL
    AND deleted_at IS NULL
  );

-- 6. daily_matches INSERT 정책 (서버가 생성하지만, service role은 RLS 무시하므로 생략 가능)
-- daily_usage INSERT/UPDATE 정책
CREATE POLICY "daily_usage_insert_own" ON public.daily_usage
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());
CREATE POLICY "daily_usage_update_own" ON public.daily_usage
  FOR UPDATE USING (user_id = public.current_profile_id());

-- 7. user_points INSERT/UPDATE 정책
CREATE POLICY "points_insert_own" ON public.user_points
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());
CREATE POLICY "points_update_own" ON public.user_points
  FOR UPDATE USING (user_id = public.current_profile_id());

-- 8. point_transactions INSERT 정책
CREATE POLICY "point_tx_insert_own" ON public.point_transactions
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

-- 9. saju_compatibility INSERT 정책 (클라이언트가 직접 insert하지 않지만, 안전장치)
CREATE POLICY "compat_insert" ON public.saju_compatibility
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

-- 10. 궁합 점수 인덱스 (추천 정렬용)
CREATE INDEX IF NOT EXISTS idx_compat_user_score
  ON public.saju_compatibility(user_id, total_score DESC);

-- 11. daily_matches 섹션별 인덱스
CREATE INDEX IF NOT EXISTS idx_daily_matches_section
  ON public.daily_matches(user_id, match_date, section);
```

**Step 2: Deploy migration**

```bash
cd /Users/noah/momo
supabase db push
```

Expected: Migration applied successfully.

**Step 3: Verify in Supabase Dashboard**

SQL Editor에서 확인:
```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'daily_matches' AND column_name IN ('section', 'photo_revealed');

SELECT column_name FROM information_schema.columns
WHERE table_name = 'daily_usage' AND column_name = 'free_photo_reveals_used';

SELECT table_name FROM information_schema.tables
WHERE table_name = 'user_actions';
```

**Step 4: Commit**

```bash
git add supabase/migrations/20260306000001_matching_recommendation_schema.sql
git commit -m "feat: 매칭 추천 스키마 확장 (섹션, 사진 열람, user_actions)"
```

---

## Task 2: Edge Function — batch-calculate-compatibility

기존 `calculate-compatibility`의 순수 수학 로직을 재사용하여, 한 유저와 모든 이성 유저의 궁합을 일괄 계산.

**Files:**
- Create: `supabase/functions/batch-calculate-compatibility/index.ts`
- Modify: `lib/core/constants/app_constants.dart` (SupabaseFunctions에 상수 추가)

**Step 1: Create the Edge Function**

```typescript
// supabase/functions/batch-calculate-compatibility/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ── 궁합 계산 로직 (calculate-compatibility에서 복사) ──
// 이 부분은 기존 calculate-compatibility/index.ts의 순수 수학 함수들을
// 그대로 가져옴 (calculateDayPillarScore, calculateFiveElementScore 등)
// → 공유 모듈로 분리하면 좋지만, Edge Function은 폴더 간 import 불가하므로 복사

const CHUNGAN_HAP: Record<string, string> = {
  '갑': '기', '기': '갑', '을': '경', '경': '을',
  '병': '신', '신': '병', '정': '임', '임': '정', '무': '계', '계': '무',
}

const JIJI_YUKHAP: Record<string, string> = {
  '자': '축', '축': '자', '인': '해', '해': '인',
  '묘': '술', '술': '묘', '진': '유', '유': '진',
  '사': '신', '신': '사', '오': '미', '미': '오',
}

const JIJI_CHUNG: Record<string, string> = {
  '자': '오', '오': '자', '축': '미', '미': '축',
  '인': '신', '신': '인', '묘': '유', '유': '묘',
  '진': '술', '술': '진', '사': '해', '해': '사',
}

const SAMHAP_GROUPS = [
  ['인', '오', '술'], ['사', '유', '축'],
  ['신', '자', '진'], ['해', '묘', '미'],
]

const JIJI_HYUNG: Record<string, string> = {
  '인': '사', '사': '인', '축': '술', '술': '축',
  '자': '묘', '묘': '자', '진': '진', '오': '오',
  '유': '유', '해': '해', '미': '축', '술': '미',
}

const ELEMENT_MAP: Record<string, string> = {
  '갑': 'wood', '을': 'wood', '병': 'fire', '정': 'fire',
  '무': 'earth', '기': 'earth', '경': 'metal', '신': 'metal',
  '임': 'water', '계': 'water',
  '자': 'water', '축': 'earth', '인': 'wood', '묘': 'wood',
  '진': 'earth', '사': 'fire', '오': 'fire', '미': 'earth',
  '신': 'metal', '유': 'metal', '술': 'earth', '해': 'water',
}

const SANGSAENG: Record<string, string> = {
  'wood': 'fire', 'fire': 'earth', 'earth': 'metal', 'metal': 'water', 'water': 'wood',
}

const SANGGEUK: Record<string, string> = {
  'wood': 'earth', 'earth': 'water', 'water': 'fire', 'fire': 'metal', 'metal': 'wood',
}

interface Pillar { stem: string; branch: string }
interface SajuData {
  yearPillar: Pillar; monthPillar: Pillar; dayPillar: Pillar;
  hourPillar?: Pillar | null;
  fiveElements: Record<string, number>; dominantElement: string;
}

function calculateDayPillarScore(my: Pillar, partner: Pillar): number {
  let score = 0
  if (CHUNGAN_HAP[my.stem] === partner.stem) score += 10
  if (JIJI_YUKHAP[my.branch] === partner.branch) score += 8
  const myBranches = [my.branch]; const partnerBranches = [partner.branch]
  for (const group of SAMHAP_GROUPS) {
    const combined = [...myBranches, ...partnerBranches]
    const matchCount = group.filter(b => combined.includes(b)).length
    if (matchCount >= 2) { score += 6; break }
  }
  if (JIJI_CHUNG[my.branch] === partner.branch) score -= 5
  if (JIJI_HYUNG[my.branch] === partner.branch) score -= 3
  return Math.max(0, Math.min(40, Math.round(score / 24 * 40 + 20)))
}

function calculateFiveElementScore(myEl: Record<string, number>, partnerEl: Record<string, number>): number {
  let score = 0
  const elements = ['wood', 'fire', 'earth', 'metal', 'water']
  for (const el of elements) {
    const myVal = myEl[el] || 0; const partnerVal = partnerEl[el] || 0
    if (myVal > 0 && partnerVal > 0) {
      const target = SANGSAENG[el]
      if (target && (partnerEl[target] || 0) > 0) score += 8
    }
  }
  let geukPenalty = 0
  for (const el of elements) {
    if ((myEl[el] || 0) > 0) {
      const target = SANGGEUK[el]
      if (target && (partnerEl[target] || 0) > 0) geukPenalty += 2
    }
  }
  score = Math.max(0, score - Math.min(geukPenalty, 8))
  return Math.max(0, Math.min(35, Math.round(score / 40 * 35 + 10)))
}

function calculateOtherPillarsScore(my: SajuData, partner: SajuData): number {
  let score = 0
  const pairs: [Pillar, Pillar][] = [
    [my.yearPillar, partner.yearPillar],
    [my.monthPillar, partner.monthPillar],
  ]
  if (my.hourPillar && partner.hourPillar) {
    pairs.push([my.hourPillar, partner.hourPillar])
  }
  for (const [a, b] of pairs) {
    if (CHUNGAN_HAP[a.stem] === b.stem) score += 3
    if (JIJI_YUKHAP[a.branch] === b.branch) score += 2
    if (JIJI_CHUNG[a.branch] === b.branch) score -= 2
  }
  return Math.max(0, Math.min(20, Math.round(score / 15 * 20 + 10)))
}

function calculateCompatibility(my: SajuData, partner: SajuData) {
  const dayScore = calculateDayPillarScore(my.dayPillar, partner.dayPillar)
  const fiveScore = calculateFiveElementScore(my.fiveElements, partner.fiveElements)
  const otherScore = calculateOtherPillarsScore(my, partner)
  const total = Math.max(0, Math.min(100, dayScore + fiveScore + otherScore + 5))

  // 간단 분석 텍스트 생성
  const strengths: string[] = []
  const challenges: string[] = []

  if (dayScore >= 28) strengths.push('일주의 조화가 뛰어나 깊은 교감이 가능해요')
  if (fiveScore >= 25) strengths.push('오행의 균형이 좋아 서로를 보완해줘요')
  if (dayScore < 15) challenges.push('일주 기운의 차이가 커서 이해와 노력이 필요해요')
  if (fiveScore < 12) challenges.push('오행의 충돌이 있어 조율이 필요해요')

  if (strengths.length === 0) strengths.push('서로 다른 점이 매력이 될 수 있어요')
  if (challenges.length === 0) challenges.push('큰 갈등 요소 없이 편안한 관계가 가능해요')

  return {
    total_score: total,
    five_element_score: fiveScore,
    day_pillar_score: dayScore,
    strengths,
    challenges,
    overall_analysis: total >= 80
      ? '운명적인 인연이에요! 서로의 사주가 아름다운 조화를 이루고 있어요.'
      : total >= 60
      ? '좋은 인연이에요. 서로의 기운이 잘 어울려요.'
      : total >= 40
      ? '노력하면 좋은 관계를 만들 수 있어요.'
      : '서로 다른 점이 많지만, 그만큼 배울 점도 많아요.',
    advice: '서로의 다른 점을 인정하고 존중하면 더 좋은 관계로 발전할 수 있어요.',
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { userId } = await req.json()
    if (!userId) {
      return new Response(JSON.stringify({ error: 'userId required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. 내 사주 조회
    const { data: mySaju } = await supabase
      .from('saju_profiles')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (!mySaju) {
      return new Response(JSON.stringify({ error: 'saju not found', calculated: 0 }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. 내 성별 조회
    const { data: myProfile } = await supabase
      .from('profiles')
      .select('gender')
      .eq('id', userId)
      .single()

    const oppositeGender = myProfile?.gender === 'male' ? 'female' : 'male'

    // 3. 이성 유저 중 사주 완료된 사람 전부 조회
    const { data: candidates } = await supabase
      .from('profiles')
      .select('id, saju_profiles!inner(year_pillar, month_pillar, day_pillar, hour_pillar, five_elements, dominant_element)')
      .eq('gender', oppositeGender)
      .not('deleted_at', 'is', null) // deleted_at IS NULL (active only)
      .is('deleted_at', null)

    if (!candidates || candidates.length === 0) {
      return new Response(JSON.stringify({ calculated: 0, total: 0 }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. 이미 계산된 궁합 조회 (중복 방지)
    const { data: existing } = await supabase
      .from('saju_compatibility')
      .select('partner_id')
      .eq('user_id', userId)

    const existingPartnerIds = new Set((existing || []).map((e: any) => e.partner_id))

    // 5. 새로운 궁합만 계산
    const mySajuData: SajuData = {
      yearPillar: mySaju.year_pillar,
      monthPillar: mySaju.month_pillar,
      dayPillar: mySaju.day_pillar,
      hourPillar: mySaju.hour_pillar,
      fiveElements: mySaju.five_elements,
      dominantElement: mySaju.dominant_element,
    }

    const newResults: any[] = []
    for (const candidate of candidates) {
      if (existingPartnerIds.has(candidate.id)) continue

      const saju = (candidate as any).saju_profiles
      if (!saju?.year_pillar || !saju?.month_pillar || !saju?.day_pillar) continue

      const partnerSajuData: SajuData = {
        yearPillar: saju.year_pillar,
        monthPillar: saju.month_pillar,
        dayPillar: saju.day_pillar,
        hourPillar: saju.hour_pillar,
        fiveElements: saju.five_elements,
        dominantElement: saju.dominant_element,
      }

      const result = calculateCompatibility(mySajuData, partnerSajuData)

      newResults.push({
        user_id: userId,
        partner_id: candidate.id,
        ...result,
        is_detailed: false,
        calculated_at: new Date().toISOString(),
      })
    }

    // 6. 배치 upsert (100개씩 chunk)
    let inserted = 0
    for (let i = 0; i < newResults.length; i += 100) {
      const chunk = newResults.slice(i, i + 100)
      const { error } = await supabase
        .from('saju_compatibility')
        .upsert(chunk, { onConflict: 'user_id,partner_id' })

      if (!error) inserted += chunk.length
    }

    return new Response(JSON.stringify({
      calculated: inserted,
      total: candidates.length,
      alreadyExisted: existingPartnerIds.size,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
```

**Step 2: Deploy**

```bash
supabase functions deploy batch-calculate-compatibility --no-verify-jwt
```

**Step 3: Test**

```bash
curl -X POST \
  'https://ejngitwtzecqbhbqfnsc.supabase.co/functions/v1/batch-calculate-compatibility' \
  -H 'Authorization: Bearer <USER_JWT>' \
  -H 'Content-Type: application/json' \
  -d '{"userId": "<PROFILE_ID>"}'
```

Expected: `{"calculated": N, "total": M, "alreadyExisted": 0}`

**Step 4: Commit**

```bash
git add supabase/functions/batch-calculate-compatibility/
git commit -m "feat: 배치 궁합 계산 Edge Function"
```

---

## Task 3: Edge Function — generate-daily-recommendations

사전 계산된 `saju_compatibility` 데이터 + 프로필 데이터를 기반으로 섹션별 일일 추천 생성.

**Files:**
- Create: `supabase/functions/generate-daily-recommendations/index.ts`

**Step 1: Create the Edge Function**

```typescript
// supabase/functions/generate-daily-recommendations/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { userId, isInitial } = await req.json()
    if (!userId) {
      return new Response(JSON.stringify({ error: 'userId required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const today = new Date().toISOString().split('T')[0]

    // 이미 오늘 추천이 있는지 확인 (initial이 아닐 때만)
    if (!isInitial) {
      const { data: existing } = await supabase
        .from('daily_matches')
        .select('id')
        .eq('user_id', userId)
        .eq('match_date', today)
        .limit(1)

      if (existing && existing.length > 0) {
        return new Response(JSON.stringify({ status: 'already_generated' }), {
          status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // 제외할 유저 목록 (이미 좋아요/차단/매칭된 유저)
    const [
      { data: likedUsers },
      { data: blockedUsers },
      { data: matchedUsers },
    ] = await Promise.all([
      supabase.from('likes').select('receiver_id').eq('sender_id', userId),
      supabase.from('blocks').select('blocked_id').eq('blocker_id', userId),
      supabase.from('matches').select('user1_id, user2_id')
        .or(`user1_id.eq.${userId},user2_id.eq.${userId}`)
        .is('unmatched_at', null),
    ])

    const excludeIds = new Set<string>()
    excludeIds.add(userId)
    for (const l of (likedUsers || [])) excludeIds.add(l.receiver_id)
    for (const b of (blockedUsers || [])) excludeIds.add(b.blocked_id)
    for (const m of (matchedUsers || [])) {
      excludeIds.add(m.user1_id === userId ? m.user2_id : m.user1_id)
    }

    // 궁합 점수 조회 (높은 순)
    const { data: compatibilities } = await supabase
      .from('saju_compatibility')
      .select('partner_id, total_score')
      .eq('user_id', userId)
      .order('total_score', { ascending: false })

    if (!compatibilities || compatibilities.length === 0) {
      return new Response(JSON.stringify({ status: 'no_compatibility_data', sections: {} }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 제외 대상 필터링
    const available = compatibilities.filter(c => !excludeIds.has(c.partner_id))

    // 섹션별 분배
    const sections: Record<string, { partner_id: string; score: number }[]> = {
      destiny: [],       // 85점 이상, 최대 5명
      compatibility: [], // 나머지 상위, 최대 15명
      gwansang: [],      // 관상 기반 (별도 로직), 최대 8명
      new: [],           // 최근 가입, 최대 10명
    }

    const usedIds = new Set<string>()

    // isInitial일 때는 상위 5명만 (최초 매칭)
    if (isInitial) {
      const top5 = available.slice(0, 5)
      for (const c of top5) {
        sections.destiny.push(c)
        usedIds.add(c.partner_id)
      }
    } else {
      // destiny: 85점 이상
      for (const c of available) {
        if (c.total_score >= 85 && sections.destiny.length < 5 && !usedIds.has(c.partner_id)) {
          sections.destiny.push(c)
          usedIds.add(c.partner_id)
        }
      }

      // compatibility: 나머지 상위
      for (const c of available) {
        if (sections.compatibility.length >= 15) break
        if (!usedIds.has(c.partner_id)) {
          sections.compatibility.push(c)
          usedIds.add(c.partner_id)
        }
      }

      // gwansang: 관상 데이터 있는 유저 (별도 조회)
      const remainingIds = available
        .filter(c => !usedIds.has(c.partner_id))
        .map(c => c.partner_id)
        .slice(0, 50) // 후보군 제한

      if (remainingIds.length > 0) {
        const { data: gwansangUsers } = await supabase
          .from('gwansang_profiles')
          .select('user_id')
          .in('user_id', remainingIds)
          .limit(8)

        for (const g of (gwansangUsers || [])) {
          const compat = available.find(c => c.partner_id === g.user_id)
          if (compat && !usedIds.has(g.user_id)) {
            sections.gwansang.push(compat)
            usedIds.add(g.user_id)
          }
        }
      }

      // new: 최근 가입 유저 (7일 이내)
      const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
      const newCandidateIds = available
        .filter(c => !usedIds.has(c.partner_id))
        .map(c => c.partner_id)
        .slice(0, 50)

      if (newCandidateIds.length > 0) {
        const { data: newUsers } = await supabase
          .from('profiles')
          .select('id')
          .in('id', newCandidateIds)
          .gte('created_at', weekAgo)
          .order('created_at', { ascending: false })
          .limit(10)

        for (const n of (newUsers || [])) {
          const compat = available.find(c => c.partner_id === n.id)
          if (compat && !usedIds.has(n.id)) {
            sections.new.push(compat)
            usedIds.add(n.id)
          }
        }
      }
    }

    // daily_matches에 INSERT
    const rows: any[] = []
    for (const [section, items] of Object.entries(sections)) {
      for (const item of items) {
        // 기존 saju_compatibility ID 조회
        rows.push({
          user_id: userId,
          recommended_id: item.partner_id,
          match_date: today,
          section,
          is_viewed: false,
          photo_revealed: false,
        })
      }
    }

    if (rows.length > 0) {
      // 기존 오늘 데이터 삭제 후 재생성 (isInitial 포함)
      await supabase
        .from('daily_matches')
        .delete()
        .eq('user_id', userId)
        .eq('match_date', today)

      await supabase.from('daily_matches').insert(rows)
    }

    // 결과 요약
    const summary: Record<string, number> = {}
    for (const [section, items] of Object.entries(sections)) {
      if (items.length > 0) summary[section] = items.length
    }

    return new Response(JSON.stringify({
      status: 'generated',
      total: rows.length,
      sections: summary,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
```

**Step 2: Deploy**

```bash
supabase functions deploy generate-daily-recommendations --no-verify-jwt
```

**Step 3: Commit**

```bash
git add supabase/functions/generate-daily-recommendations/
git commit -m "feat: 섹션별 일일 추천 생성 Edge Function"
```

---

## Task 4: Flutter Constants & Entities Update

**Files:**
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/features/points/domain/entities/point_entity.dart`
- Create: `lib/features/matching/domain/entities/daily_recommendation.dart`

**Step 1: Update AppLimits and SupabaseFunctions**

In `lib/core/constants/app_constants.dart`:

Add to `SupabaseFunctions`:
```dart
static const batchCalculateCompatibility = 'batch-calculate-compatibility';
static const generateDailyRecommendations = 'generate-daily-recommendations';
```

Update `AppLimits`:
```dart
// --- 사진 열람 ---
static const dailyFreePhotoRevealLimit = 3;
static const photoRevealCost = 30;

// --- 좋아요/수락 (디자인 문서 기준 업데이트) ---
static const likeCost = 50;          // 기존 100 → 50
static const premiumLikeCost = 100;  // 기존 300 → 100
```

**Step 2: Add photo reveal to DailyUsage entity**

In `lib/features/points/domain/entities/point_entity.dart`, add to `DailyUsage`:
```dart
final int freePhotoRevealsUsed;

bool get hasFreePhotoReveals =>
    freePhotoRevealsUsed < AppLimits.dailyFreePhotoRevealLimit;

int get remainingFreePhotoReveals =>
    AppLimits.dailyFreePhotoRevealLimit - freePhotoRevealsUsed;
```

**Step 3: Create DailyRecommendation entity**

File: `lib/features/matching/domain/entities/daily_recommendation.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'match_profile.dart';

part 'daily_recommendation.freezed.dart';

/// 섹션별 일일 추천 결과
@freezed
class SectionedRecommendations with _$SectionedRecommendations {
  const factory SectionedRecommendations({
    @Default([]) List<MatchProfile> destinyMatches,
    @Default([]) List<MatchProfile> compatibilityMatches,
    @Default([]) List<MatchProfile> gwansangMatches,
    @Default([]) List<MatchProfile> newUserMatches,
  }) = _SectionedRecommendations;

  const SectionedRecommendations._();

  /// 전체 추천 수
  int get totalCount =>
      destinyMatches.length +
      compatibilityMatches.length +
      gwansangMatches.length +
      newUserMatches.length;

  /// 비어있지 않은 섹션만
  bool get hasDestiny => destinyMatches.isNotEmpty;
  bool get hasCompatibility => compatibilityMatches.isNotEmpty;
  bool get hasGwansang => gwansangMatches.isNotEmpty;
  bool get hasNewUsers => newUserMatches.isNotEmpty;
}
```

**Step 4: Run code generation**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit**

```bash
git add lib/core/constants/app_constants.dart \
        lib/features/points/domain/entities/point_entity.dart \
        lib/features/matching/domain/entities/daily_recommendation.dart \
        lib/features/matching/domain/entities/daily_recommendation.freezed.dart
git commit -m "feat: 매칭 추천 엔티티 + 상수 업데이트 (사진 열람, 포인트 비용)"
```

---

## Task 5: Flutter Matching Datasource — Real Supabase Queries

**Files:**
- Create: `lib/features/matching/data/datasources/matching_remote_datasource.dart`

**Step 1: Create the datasource**

```dart
/// 매칭 Remote Datasource — Supabase 실연동
///
/// Edge Function 호출 + DB 직접 쿼리를 담당.
/// Repository에서 호출하며, domain layer에 의존하지 않음.
library;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';

class MatchingRemoteDatasource {
  const MatchingRemoteDatasource({required SupabaseHelper supabaseHelper})
      : _supabaseHelper = supabaseHelper;

  final SupabaseHelper _supabaseHelper;

  /// 배치 궁합 계산 트리거
  Future<Map<String, dynamic>> triggerBatchCompatibility(String userId) async {
    final response = await _supabaseHelper.invokeFunction(
      SupabaseFunctions.batchCalculateCompatibility,
      body: {'userId': userId},
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  /// 일일 추천 생성 트리거
  Future<Map<String, dynamic>> triggerDailyRecommendations(
    String userId, {
    bool isInitial = false,
  }) async {
    final response = await _supabaseHelper.invokeFunction(
      SupabaseFunctions.generateDailyRecommendations,
      body: {'userId': userId, 'isInitial': isInitial},
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  /// 오늘의 추천 목록 조회 (섹션별)
  ///
  /// daily_matches JOIN profiles + saju_profiles + gwansang_profiles
  Future<List<Map<String, dynamic>>> fetchDailyRecommendations(
    String userId,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final client = _supabaseHelper.client;

    final response = await client
        .from(SupabaseTables.dailyRecommendations)
        .select('''
          id, section, is_viewed, photo_revealed,
          recommended:profiles!recommended_id (
            id, name, birth_date, gender, profile_images, bio,
            height, location, occupation, dominant_element, character_type,
            saju_profiles (dominant_element),
            gwansang_profiles (animal_type, animal_modifier, traits)
          )
        ''')
        .eq('user_id', userId)
        .eq('match_date', today)
        .order('section');

    return List<Map<String, dynamic>>.from(response);
  }

  /// 궁합 점수 조회 (캐시에서)
  Future<Map<String, dynamic>?> fetchCompatibilityScore(
    String userId,
    String partnerId,
  ) async {
    final client = _supabaseHelper.client;
    final response = await client
        .from(SupabaseTables.sajuCompatibility)
        .select()
        .eq('user_id', userId)
        .eq('partner_id', partnerId)
        .maybeSingle();

    return response;
  }

  /// 사진 열람 기록
  Future<void> recordPhotoReveal(
    String userId,
    String targetUserId,
    int pointsSpent,
  ) async {
    final client = _supabaseHelper.client;

    // user_actions에 기록
    await client.from('user_actions').insert({
      'user_id': userId,
      'target_user_id': targetUserId,
      'action_type': 'photo_reveal',
      'points_spent': pointsSpent,
    });

    // daily_matches의 photo_revealed 업데이트
    final today = DateTime.now().toIso8601String().split('T')[0];
    await client
        .from(SupabaseTables.dailyRecommendations)
        .update({'photo_revealed': true})
        .eq('user_id', userId)
        .eq('recommended_id', targetUserId)
        .eq('match_date', today);
  }

  /// 좋아요 전송
  Future<void> sendLike(
    String senderId,
    String receiverId, {
    bool isPremium = false,
  }) async {
    final client = _supabaseHelper.client;
    await client.from(SupabaseTables.likes).upsert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'is_premium': isPremium,
      'status': 'pending',
    }, onConflict: 'sender_id,receiver_id');
  }

  /// 좋아요 수락
  Future<void> acceptLike(String likeId) async {
    final client = _supabaseHelper.client;
    await client.from(SupabaseTables.likes).update({
      'status': 'accepted',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', likeId);
  }

  /// 좋아요 거절
  Future<void> rejectLike(String likeId) async {
    final client = _supabaseHelper.client;
    await client.from(SupabaseTables.likes).update({
      'status': 'rejected',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', likeId);
  }

  /// 받은 좋아요 조회
  Future<List<Map<String, dynamic>>> fetchReceivedLikes(String userId) async {
    final client = _supabaseHelper.client;
    final response = await client
        .from(SupabaseTables.likes)
        .select('''
          *,
          sender:profiles!sender_id (
            id, name, birth_date, profile_images, bio,
            height, location, occupation, dominant_element, character_type,
            gwansang_profiles (animal_type, animal_modifier, traits)
          )
        ''')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('sent_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 보낸 좋아요 조회
  Future<List<Map<String, dynamic>>> fetchSentLikes(String userId) async {
    final client = _supabaseHelper.client;
    final response = await client
        .from(SupabaseTables.likes)
        .select('''
          *,
          receiver:profiles!receiver_id (
            id, name, birth_date, profile_images, bio,
            height, location, occupation, dominant_element, character_type,
            gwansang_profiles (animal_type, animal_modifier, traits)
          )
        ''')
        .eq('sender_id', userId)
        .order('sent_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 일일 무료 사용량 조회/생성
  Future<Map<String, dynamic>> fetchOrCreateDailyUsage(String userId) async {
    final client = _supabaseHelper.client;
    final today = DateTime.now().toIso8601String().split('T')[0];

    var response = await client
        .from(SupabaseTables.dailyUsage)
        .select()
        .eq('user_id', userId)
        .eq('usage_date', today)
        .maybeSingle();

    if (response == null) {
      response = await client
          .from(SupabaseTables.dailyUsage)
          .insert({
            'user_id': userId,
            'usage_date': today,
            'free_likes_used': 0,
            'free_accepts_used': 0,
            'free_photo_reveals_used': 0,
          })
          .select()
          .single();
    }

    return Map<String, dynamic>.from(response);
  }

  /// 일일 무료 사용량 업데이트
  Future<void> incrementDailyUsage(
    String usageId, {
    bool like = false,
    bool accept = false,
    bool photoReveal = false,
  }) async {
    final client = _supabaseHelper.client;
    final updates = <String, dynamic>{};

    // Supabase doesn't support increment directly, need RPC or read-update
    // For simplicity, fetch current and increment
    final current = await client
        .from(SupabaseTables.dailyUsage)
        .select()
        .eq('id', usageId)
        .single();

    if (like) updates['free_likes_used'] = (current['free_likes_used'] as int) + 1;
    if (accept) updates['free_accepts_used'] = (current['free_accepts_used'] as int) + 1;
    if (photoReveal) updates['free_photo_reveals_used'] = (current['free_photo_reveals_used'] as int) + 1;

    if (updates.isNotEmpty) {
      await client
          .from(SupabaseTables.dailyUsage)
          .update(updates)
          .eq('id', usageId);
    }
  }

  /// 포인트 차감
  Future<void> spendPoints(String userId, int amount, String type, {String? targetId}) async {
    final client = _supabaseHelper.client;

    // user_points 업데이트
    final current = await client
        .from(SupabaseTables.userPoints)
        .select()
        .eq('user_id', userId)
        .single();

    await client.from(SupabaseTables.userPoints).update({
      'balance': (current['balance'] as int) - amount,
      'total_spent': (current['total_spent'] as int) + amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    // point_transactions 기록
    await client.from(SupabaseTables.pointTransactions).insert({
      'user_id': userId,
      'type': type,
      'amount': -amount,
      'target_id': targetId,
    });
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/matching/data/datasources/matching_remote_datasource.dart
git commit -m "feat: 매칭 Remote Datasource 실구현 (Supabase 직접 쿼리)"
```

---

## Task 6: Flutter Repository — Replace Mock with Real

**Files:**
- Modify: `lib/features/matching/data/repositories/matching_repository_impl.dart`
- Modify: `lib/features/matching/domain/repositories/matching_repository.dart`
- Modify: `lib/core/di/providers.dart`

**Step 1: Update repository interface**

Add to `MatchingRepository`:
```dart
/// 배치 궁합 계산 트리거
Future<void> triggerBatchCompatibility();

/// 일일 추천 생성 (필요 시)
Future<void> ensureDailyRecommendations({bool isInitial = false});

/// 섹션별 일일 추천 조회
Future<SectionedRecommendations> getSectionedRecommendations();

/// 사진 열람
Future<void> revealPhoto(String targetUserId, {required int pointsSpent});
```

**Step 2: Rewrite MatchingRepositoryImpl**

Replace mock implementations with real calls through `MatchingRemoteDatasource`. Keep mock data as fallback only when datasource throws.

Key changes:
- `getDailyRecommendations()` → calls `fetchDailyRecommendations` from datasource
- `getSectionedRecommendations()` → fetches and groups by section
- `sendLike()` → calls real `sendLike` on datasource
- `getReceivedLikes()` → real query
- `getSentLikes()` → real query
- `revealPhoto()` → records action + updates daily_matches
- `getCompatibilityPreview()` → first checks cache in `saju_compatibility`, falls back to Edge Function

**Step 3: Update DI providers**

In `lib/core/di/providers.dart`, add:
```dart
@riverpod
MatchingRemoteDatasource matchingRemoteDatasource(Ref ref) {
  return MatchingRemoteDatasource(
    supabaseHelper: ref.watch(supabaseHelperProvider),
  );
}
```

Update `matchingRepositoryProvider` to inject `MatchingRemoteDatasource`.

**Step 4: Run code generation**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit**

```bash
git add lib/features/matching/ lib/core/di/providers.dart
git commit -m "feat: 매칭 Repository 실구현 (Mock → Supabase)"
```

---

## Task 7: Flutter Providers — Sectioned Recommendations + Photo Reveal

**Files:**
- Modify: `lib/features/matching/presentation/providers/matching_provider.dart`
- Modify: `lib/features/points/presentation/providers/points_provider.dart`

**Step 1: Add sectioned recommendations provider**

```dart
@riverpod
class SectionedRecommendationsNotifier extends _$SectionedRecommendationsNotifier {
  @override
  Future<SectionedRecommendations> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    await repo.ensureDailyRecommendations();
    return repo.getSectionedRecommendations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(matchingRepositoryProvider);
      await repo.ensureDailyRecommendations();
      return repo.getSectionedRecommendations();
    });
  }
}
```

**Step 2: Add photo reveal provider**

```dart
@riverpod
class PhotoRevealNotifier extends _$PhotoRevealNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 사진 열람 (무료 한도 → 포인트 차감)
  Future<bool> revealPhoto(String targetUserId) async {
    final dailyUsage = ref.read(dailyUsageNotifierProvider);
    final userPoints = ref.read(userPointsNotifierProvider);

    // 1. 무료 한도 확인
    if (dailyUsage.hasFreePhotoReveals) {
      state = const AsyncLoading();
      try {
        await ref.read(matchingRepositoryProvider).revealPhoto(
          targetUserId,
          pointsSpent: 0,
        );
        ref.read(dailyUsageNotifierProvider.notifier).useFreePhotoReveal();
        state = const AsyncData(null);
        return true;
      } catch (e, st) {
        state = AsyncError(e, st);
        return false;
      }
    }

    // 2. 포인트 확인
    const cost = AppLimits.photoRevealCost;
    if (!userPoints.canAfford(cost)) {
      state = AsyncError('포인트가 부족해요 (${cost}P 필요)', StackTrace.current);
      return false;
    }

    // 3. 포인트 차감 + 열람
    state = const AsyncLoading();
    try {
      await ref.read(matchingRepositoryProvider).revealPhoto(
        targetUserId,
        pointsSpent: cost,
      );
      ref.read(userPointsNotifierProvider.notifier).spend(cost);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
```

**Step 3: Update DailyUsageNotifier**

Add `useFreePhotoReveal()` method to `DailyUsageNotifier`.

**Step 4: Run code generation**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit**

```bash
git add lib/features/matching/presentation/providers/ \
        lib/features/points/presentation/providers/
git commit -m "feat: 섹션별 추천 + 사진 열람 Provider"
```

---

## Task 8: Flutter Home UI — Multi-Section Recommendations

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/features/home/presentation/widgets/recommendation_section.dart`
- Create: `lib/features/home/presentation/widgets/destiny_section.dart`
- Create: `lib/features/home/presentation/widgets/new_users_section.dart`
- Modify: `lib/features/home/presentation/widgets/gwansang_match_section.dart`
- Modify: `lib/features/home/presentation/constants/home_layout.dart`

**Step 1: Update HomeLayout constants**

```dart
// 섹션별 최대 아이템 수
static const destinyMaxItems = 5;      // 운명 매칭
static const compatMaxItems = 6;       // 궁합 추천 (홈 그리드: 2열 × 3행)
static const gwansangMaxItems = 4;     // 관상 매칭
static const newUsersMaxItems = 4;     // 새로운 인연
```

**Step 2: Create DestinySection widget**

"오늘의 운명 매칭 (85%+)" — 수평 스크롤 카드, 프리미엄 느낌 (금색 테두리).

```dart
class DestinySection extends ConsumerWidget {
  // SectionedRecommendationsNotifier에서 destinyMatches를 가져옴
  // 비어있으면 위젯 자체를 반환하지 않음 (SizedBox.shrink)
  // SajuMatchCard(isPremium: true, showCharacterInstead: true) 사용
  // 수평 스크롤 ListView
}
```

**Step 3: Update RecommendationSection**

기존 `dailyRecommendationsProvider` → `sectionedRecommendationsNotifierProvider`의 `compatibilityMatches` 사용.

**Step 4: Update GwansangMatchSection**

기존 하드코딩된 관상 매칭 → `sectionedRecommendationsNotifierProvider`의 `gwansangMatches` 사용.

**Step 5: Create NewUsersSection widget**

"새로 가입한 인연" — 2열 그리드, 기본 스타일.

**Step 6: Update HomePage**

섹션 순서 변경:
```
1. GreetingSection (인사)
2. DailyFortuneSection (연애운)
3. DestinySection (운명 매칭 85%+) — 비어있으면 숨김
4. RecommendationSection (궁합 추천)
5. ReceivedLikesSection (받은 좋아요)
6. GwansangMatchSection (관상 매칭) — 비어있으면 숨김
7. NewUsersSection (새 인연) — 비어있으면 숨김
```

각 섹션은 데이터 0명이면 `SizedBox.shrink()` 반환.

**Step 7: Verify build**

```bash
fvm flutter analyze lib/
```

**Step 8: Commit**

```bash
git add lib/features/home/
git commit -m "feat: 홈 멀티섹션 추천 UI (운명/궁합/관상/신규)"
```

---

## Task 9: Flutter Photo Reveal UI — Profile Detail Page

**Files:**
- Modify: `lib/features/matching/presentation/pages/profile_detail_page.dart`

**Step 1: Add photo reveal button to Hero section**

현재 ProfileDetailPage의 Hero 섹션은 사진을 블러 처리하고 캐릭터를 오버레이합니다.
사진 열람 버튼을 추가:

```dart
// 사진 블러 오버레이 위에 버튼
if (!isPhotoRevealed)
  Positioned(
    bottom: 16,
    left: 0, right: 0,
    child: Center(
      child: _PhotoRevealButton(
        remainingFree: dailyUsage.remainingFreePhotoReveals,
        cost: AppLimits.photoRevealCost,
        onTap: () => _handlePhotoReveal(context, ref, profile),
      ),
    ),
  ),
```

**Step 2: Implement photo reveal state**

```dart
// isPhotoRevealed 상태 관리:
// 1. daily_matches에서 photo_revealed 확인
// 2. 열람 성공 시 로컬 상태 + 서버 동기화
// 3. 열람 후 블러 애니메이션으로 해제 (sigma 25 → 0, 500ms)
```

**Step 3: Photo reveal button design**

```
┌─────────────────────────────┐
│  🔓 사진 보기 (무료 2회 남음)  │  ← 무료 있을 때
│  🔓 사진 보기 (30P)           │  ← 무료 소진 시
└─────────────────────────────┘
```

버튼 스타일: 반투명 배경 + 아이콘 + 텍스트, 부드러운 rounded corners.

**Step 4: Verify build**

```bash
fvm flutter analyze lib/
```

**Step 5: Commit**

```bash
git add lib/features/matching/presentation/pages/profile_detail_page.dart
git commit -m "feat: 프로필 상세 사진 열람 게이팅 UI"
```

---

## Task 10: Trigger Integration — Hook Batch Calc & Daily Recs

**Files:**
- Modify: `lib/features/saju/data/repositories/saju_repository_impl.dart`
- Modify: `lib/features/matching/presentation/providers/matching_provider.dart`

**Step 1: Trigger batch compatibility after saju analysis**

`SajuRepositoryImpl.analyzeSaju()` 완료 후 배치 궁합 계산을 비동기 트리거:

```dart
// analyzeSaju() 마지막에 추가 (non-blocking)
try {
  final matchingRepo = ref.read(matchingRepositoryProvider);
  matchingRepo.triggerBatchCompatibility(); // await 하지 않음
} catch (_) {
  // 실패해도 사주 분석 결과에는 영향 없음
}
```

**Step 2: Trigger daily recommendations on home load**

`SectionedRecommendationsNotifier.build()`에서 이미 `ensureDailyRecommendations()` 호출.
이 함수는 오늘 추천이 없을 때만 Edge Function 호출.

**Step 3: Commit**

```bash
git add lib/features/saju/ lib/features/matching/
git commit -m "feat: 사주 완료 → 배치 궁합, 홈 진입 → 일일 추천 트리거"
```

---

## Task 11: Post-Analysis Initial Matches — First 5

**Files:**
- Modify: `lib/features/matching/presentation/pages/post_analysis_match_list_page.dart`
- Modify: `lib/features/matching/presentation/providers/post_analysis_matches_provider.dart`

**Step 1: Update provider to use real data**

```dart
@riverpod
Future<List<MatchProfile>> postAnalysisMatches(Ref ref) async {
  final repo = ref.watch(matchingRepositoryProvider);

  // 최초 매칭: isInitial=true로 상위 5명만 생성
  await repo.ensureDailyRecommendations(isInitial: true);
  final sectioned = await repo.getSectionedRecommendations();

  // destiny 섹션에서 최대 5명
  return sectioned.destinyMatches.take(5).toList();
}
```

**Step 2: Commit**

```bash
git add lib/features/matching/presentation/
git commit -m "feat: 분석 후 최초 매칭 5명 실데이터"
```

---

## Task 12: Final Integration Test & Cleanup

**Step 1: Build verification**

```bash
fvm flutter analyze lib/
fvm flutter build ios --no-codesign --debug
```

**Step 2: Remove mock data**

`matching_repository_impl.dart`에서 `_mockProfiles`, `_mockStrengths`, `_mockChallenges`, `MockMatchingRepository` 등 mock 관련 코드 제거.

단, 개발 편의를 위해 `MockMatchingRepository` 클래스는 유지하되, DI에서 사용하지 않도록 변경.

**Step 3: Update CLAUDE.md**

- AppLimits 포인트 비용 변경 반영
- 사진 열람 규칙 추가
- Task master 업데이트

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: 매칭 추천 & 수익화 Phase 1 MVP 완성"
```

---

## Dependency Graph

```
Task 1 (DB Migration)
  ↓
Task 2 (Batch Compatibility EF) ── Task 3 (Daily Recs EF)   [parallel]
  ↓                                    ↓
Task 4 (Constants & Entities)          |
  ↓                                    |
Task 5 (Datasource)                    |
  ↓                                    |
Task 6 (Repository)  ←────────────────┘
  ↓
Task 7 (Providers)
  ↓
Task 8 (Home UI) ── Task 9 (Photo Reveal UI) ── Task 11 (Post-Analysis)  [parallel]
  ↓                    ↓                            ↓
Task 10 (Triggers)     |                            |
  ↓                    |                            |
Task 12 (Integration)  ←───────────────────────────┘
```

## Estimated Parallel Execution

- **Wave 1**: Task 1 (DB)
- **Wave 2**: Task 2 + Task 3 (Edge Functions, parallel)
- **Wave 3**: Task 4 → Task 5 → Task 6 (Data layer, sequential)
- **Wave 4**: Task 7 (Providers)
- **Wave 5**: Task 8 + Task 9 + Task 11 (UI, parallel)
- **Wave 6**: Task 10 + Task 12 (Integration)
