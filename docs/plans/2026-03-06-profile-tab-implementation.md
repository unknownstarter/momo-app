# Profile Tab Features Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 프로필 탭의 프로필 편집, 설정(Push 알림, 아는 사람 피하기), 회원 탈퇴 기능을 구현한다.

**Architecture:** MatchingProfilePage를 isEditMode 파라미터로 재활용하여 프로필 편집 구현. 설정 페이지는 새로 생성하되, push 알림 권한(permission_handler), 연락처 동기화(flutter_contacts + SHA256 해시), 로그아웃/탈퇴를 포함. 프로필 탭 메인에서 캐릭터 동적 렌더링 및 로그아웃→설정 이동.

**Tech Stack:** Flutter 3.38+, Riverpod, go_router, permission_handler, flutter_contacts, crypto (SHA256), Supabase (PostgreSQL + Edge Functions)

---

### Task 1: DB 마이그레이션 (profiles 컬럼 + blocked_phone_hashes 테이블)

**Files:**
- Create: `supabase/migrations/20260306_profile_tab_features.sql`

**Step 1: SQL 마이그레이션 작성**

```sql
-- profiles 컬럼 추가
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS push_enabled boolean DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS contact_sync_enabled boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS contact_synced_at timestamptz;
-- deleted_at은 이미 UserEntity에 존재, DB에도 있는지 확인 후 추가
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- blocked_phone_hashes 테이블
CREATE TABLE IF NOT EXISTS blocked_phone_hashes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  phone_hash text NOT NULL,
  created_at timestamptz DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_blocked_phone_user
  ON blocked_phone_hashes(user_id, phone_hash);

-- RLS
ALTER TABLE blocked_phone_hashes ENABLE ROW LEVEL SECURITY;

-- 유저는 자기 해시만 CRUD
CREATE POLICY "Users can manage own phone hashes"
  ON blocked_phone_hashes
  FOR ALL
  USING (user_id = (SELECT id FROM profiles WHERE auth_id = auth.uid()))
  WITH CHECK (user_id = (SELECT id FROM profiles WHERE auth_id = auth.uid()));
```

**Step 2: Supabase 대시보드에서 SQL 실행**

Run: Supabase SQL Editor에서 위 SQL 실행
Expected: 테이블/컬럼 생성 성공

**Step 3: 커밋**

```bash
git add supabase/migrations/
git commit -m "feat: DB 마이그레이션 - profiles 컬럼 + blocked_phone_hashes 테이블"
```

---

### Task 2: 패키지 추가 (permission_handler, flutter_contacts, crypto)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Podfile` (필요 시)
- Modify: `ios/Runner/Info.plist` — 연락처/알림 권한 설명
- Modify: `android/app/src/main/AndroidManifest.xml` — 연락처 권한

**Step 1: pubspec.yaml에 패키지 추가**

```yaml
dependencies:
  # ... existing ...
  permission_handler: ^11.3.1
  flutter_contacts: ^1.1.9+2
  crypto: ^3.0.3
```

**Step 2: iOS Info.plist 권한 설명 추가**

`ios/Runner/Info.plist`에 추가:
```xml
<key>NSContactsUsageDescription</key>
<string>아는 사람을 매칭에서 제외하기 위해 연락처에 접근합니다. 전화번호는 암호화되어 저장됩니다.</string>
```
알림 권한 (`NSUserNotificationsUsageDescription`)은 Firebase에서 이미 설정되어 있을 수 있음. 확인 후 없으면 추가.

**Step 3: Android 매니페스트 권한 추가**

`android/app/src/main/AndroidManifest.xml`에 추가 (없으면):
```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

**Step 4: 패키지 설치 + 빌드 확인**

Run: `flutter pub get`
Expected: 성공

**Step 5: 커밋**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml ios/Podfile
git commit -m "feat: permission_handler, flutter_contacts, crypto 패키지 추가"
```

---

### Task 3: 프로필 편집 — MatchingProfilePage isEditMode 확장

**Files:**
- Modify: `lib/features/profile/presentation/pages/matching_profile_page.dart`
- Modify: `lib/features/profile/presentation/providers/matching_profile_provider.dart`
- Modify: `lib/app/routes/app_router.dart` (editProfile 라우트 연결)

