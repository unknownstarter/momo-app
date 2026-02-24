-- ============================================================
-- Saju App Initial Schema
-- ============================================================

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES (유저 기본 정보)
-- ============================================================
create table public.profiles (
  id uuid primary key default uuid_generate_v4(),
  auth_id uuid unique not null references auth.users(id) on delete cascade,
  name text not null,
  birth_date date not null,
  birth_time time,
  gender text not null check (gender in ('male', 'female')),
  profile_images text[] default '{}',
  bio text,
  interests text[] default '{}',
  height int,
  location text,
  occupation text,
  dominant_element text check (dominant_element in ('wood', 'fire', 'earth', 'metal', 'water')),
  character_type text check (character_type in ('namuri', 'bulkkori', 'heuksuni', 'soedongi', 'mulgyeori')),
  point_balance int not null default 0,
  is_premium boolean not null default false,
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_profiles_auth_id on public.profiles(auth_id);
create index idx_profiles_dominant_element on public.profiles(dominant_element);
create index idx_profiles_last_active on public.profiles(last_active_at desc);

-- ============================================================
-- SAJU PROFILES (사주 분석 결과)
-- ============================================================
create table public.saju_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  year_pillar jsonb not null,
  month_pillar jsonb not null,
  day_pillar jsonb not null,
  hour_pillar jsonb,
  five_elements jsonb not null,
  dominant_element text not null,
  personality_traits text[] default '{}',
  ai_interpretation text,
  is_lunar_calendar boolean not null default false,
  calculated_at timestamptz not null default now()
);

-- ============================================================
-- SAJU COMPATIBILITY (궁합 결과 — 캐시)
-- ============================================================
create table public.saju_compatibility (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  partner_id uuid not null references public.profiles(id),
  total_score int not null check (total_score between 0 and 100),
  five_element_score int,
  day_pillar_score int,
  overall_analysis text,
  strengths text[] default '{}',
  challenges text[] default '{}',
  advice text,
  ai_story text,
  is_detailed boolean not null default false,
  calculated_at timestamptz not null default now(),
  unique(user_id, partner_id)
);

create index idx_compatibility_user on public.saju_compatibility(user_id);
create index idx_compatibility_partner on public.saju_compatibility(partner_id);

-- ============================================================
-- DAILY MATCHES (매일 추천)
-- ============================================================
create table public.daily_matches (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  recommended_id uuid not null references public.profiles(id),
  compatibility_id uuid references public.saju_compatibility(id),
  match_date date not null default current_date,
  is_viewed boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id, recommended_id, match_date)
);

create index idx_daily_matches_user_date on public.daily_matches(user_id, match_date desc);

-- ============================================================
-- LIKES (좋아요)
-- ============================================================
create table public.likes (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid not null references public.profiles(id),
  receiver_id uuid not null references public.profiles(id),
  is_premium boolean not null default false,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'expired')),
  sent_at timestamptz not null default now(),
  responded_at timestamptz,
  unique(sender_id, receiver_id)
);

create index idx_likes_receiver_status on public.likes(receiver_id, status);
create index idx_likes_sender on public.likes(sender_id);

-- ============================================================
-- MATCHES (매칭 성사)
-- ============================================================
create table public.matches (
  id uuid primary key default uuid_generate_v4(),
  user1_id uuid not null references public.profiles(id),
  user2_id uuid not null references public.profiles(id),
  like_id uuid references public.likes(id),
  compatibility_id uuid references public.saju_compatibility(id),
  matched_at timestamptz not null default now(),
  unmatched_at timestamptz
);

create index idx_matches_users on public.matches(user1_id, user2_id);

