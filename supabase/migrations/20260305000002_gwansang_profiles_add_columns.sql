-- gwansang_profiles 테이블에 누락된 컬럼 추가
-- animal_modifier, animal_type_korean, samjeong, ogwan, traits, romance_key_points

ALTER TABLE public.gwansang_profiles
  ADD COLUMN IF NOT EXISTS animal_modifier text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS animal_type_korean text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS samjeong jsonb NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS ogwan jsonb NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS traits jsonb NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS romance_key_points text[] NOT NULL DEFAULT '{}';