**Step 1: MatchingProfilePage에 isEditMode 파라미터 추가**

`matching_profile_page.dart` 변경:
```dart
class MatchingProfilePage extends ConsumerStatefulWidget {
  const MatchingProfilePage({super.key, this.isEditMode = false});
  final bool isEditMode;
  // ...
}
```

**Step 2: initState에서 편집 모드일 때 기존 데이터 프리필**

```dart
@override
void initState() {
  super.initState();
  _loadExistingPhotos();
  if (widget.isEditMode) {
    _prefillFromProfile();
  }
}

Future<void> _prefillFromProfile() async {
  try {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _heightController.text = profile.height?.toString() ?? '';
        _occupationController.text = profile.occupation ?? '';
        _selectedLocation = profile.location;
        _bioController.text = profile.bio ?? '';
        _selectedBodyType = profile.bodyType;
        _selectedReligion = profile.religion;
        _selectedInterests.addAll(profile.interests);
        _idealTypeController.text = profile.idealType ?? '';
      });
    }
  } catch (_) {}
}
```

**Step 3: 상단 바 — 편집 모드에서 뒤로가기 + 타이틀 변경**

```dart
Widget _buildTopBar(ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: SajuSpacing.space16,
      vertical: SajuSpacing.space8,
    ),
    child: Row(
      children: [
        if (widget.isEditMode)
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          )
        else
          const SizedBox(width: 40, height: 40),
        const Spacer(),
        Text(
          widget.isEditMode ? '프로필 편집' : '프로필 완성하기',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40, height: 40),
      ],
    ),
  );
}
```

**Step 4: 저장 로직 분기 — 편집 모드에서는 updateProfile + pop()**

`_submitProfile()` 수정:
```dart
Future<void> _submitProfile() async {
  if (_isSubmitting || !_validate()) return;
  FocusScope.of(context).unfocus();
  HapticFeedback.mediumImpact();
  setState(() => _isSubmitting = true);

  // 사진 업로드 (기존 로직 동일)
  // ...로컬 파일 업로드 + URL 변환...

  if (widget.isEditMode) {
    // 편집 모드: updateProfile + pop
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile({
        'profile_images': photoUrls,
        'height': int.parse(_heightController.text.trim()),
        'occupation': _occupationController.text.trim(),
        'location': _selectedLocation,
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests.toList(),
        'religion': _selectedReligion?.name,
        'body_type': _selectedBodyType?.name,
        'ideal_type': _idealTypeController.text.trim().isNotEmpty
            ? _idealTypeController.text.trim()
            : null,
      });
      if (!mounted) return;
      ref.invalidate(currentUserProfileProvider);
      setState(() => _isSubmitting = false);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('저장에 실패했어요. 다시 시도해주세요.');
    }
  } else {
    // 온보딩 모드: 기존 로직
    final result = await ref
        .read(matchingProfileNotifierProvider.notifier)
        .saveMatchingProfile(/* 기존 파라미터 */);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result != null) {
      AnalyticsService.completeMatchingProfile();
      context.go(RoutePaths.postAnalysisMatches);
    } else {
      _showSnack('프로필 저장에 실패했어요. 다시 시도해주세요.');
    }
  }
}
```

**Step 5: 하단 버튼 라벨 분기**

```dart
SajuButton(
  label: _isSubmitting
      ? '저장 중...'
      : widget.isEditMode
          ? '저장'
          : '프로필 완성!',
  // ...
)
```

**Step 6: app_router.dart — editProfile 라우트를 실제 페이지로 연결**

```dart
// 프로필 편집 (기존 _PlaceholderPage 교체)
GoRoute(
  path: RoutePaths.editProfile,
  name: RouteNames.editProfile,
  builder: (context, state) =>
      const MatchingProfilePage(isEditMode: true),
),
```

**Step 7: 빌드 확인**

Run: `flutter analyze --no-fatal-infos`
Expected: 에러 없음

**Step 8: 커밋**

```bash
git add lib/features/profile/ lib/app/routes/app_router.dart
git commit -m "feat: 프로필 편집 기능 (MatchingProfilePage isEditMode)"
```

---

### Task 4: 설정 페이지 UI 스켈레톤

