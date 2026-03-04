-- =============================================================================
-- profiles → auth.users 자동 동기화 트리거
--
-- profiles.name → auth.users.raw_user_meta_data.display_name
-- profiles.phone + is_phone_verified → auth.users.phone + phone_confirmed_at
--
-- SECURITY DEFINER: auth 스키마 직접 접근 필요
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fn_sync_profile_to_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- display_name 동기화 (name 변경 시)
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    UPDATE auth.users
    SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
        || jsonb_build_object('display_name', NEW.name)
    WHERE id = NEW.auth_id;
  END IF;

  -- phone 동기화 (인증 완료된 전화번호만)
  IF NEW.phone IS DISTINCT FROM OLD.phone
     AND NEW.is_phone_verified = true
     AND NEW.phone IS NOT NULL THEN
    UPDATE auth.users
    SET phone = NEW.phone,
        phone_confirmed_at = NOW()
    WHERE id = NEW.auth_id;
  END IF;

  RETURN NEW;
END;
$$;

-- INSERT 시에도 동기화 (최초 프로필 생성)
CREATE OR REPLACE FUNCTION public.fn_sync_profile_to_auth_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- display_name 동기화
  IF NEW.name IS NOT NULL THEN
    UPDATE auth.users
    SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
        || jsonb_build_object('display_name', NEW.name)
    WHERE id = NEW.auth_id;
  END IF;

  -- phone 동기화 (인증 완료된 전화번호만)
  IF NEW.phone IS NOT NULL AND NEW.is_phone_verified = true THEN
    UPDATE auth.users
    SET phone = NEW.phone,
        phone_confirmed_at = NOW()
    WHERE id = NEW.auth_id;
  END IF;

  RETURN NEW;
END;
$$;

-- UPDATE 트리거
DROP TRIGGER IF EXISTS trg_sync_profile_to_auth ON public.profiles;
CREATE TRIGGER trg_sync_profile_to_auth
  AFTER UPDATE OF name, phone, is_phone_verified ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sync_profile_to_auth();

-- INSERT 트리거
DROP TRIGGER IF EXISTS trg_sync_profile_to_auth_insert ON public.profiles;
CREATE TRIGGER trg_sync_profile_to_auth_insert
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sync_profile_to_auth_on_insert();
