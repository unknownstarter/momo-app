-- profiles 테이블에 saju_profile_id 컬럼 추가
-- saju_profiles와 1:1 관계 설정
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS saju_profile_id uuid
  REFERENCES public.saju_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_saju_profile
  ON public.profiles(saju_profile_id);