**Files:**
- Create: `lib/features/profile/presentation/pages/settings_page.dart`
- Modify: `lib/app/routes/app_router.dart` (settings 라우트 연결)

**Step 1: SettingsPage 기본 구조 작성**

```dart
// lib/features/profile/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sajuColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          '설정',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 섹션 1: 알림
          _SectionHeader(title: '알림'),
          _PushNotificationTile(),
          const Divider(height: 1),

          // 섹션 2: 프라이버시
          _SectionHeader(title: '프라이버시'),
          _ContactBlockTile(),
          const Divider(height: 1),

          // 섹션 3: 계정
          _SectionHeader(title: '계정'),
          _LogoutTile(),
          const Divider(height: 1),
          _DeleteAccountTile(),
        ],
      ),
    );
  }
}
```

각 타일 위젯은 Task 5~7에서 구현. 이 태스크에서는 UI 껍데기와 라우트 연결만.

**Step 2: app_router.dart — settings 라우트를 실제 페이지로 연결**

```dart
// 기존 _PlaceholderPage(title: 'Settings') 교체
GoRoute(
  path: RoutePaths.settings,
  name: RouteNames.settings,
  builder: (context, state) => const SettingsPage(),
),
```

**Step 3: 빌드 확인**

Run: `flutter analyze --no-fatal-infos`
Expected: 에러 없음

**Step 4: 커밋**

```bash
git add lib/features/profile/presentation/pages/settings_page.dart lib/app/routes/app_router.dart
git commit -m "feat: 설정 페이지 UI 스켈레톤"
```

---

### Task 5: Push 알림 토글 구현

**Files:**
- Modify: `lib/features/profile/presentation/pages/settings_page.dart` (_PushNotificationTile)
- Create: `lib/features/profile/presentation/providers/settings_provider.dart`

**Step 1: settings_provider 작성**

```dart
// lib/features/profile/presentation/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Push 알림 활성화 상태 Provider
final pushEnabledProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  // DB의 push_enabled 값 (profiles 테이블에서 직접 가져옴)
  // UserEntity에 pushEnabled 필드가 없으므로 직접 쿼리
  if (profile == null) return false;
  final repo = ref.read(profileRepositoryProvider);
  final user = await repo.getProfile();
  // 임시: profiles에서 push_enabled 필드 직접 읽기
  return true; // 기본값
});
```

실제로는 `ProfileRepository`에 `getPushEnabled()` 메서드를 추가하거나, `updateProfile`로 토글.

**Step 2: _PushNotificationTile 위젯 구현**

```dart
class _PushNotificationTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PushNotificationTile> createState() => _PushNotificationTileState();
}

class _PushNotificationTileState extends ConsumerState<_PushNotificationTile> {
  bool _pushEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPushState();
  }

  Future<void> _loadPushState() async {
    // profiles.push_enabled 읽기
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.getProfileRaw(); // raw Map 반환
    if (!mounted) return;
    setState(() {
      _pushEnabled = profile?['push_enabled'] ?? true;
      _loading = false;
    });
  }

  Future<void> _togglePush(bool value) async {
    if (value) {
      // 권한 요청
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        if (!mounted) return;
        // 설정으로 안내
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한을 허용해주세요')),
        );
        openAppSettings();
        return;
      }
    }

    // DB 업데이트
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile({'push_enabled': value});
    if (!mounted) return;
    setState(() => _pushEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('푸시 알림'),
      subtitle: const Text('새로운 매칭, 좋아요, 메시지 알림'),
      value: _loading ? true : _pushEnabled,
      onChanged: _loading ? null : _togglePush,
    );
  }
}
```

**Step 3: ProfileRepository에 getProfileRaw() 추가** (profiles raw Map 반환)

`lib/features/profile/domain/repositories/profile_repository.dart`:
```dart
/// profiles 테이블 raw 데이터 반환 (push_enabled 등 UserEntity에 없는 필드 접근용)
Future<Map<String, dynamic>?> getProfileRaw();
```

