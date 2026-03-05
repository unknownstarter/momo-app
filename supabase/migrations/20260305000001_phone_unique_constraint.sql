-- ============================================================
-- 1인 1계정 정책: 전화번호 UNIQUE 제약 추가
-- 인증 완료된 전화번호만 UNIQUE (partial unique index)
-- NULL은 허용 (아직 전화번호 미입력 유저)
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_phone_unique
  ON public.profiles(phone)
  WHERE phone IS NOT NULL AND is_phone_verified = true;