-- ============================================================
-- CHAT ROOMS (채팅방)
-- ============================================================
create table public.chat_rooms (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid unique not null references public.matches(id),
  user1_id uuid not null references public.profiles(id),
  user2_id uuid not null references public.profiles(id),
  last_message_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_chat_rooms_users on public.chat_rooms using gin(array[user1_id, user2_id]);

-- ============================================================
-- CHAT MESSAGES (채팅 메시지)
-- ============================================================
create table public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text not null,
  message_type text not null default 'text' check (message_type in ('text', 'image', 'icebreaker', 'system')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_messages_room_created on public.chat_messages(room_id, created_at desc);

-- ============================================================
-- USER POINTS (포인트 잔액)
-- ============================================================
create table public.user_points (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  balance int not null default 0 check (balance >= 0),
  total_earned int not null default 0,
  total_spent int not null default 0,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- POINT TRANSACTIONS (포인트 거래 내역)
-- ============================================================
create table public.point_transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  type text not null check (type in (
    'purchase', 'like_sent', 'premium_like_sent', 'accept',
    'compatibility_report', 'character_skin', 'saju_report',
    'icebreaker', 'daily_reset_bonus', 'refund'
  )),
  amount int not null,
  target_id uuid,
  description text,
  created_at timestamptz not null default now()
);

create index idx_point_tx_user on public.point_transactions(user_id, created_at desc);

-- ============================================================
-- DAILY USAGE (일일 무료 사용량)
-- ============================================================
create table public.daily_usage (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  usage_date date not null default current_date,
  free_likes_used int not null default 0 check (free_likes_used between 0 and 3),
  free_accepts_used int not null default 0 check (free_accepts_used between 0 and 3),
  unique(user_id, usage_date)
);

-- ============================================================
-- BLOCKS (차단)
-- ============================================================
create table public.blocks (
  id uuid primary key default uuid_generate_v4(),
  blocker_id uuid not null references public.profiles(id),
  blocked_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(blocker_id, blocked_id)
);

-- ============================================================
-- REPORTS (신고)
-- ============================================================
create table public.reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.profiles(id),
  reported_id uuid not null references public.profiles(id),
  reason text not null,
  description text,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'resolved')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- PURCHASES (IAP 구매 내역)
-- ============================================================
create table public.purchases (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  product_type text not null check (product_type in (
    'point_package', 'detailed_compatibility', 'character_skin',
    'saju_report', 'subscription'
  )),
  product_id text not null,
  amount int,
  currency text default 'KRW',
  receipt_data text,
  purchased_at timestamptz not null default now(),
  expires_at timestamptz
);

create index idx_purchases_user on public.purchases(user_id, purchased_at desc);

-- ============================================================
-- CHARACTER ITEMS (캐릭터 커스터마이징)
-- ============================================================
create table public.character_items (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  item_type text not null check (item_type in ('outfit', 'accessory', 'background')),
  item_id text not null,
  is_equipped boolean not null default false,
  purchased_at timestamptz not null default now(),
  unique(user_id, item_id)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.saju_profiles enable row level security;
alter table public.saju_compatibility enable row level security;
alter table public.daily_matches enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
alter table public.user_points enable row level security;
alter table public.point_transactions enable row level security;
alter table public.daily_usage enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.purchases enable row level security;
alter table public.character_items enable row level security;

-- Helper: get current user's profile id
create or replace function public.current_profile_id()
returns uuid as $$
  select id from public.profiles where auth_id = auth.uid()
$$ language sql security definer stable;

-- PROFILES: 자기 것만 수정, 추천 상대 프로필은 읽기 가능
create policy "profiles_select_own" on public.profiles for select using (auth_id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (auth_id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (auth_id = auth.uid());

-- SAJU PROFILES: 자기 것만
create policy "saju_select_own" on public.saju_profiles for select using (user_id = public.current_profile_id());
create policy "saju_insert_own" on public.saju_profiles for insert with check (user_id = public.current_profile_id());
create policy "saju_update_own" on public.saju_profiles for update using (user_id = public.current_profile_id());

-- COMPATIBILITY: 당사자만
create policy "compat_select" on public.saju_compatibility for select
  using (user_id = public.current_profile_id() or partner_id = public.current_profile_id());

-- LIKES: sender/receiver만
create policy "likes_select" on public.likes for select
  using (sender_id = public.current_profile_id() or receiver_id = public.current_profile_id());
create policy "likes_insert" on public.likes for insert
  with check (sender_id = public.current_profile_id());
create policy "likes_update" on public.likes for update
  using (receiver_id = public.current_profile_id());

-- MATCHES: 참여자만
create policy "matches_select" on public.matches for select
  using (user1_id = public.current_profile_id() or user2_id = public.current_profile_id());

-- CHAT ROOMS: 참여자만
create policy "rooms_select" on public.chat_rooms for select
  using (user1_id = public.current_profile_id() or user2_id = public.current_profile_id());

-- CHAT MESSAGES: 해당 채팅방 참여자만
create policy "messages_select" on public.chat_messages for select
  using (
    room_id in (
      select id from public.chat_rooms
      where user1_id = public.current_profile_id() or user2_id = public.current_profile_id()
    )
  );
create policy "messages_insert" on public.chat_messages for insert
  with check (sender_id = public.current_profile_id());

-- POINTS: 본인만
create policy "points_select" on public.user_points for select using (user_id = public.current_profile_id());
create policy "point_tx_select" on public.point_transactions for select using (user_id = public.current_profile_id());

-- DAILY USAGE: 본인만
create policy "daily_usage_select" on public.daily_usage for select using (user_id = public.current_profile_id());

-- PURCHASES: 본인만
create policy "purchases_select" on public.purchases for select using (user_id = public.current_profile_id());

-- CHARACTER ITEMS: 본인만
create policy "char_items_select" on public.character_items for select using (user_id = public.current_profile_id());
create policy "char_items_update" on public.character_items for update using (user_id = public.current_profile_id());

-- DAILY MATCHES: 본인 추천만
create policy "daily_matches_select" on public.daily_matches for select using (user_id = public.current_profile_id());

-- BLOCKS/REPORTS: 본인 것만
create policy "blocks_select" on public.blocks for select using (blocker_id = public.current_profile_id());
create policy "blocks_insert" on public.blocks for insert with check (blocker_id = public.current_profile_id());
create policy "reports_insert" on public.reports for insert with check (reporter_id = public.current_profile_id());

-- ============================================================
-- REALTIME: 채팅 메시지 구독 활성화
-- ============================================================
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.likes;
