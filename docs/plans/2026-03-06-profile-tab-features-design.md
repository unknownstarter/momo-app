# Profile Tab Features Design

## Goal
프로필 탭의 프로필 편집, 설정(Push 알림, 아는 사람 피하기), 회원 탈퇴 기능을 구현한다.

## Scope
- 프로필 편집: MatchingProfilePage 재활용 (isEditMode)
- 설정 페이지: Push 알림 권한 + 아는 사람 피하기(연락처 해시) + 계정(로그아웃/탈퇴)
- 프로필 탭 메인: 캐릭터 동적 변경, 로그아웃 → 설정으로 이동
- 결제/구독은 이번 스코프 아님

## 1. Profile Edit (`/profile/edit`)

MatchingProfilePage에 `isEditMode` 파라미터 추가:
- 온보딩: 뒤로가기 없음, 빈 폼, 저장 → postAnalysisMatches
- 편집: 뒤로가기 있음, UserEntity 프리필, 저장 → pop(), CTA "저장"

## 2. Settings Page (`/settings`)

### Push 알림
- permission_handler 패키지로 권한 요청
- 토글 ON → 권한 요청 → 허용/거절 처리
- 토글 OFF → profiles.push_enabled = false
- FCM 토큰 등록은 추후 — 권한 + 플래그만 관리

### 아는 사람 피하기
- flutter_contacts로 연락처 읽기
- 전화번호 정규화 (국가코드/하이픈/공백 제거) → SHA256 해시
- DB: blocked_phone_hashes 테이블 (user_id, phone_hash, unique index)
- 매칭 쿼리에서 해시 매칭으로 제외
- 토글 ON 시 1회 동기화 + 수동 "다시 동기화" 버튼

### 계정
- 로그아웃 (기존 로직 이동)
- 회원 탈퇴: 2단계 확인 → profiles.deleted_at 소프트 딜리트 → 즉시 로그아웃

## 3. Profile Tab Main 개선
- 캐릭터: 나무리 하드코딩 → 유저 오행 캐릭터 동적
- 로그아웃 버튼 → 설정 페이지로 이동

## DB Changes
```sql
-- blocked_phone_hashes
CREATE TABLE blocked_phone_hashes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  phone_hash text NOT NULL,
  created_at timestamptz DEFAULT now()
);
CREATE UNIQUE INDEX idx_blocked_phone_user ON blocked_phone_hashes(user_id, phone_hash);

-- profiles 컬럼 추가
ALTER TABLE profiles ADD COLUMN push_enabled boolean DEFAULT true;
ALTER TABLE profiles ADD COLUMN contact_sync_enabled boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN contact_synced_at timestamptz;
ALTER TABLE profiles ADD COLUMN deleted_at timestamptz;
```

## Packages
- permission_handler (알림 권한)
- flutter_contacts (연락처 읽기)
- crypto (SHA256 해싱)