`lib/features/profile/data/repositories/profile_repository_impl.dart`:
```dart
@override
Future<Map<String, dynamic>?> getProfileRaw() async {
  final authId = _client.auth.currentUser?.id;
  if (authId == null) return null;
  return await _client
      .from(SupabaseTables.profiles)
      .select()
      .eq('auth_id', authId)
      .maybeSingle();
}
```

**Step 4: 빌드 확인 + 커밋**

```bash
git add lib/features/profile/
git commit -m "feat: Push 알림 토글 (permission_handler + profiles.push_enabled)"
```

---

### Task 6: 아는 사람 피하기 (연락처 해시 동기화)

**Files:**
- Modify: `lib/features/profile/presentation/pages/settings_page.dart` (_ContactBlockTile)
- Create: `lib/features/profile/data/services/contact_block_service.dart`

**Step 1: ContactBlockService 작성**

```dart
// lib/features/profile/data/services/contact_block_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class ContactBlockService {
  ContactBlockService(this._client);
  final SupabaseClient _client;

  /// 연락처 권한 요청
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// 연락처를 읽어 전화번호 해시 생성 → DB 동기화
  Future<int> syncContacts(String userId) async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    final hashes = <String>{};
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhone(phone.number);
        if (normalized.isNotEmpty) {
          hashes.add(_hashPhone(normalized));
        }
      }
    }

    if (hashes.isEmpty) return 0;

    // 기존 해시 삭제 후 새로 삽입 (전체 동기화)
    await _client
        .from('blocked_phone_hashes')
        .delete()
        .eq('user_id', userId);

    final rows = hashes.map((h) => {
      'user_id': userId,
      'phone_hash': h,
    }).toList();

    // 배치 삽입 (100개씩)
    for (var i = 0; i < rows.length; i += 100) {
      final batch = rows.sublist(i, i + 100 > rows.length ? rows.length : i + 100);
      await _client.from('blocked_phone_hashes').insert(batch);
    }

    // profiles 업데이트
    await _client
        .from(SupabaseTables.profiles)
        .update({
          'contact_sync_enabled': true,
          'contact_synced_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    return hashes.length;
  }

  /// 연락처 차단 해제 (해시 삭제 + 플래그 off)
  Future<void> disableContactBlock(String userId) async {
    await _client
        .from('blocked_phone_hashes')
        .delete()
        .eq('user_id', userId);

    await _client
        .from(SupabaseTables.profiles)
        .update({
          'contact_sync_enabled': false,
          'contact_synced_at': null,
        })
        .eq('id', userId);
  }

  /// 전화번호 정규화: 국가코드/하이픈/공백/괄호 제거 → 마지막 8자리
  String _normalizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 8) return '';
    // 마지막 8자리로 통일 (국가코드 무관하게 매칭)
    return digitsOnly.substring(digitsOnly.length - 8);
  }

  /// SHA256 해시
  String _hashPhone(String normalizedPhone) {
    return sha256.convert(utf8.encode(normalizedPhone)).toString();
  }
}
```

**Step 2: _ContactBlockTile 위젯 구현**

