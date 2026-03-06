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
