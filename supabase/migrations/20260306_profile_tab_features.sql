-- ============================================================
-- Profile Tab Features: 설정 컬럼 + 연락처 차단 테이블
-- ============================================================

-- ============================================================
-- 1. profiles 테이블에 설정 컬럼 추가
-- ============================================================

-- push_enabled: 푸시 알림 on/off
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'push_enabled'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN push_enabled boolean DEFAULT true;
  END IF;
END $$;

-- contact_sync_enabled: 연락처 동기화 on/off
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'contact_sync_enabled'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN contact_sync_enabled boolean DEFAULT false;
  END IF;
END $$;

-- contact_synced_at: 마지막 연락처 동기화 시각
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'contact_synced_at'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN contact_synced_at timestamptz;
  END IF;
END $$;

-- deleted_at: 소프트 삭제 (initial_schema에 이미 존재하지만 안전하게 IF NOT EXISTS)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN deleted_at timestamptz;
  END IF;
END $$;

-- ============================================================
-- 2. blocked_phone_hashes 테이블 (연락처 차단)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blocked_phone_hashes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  phone_hash text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 동일 유저가 같은 해시를 중복 등록하지 않도록 유니크 인덱스
CREATE UNIQUE INDEX IF NOT EXISTS idx_blocked_phone_hashes_user_hash
  ON public.blocked_phone_hashes(user_id, phone_hash);

-- ============================================================
-- 3. blocked_phone_hashes RLS
-- ============================================================

ALTER TABLE public.blocked_phone_hashes ENABLE ROW LEVEL SECURITY;

-- 본인의 차단 해시만 조회
CREATE POLICY "blocked_phones_select_own" ON public.blocked_phone_hashes
  FOR SELECT
  USING (user_id = (SELECT id FROM public.profiles WHERE auth_id = auth.uid()));

-- 본인의 차단 해시만 추가
CREATE POLICY "blocked_phones_insert_own" ON public.blocked_phone_hashes
  FOR INSERT
  WITH CHECK (user_id = (SELECT id FROM public.profiles WHERE auth_id = auth.uid()));

-- 본인의 차단 해시만 삭제
CREATE POLICY "blocked_phones_delete_own" ON public.blocked_phone_hashes
  FOR DELETE
  USING (user_id = (SELECT id FROM public.profiles WHERE auth_id = auth.uid()));

-- ============================================================
-- 4. RPC: 차단 연락처에 해당하는 프로필 ID 반환
-- ============================================================
-- 유저가 동기화한 연락처 해시와 다른 유저의 전화번호 해시를 비교하여
-- 매칭 추천에서 제외해야 할 프로필 ID를 반환합니다.
-- phone 컬럼에서 숫자만 추출 → 뒤 8자리 → SHA256 해시 비교
-- SECURITY DEFINER: 모든 profiles.phone을 읽을 수 있어야 하므로 (RLS 우회)

CREATE OR REPLACE FUNCTION public.get_blocked_profile_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.id
  FROM profiles p
  JOIN blocked_phone_hashes bph ON bph.user_id = p_user_id
  WHERE p.phone IS NOT NULL
    AND p.id != p_user_id
    AND encode(
          sha256(
            right(
              regexp_replace(p.phone, '[^0-9]', '', 'g'),
              8
            )::bytea
          ),
          'hex'
        ) = bph.phone_hash;
$$;