```dart
class _ContactBlockTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ContactBlockTile> createState() => _ContactBlockTileState();
}

class _ContactBlockTileState extends ConsumerState<_ContactBlockTile> {
  bool _enabled = false;
  bool _syncing = false;
  DateTime? _lastSyncedAt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final repo = ref.read(profileRepositoryProvider);
    final raw = await repo.getProfileRaw();
    if (!mounted) return;
    setState(() {
      _enabled = raw?['contact_sync_enabled'] ?? false;
      _lastSyncedAt = raw?['contact_synced_at'] != null
          ? DateTime.tryParse(raw!['contact_synced_at'])
          : null;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (_syncing) return;

    if (value) {
      // 연락처 권한 요청 + 동기화
      setState(() => _syncing = true);
      final service = ContactBlockService(ref.read(supabaseClientProvider));
      final hasPermission = await service.requestPermission();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() => _syncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 접근 권한이 필요해요')),
        );
        return;
      }

      final user = await ref.read(currentUserProfileProvider.future);
      if (user == null || !mounted) return;

      final count = await service.syncContacts(user.id);
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _syncing = false;
        _lastSyncedAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연락처 $count건이 동기화되었어요')),
      );
    } else {
      // 차단 해제
      setState(() => _syncing = true);
      final service = ContactBlockService(ref.read(supabaseClientProvider));
      final user = await ref.read(currentUserProfileProvider.future);
      if (user == null || !mounted) return;
      await service.disableContactBlock(user.id);
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _syncing = false;
        _lastSyncedAt = null;
      });
    }
  }

  Future<void> _resync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final service = ContactBlockService(ref.read(supabaseClientProvider));
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null || !mounted) return;
    final count = await service.syncContacts(user.id);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _lastSyncedAt = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('연락처 $count건이 다시 동기화되었어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('아는 사람 피하기'),
          subtitle: Text(_syncing
              ? '동기화 중...'
              : _enabled
                  ? '연락처에 있는 사람은 매칭에서 제외돼요'
                  : '연락처를 동기화하면 아는 사람을 피할 수 있어요'),
          value: _loading ? false : _enabled,
          onChanged: _loading || _syncing ? null : _toggle,
        ),
        if (_enabled && !_syncing)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                if (_lastSyncedAt != null)
                  Text(
                    '마지막 동기화: ${_formatDate(_lastSyncedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.sajuColors.textTertiary,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _resync,
                  child: const Text('다시 동기화'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

**Step 3: DI 등록 — ContactBlockService Provider**

`lib/core/di/providers.dart`에 추가:
```dart
// Contact Block Service는 Provider 없이 직접 생성 (stateless, SupabaseClient만 필요)
// settings_page에서 ContactBlockService(ref.read(supabaseClientProvider))로 사용
```

**Step 4: 빌드 확인 + 커밋**

```bash
git add lib/features/profile/
git commit -m "feat: 아는 사람 피하기 (연락처 SHA256 해시 동기화)"
```

---

### Task 7: 계정 관리 (로그아웃 + 회원 탈퇴)

**Files:**
- Modify: `lib/features/profile/presentation/pages/settings_page.dart` (_LogoutTile, _DeleteAccountTile)

**Step 1: _LogoutTile 구현 (ProfilePage에서 이동)**

```dart
class _LogoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.logout, color: context.sajuColors.textSecondary),
      title: const Text('로그아웃'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('로그아웃 할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await ref.read(authNotifierProvider.notifier).signOut();
          if (context.mounted) context.go(RoutePaths.login);
        }
      },
    );
  }
}
```

**Step 2: _DeleteAccountTile 구현 (2단계 확인 + 소프트 딜리트)**

```dart
class _DeleteAccountTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
      onTap: () async {
        // 1단계: 정말로?
        final step1 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('회원 탈퇴'),
            content: const Text(
              '탈퇴하면 모든 데이터가 삭제되며\n복구할 수 없어요.\n\n정말 탈퇴하시겠어요?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('탈퇴하기'),
              ),
            ],
          ),
        );
        if (step1 != true || !context.mounted) return;

        // 2단계: 최종 확인
        final step2 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('최종 확인'),
            content: const Text('정말로 탈퇴하시겠어요?\n이 작업은 되돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('네, 탈퇴합니다'),
              ),
            ],
          ),
        );
        if (step2 != true || !context.mounted) return;

        // 소프트 딜리트: profiles.deleted_at 설정
        try {
          final repo = ref.read(profileRepositoryProvider);
          await repo.updateProfile({
            'deleted_at': DateTime.now().toIso8601String(),
          });
          if (!context.mounted) return;
          // 즉시 로그아웃
          await ref.read(authNotifierProvider.notifier).signOut();
          if (context.mounted) context.go(RoutePaths.login);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('탈퇴 처리 중 오류가 발생했어요')),
            );
          }
        }
      },
    );
  }
}
```

**Step 3: 빌드 확인 + 커밋**

```bash
git add lib/features/profile/presentation/pages/settings_page.dart
git commit -m "feat: 계정 관리 (로그아웃 이동 + 2단계 확인 회원 탈퇴)"
```

---

### Task 8: 프로필 탭 메인 개선 (동적 캐릭터 + 로그아웃→설정)

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`

**Step 1: 하드코딩된 나무리 → 유저 오행 캐릭터 동적 변경**

`_ProfileContent._buildCharacter()` — saju_profiles에서 dominantElement를 가져와 캐릭터 동적 매핑:

