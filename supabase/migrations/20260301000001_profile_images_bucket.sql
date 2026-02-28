-- profile-images 스토리지 버킷 생성 + RLS 정책
-- Sprint A: Auth 실연동 준비

-- 버킷 생성 (비공개)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  false,
  10485760, -- 10MB
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- RLS 정책: 인증된 사용자는 자신의 폴더에만 업로드 가능
CREATE POLICY "Users can upload own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS 정책: 인증된 사용자는 자신의 이미지를 업데이트 가능
CREATE POLICY "Users can update own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS 정책: 인증된 사용자는 자신의 이미지를 삭제 가능
CREATE POLICY "Users can delete own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS 정책: 모든 인증된 사용자가 프로필 이미지를 조회 가능 (매칭용)
CREATE POLICY "Authenticated users can view profile images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'profile-images');
