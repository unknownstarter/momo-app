-- ============================================================
-- 매칭 추천 스키마 확장
-- 섹션별 추천, 사진 열람, user_actions, RLS 보강
-- ============================================================

-- ============================================================
-- 1. daily_matches 테이블 확장
-- ============================================================

-- 섹션 컬럼: 추천 카드가 어느 섹션에 속하는지 구분
ALTER TABLE public.daily_matches
  ADD COLUMN IF NOT EXISTS section text NOT NULL DEFAULT 'compatibility'
  CHECK (section IN ('destiny', 'compatibility', 'gwansang', 'new'));

-- 사진 열람 여부
ALTER TABLE public.daily_matches
  ADD COLUMN IF NOT EXISTS photo_revealed boolean NOT NULL DEFAULT false;

-- ============================================================
-- 2. daily_usage 테이블 확장
-- ============================================================

-- 무료 사진 열람 횟수 (하루 3회 제한)
ALTER TABLE public.daily_usage
  ADD COLUMN IF NOT EXISTS free_photo_reveals_used int NOT NULL DEFAULT 0
  CHECK (free_photo_reveals_used BETWEEN 0 AND 3);

-- ============================================================
-- 3. user_actions 테이블 (NEW)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  target_user_id uuid NOT NULL REFERENCES public.profiles(id),
  action_type text NOT NULL CHECK (action_type IN ('photo_reveal', 'like', 'premium_like', 'pass')),
  points_spent int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_actions_user_created
  ON public.user_actions(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_actions_target
  ON public.user_actions(target_user_id);

-- ============================================================
-- 4. point_transactions type 제약 조건 확장 ('photo_reveal' 추가)
-- ============================================================

ALTER TABLE public.point_transactions DROP CONSTRAINT IF EXISTS point_transactions_type_check;
ALTER TABLE public.point_transactions ADD CONSTRAINT point_transactions_type_check
  CHECK (type IN (
    'purchase', 'like_sent', 'premium_like_sent', 'accept',
    'compatibility_report', 'character_skin', 'saju_report',
    'icebreaker', 'daily_reset_bonus', 'refund', 'photo_reveal'
  ));

-- ============================================================
-- 5. 인덱스 추가
-- ============================================================

-- 궁합 점수 내림차순 정렬 (추천 목록용)
CREATE INDEX IF NOT EXISTS idx_compatibility_user_score
  ON public.saju_compatibility(user_id, total_score DESC);

-- 섹션별 매칭 필터링
CREATE INDEX IF NOT EXISTS idx_daily_matches_user_date_section
  ON public.daily_matches(user_id, match_date, section);

-- ============================================================
-- 6. RLS 정책
-- ============================================================

-- 6a. user_actions: RLS 활성화 + 본인 것만 조회/입력
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_actions_select_own" ON public.user_actions
  FOR SELECT USING (user_id = public.current_profile_id());

CREATE POLICY "user_actions_insert_own" ON public.user_actions
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

-- 6b. profiles: 인증된 유저는 삭제되지 않은 프로필 조회 가능 (매칭 추천용)
--     기존 profiles_select_own은 자기 자신만 읽기 가능하므로, 매칭 추천을 위해 확장 필요
CREATE POLICY "profiles_select_for_matching" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL);

-- 6c. daily_usage: 본인 insert + update
CREATE POLICY "daily_usage_insert_own" ON public.daily_usage
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

CREATE POLICY "daily_usage_update_own" ON public.daily_usage
  FOR UPDATE USING (user_id = public.current_profile_id());

-- 6d. user_points: 본인 insert + update
CREATE POLICY "user_points_insert_own" ON public.user_points
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

CREATE POLICY "user_points_update_own" ON public.user_points
  FOR UPDATE USING (user_id = public.current_profile_id());

-- 6e. point_transactions: 본인 insert
CREATE POLICY "point_tx_insert_own" ON public.point_transactions
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());

-- 6f. saju_compatibility: 본인이 user_id인 궁합 insert
CREATE POLICY "compat_insert_own" ON public.saju_compatibility
  FOR INSERT WITH CHECK (user_id = public.current_profile_id());
