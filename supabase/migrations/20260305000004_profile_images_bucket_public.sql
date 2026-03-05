-- profile-images 버킷을 public으로 변경
-- 소개팅 앱에서 프로필 사진은 다른 유저 및 Claude Vision API가 접근 가능해야 함
UPDATE storage.buckets
SET public = true
WHERE id = 'profile-images';