```dart
// ProfilePage 내 Image.asset 교체
// 기존: CharacterAssets.namuriWoodDefault
// 변경: 사주 프로필의 dominantElement 기반 동적 캐릭터

// saju profile을 가져오는 provider 사용
final sajuAsync = ref.watch(myAnalysisProvider);
final characterAsset = sajuAsync.maybeWhen(
  data: (data) {
    if (data.saju != null) {
      final element = data.saju!.dominantElement ?? FiveElementType.wood;
      return CharacterAssets.defaultFor(element);
    }
    return CharacterAssets.namuriWoodDefault;
  },
  orElse: () => CharacterAssets.namuriWoodDefault,
);
```

ProfilePage를 ConsumerWidget에서 필요한 provider watch 추가.

**Step 2: 로그아웃 버튼 제거 — 설정 메뉴로 이동 완료 확인**

ProfilePage에서 `_LogoutButton` 위젯 제거. 이미 설정 메뉴 타일(`_MenuTile(icon: Icons.settings_outlined, label: '설정')`)이 있으므로 로그아웃은 설정에서만 접근 가능.

**Step 3: 빌드 확인 + 커밋**

```bash
git add lib/features/profile/presentation/pages/profile_page.dart
git commit -m "feat: 프로필 탭 - 동적 캐릭터 + 로그아웃 설정 이동"
```

---

### Task 9: 매칭 쿼리에서 blocked contacts 제외

**Files:**
- Modify: `supabase/functions/generate-daily-recommendations/index.ts` (또는 해당 매칭 함수)
- 또는 Modify: `lib/features/matching/data/datasources/matching_remote_datasource.dart`

**Step 1: 매칭 쿼리에 blocked_phone_hashes 제외 조건 추가**

클라이언트 측 매칭 쿼리에서:
```dart
// matching_remote_datasource.dart의 추천 쿼리에
// blocked_phone_hashes에 있는 유저 제외
// profiles.phone 해시가 blocked_phone_hashes에 있으면 제외

// Supabase RPC 또는 Edge Function에서 처리하는 것이 성능상 유리
// 클라이언트에서 해시 비교는 비효율적이므로 DB 레벨에서 처리
```

매칭 추천 쿼리 (DB function 또는 Edge Function):
```sql
-- 추천 쿼리에 추가할 WHERE 절
AND p.id NOT IN (
  SELECT p2.id FROM profiles p2
  JOIN blocked_phone_hashes bph ON bph.user_id = $userId
  WHERE p2.phone IS NOT NULL
    AND encode(sha256(right(regexp_replace(p2.phone, '[^0-9]', '', 'g'), 8)::bytea), 'hex') = bph.phone_hash
)
```

주의: 이 로직은 `generate-daily-recommendations` Edge Function 또는 `sectionedRecommendationsNotifier`의 쿼리에 적용해야 함. 정확한 위치는 기존 매칭 쿼리 구현체를 확인 후 결정.

**Step 2: 빌드 확인 + 커밋**

```bash
git add supabase/functions/ lib/features/matching/
git commit -m "feat: 매칭 추천에서 차단 연락처 제외"
```

---

### Task 10: 통합 검증

**Step 1: 전체 빌드 확인**

Run: `flutter analyze --no-fatal-infos`
Expected: 에러 없음

**Step 2: 기능 동작 확인 체크리스트**

- [ ] 프로필 탭 → 프로필 편집 → 기존 데이터 프리필 확인
- [ ] 프로필 편집 → 저장 → pop 동작 확인
- [ ] 프로필 탭 → 설정 → Push 알림 토글 동작
- [ ] 설정 → 아는 사람 피하기 토글 → 연락처 권한 요청 → 동기화
- [ ] 설정 → 다시 동기화 버튼 동작
- [ ] 설정 → 로그아웃 동작
- [ ] 설정 → 회원 탈퇴 → 2단계 확인 → 소프트 딜리트 + 로그아웃
- [ ] 프로필 탭 캐릭터가 유저 오행에 맞게 표시
- [ ] 프로필 탭에서 로그아웃 버튼 제거 확인

**Step 3: 커밋**

```bash
git add .
git commit -m "chore: 프로필 탭 기능 통합 검증 완료"
```
