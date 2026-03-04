-- ============================================================
-- Sprint ON 누락 컬럼 추가: body_type, ideal_type, is_phone_verified
-- UserEntity/UserModel에서 사용하지만 DB에 없던 컬럼들
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS body_type text CHECK (body_type IN ('slim', 'average', 'slightlyChubby', 'chubby')),
  ADD COLUMN IF NOT EXISTS ideal_type text,
  ADD COLUMN IF NOT EXISTS is_phone_verified boolean NOT NULL DEFAULT false;

-- is_phone_verified 인덱스 (인증 뱃지 필터용)
CREATE INDEX IF NOT EXISTS idx_profiles_phone_verified
  ON public.profiles(is_phone_verified)
  WHERE is_phone_verified = true;

-- animal_type 인덱스 (관상 동물상 — 이미 존재할 수 있음)
CREATE INDEX IF NOT EXISTS idx_profiles_animal_type
  ON public.profiles(dominant_element)
  WHERE dominant_element IS NOT NULL;
