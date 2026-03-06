import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Settings Page
// =============================================================================

/// 설정 페이지
///
/// 알림, 프라이버시(아는 사람 피하기), 계정(로그아웃/탈퇴) 섹션으로 구성.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '설정',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.sajuColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.sajuColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: context.sajuColors.bgPrimary,
      body: ListView(
        children: const [
          // --- 알림 ---
          _SectionHeader(title: '알림'),
          _PushNotificationTile(),

          // --- 프라이버시 ---
          _SectionHeader(title: '프라이버시'),
          _ContactBlockTile(),

          // --- 계정 ---
          _SectionHeader(title: '계정'),
          _LogoutTile(),
          _DeleteAccountTile(),

          SizedBox(height: 48),
        ],
      ),
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.sajuColors.textTertiary,
        ),
      ),
    );
  }
}

// =============================================================================
// Task 5: Push Notification Toggle
// =============================================================================

class _PushNotificationTile extends ConsumerStatefulWidget {
  const _PushNotificationTile();

  @override
  ConsumerState<_PushNotificationTile> createState() =>
      _PushNotificationTileState();
}

class _PushNotificationTileState extends ConsumerState<_PushNotificationTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPushEnabled();
  }

  Future<void> _loadPushEnabled() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final authId = client.auth.currentUser?.id;
      if (authId == null) return;

      final result = await client
          .from('profiles')
          .select('push_enabled')
          .eq('auth_id', authId)
          .single();

      if (!mounted) return;
      setState(() {
        _enabled = result['push_enabled'] as bool? ?? false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      // ON: 권한 요청
      final status = await Permission.notification.request();
      if (!mounted) return;

      if (status.isDenied || status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('알림 권한이 필요해요. 설정에서 허용해 주세요.'),
            action: SnackBarAction(
              label: '설정',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    // DB 업데이트
    try {
      final client = ref.read(supabaseClientProvider);
      final authId = client.auth.currentUser?.id;
      if (authId == null) return;

      await client
          .from('profiles')
          .update({'push_enabled': value}).eq('auth_id', authId);

      if (!mounted) return;
      setState(() => _enabled = value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 변경에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        '푸시 알림',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.sajuColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '새로운 매칭, 좋아요, 메시지 알림',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          color: context.sajuColors.textSecondary,
        ),
      ),
      value: _enabled,
      onChanged: _loading ? null : _toggle,
    );
  }
}

// =============================================================================
// Task 6: Contact Block (아는 사람 피하기)
// =============================================================================

class _ContactBlockTile extends ConsumerStatefulWidget {
  const _ContactBlockTile();

  @override
  ConsumerState<_ContactBlockTile> createState() => _ContactBlockTileState();
}

class _ContactBlockTileState extends ConsumerState<_ContactBlockTile> {
  bool _enabled = false;
  bool _loading = true;
  bool _syncing = false;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final authId = client.auth.currentUser?.id;
      if (authId == null) return;

      final result = await client
          .from('profiles')
          .select('contact_sync_enabled, contact_synced_at')
          .eq('auth_id', authId)
          .single();

      if (!mounted) return;
      setState(() {
        _enabled = result['contact_sync_enabled'] as bool? ?? false;
        final syncedAt = result['contact_synced_at'] as String?;
        _lastSyncedAt = syncedAt != null ? DateTime.tryParse(syncedAt) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// 전화번호 정규화: 숫자만 남기고 뒤 8자리
  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 8) return digits;
    return digits.substring(digits.length - 8);
  }

  /// SHA256 해시
  String _hashPhone(String normalized) {
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  Future<void> _syncContacts() async {
    setState(() => _syncing = true);

    try {
      // 연락처 권한 요청
      final granted = await FlutterContacts.requestPermission();
      if (!mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('연락처 권한이 필요해요. 설정에서 허용해 주세요.'),
            action: SnackBarAction(
              label: '설정',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() => _syncing = false);
        return;
      }

      // 연락처 읽기
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      // 전화번호 추출 + 정규화 + 해시
      final hashes = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _normalizePhone(phone.number);
          if (normalized.length >= 7) {
            hashes.add(_hashPhone(normalized));
          }
        }
      }

      // 유저 프로필 ID 가져오기
      final user = await ref.read(currentUserProfileProvider.future);
      if (!mounted) return;
      if (user == null) {
        if (mounted) setState(() => _syncing = false);
        return;
      }

      final userId = user.id;
      final client = ref.read(supabaseClientProvider);

      // 기존 해시 삭제
      await client.from('blocked_phone_hashes').delete().eq('user_id', userId);
      if (!mounted) return;

      // 새 해시 일괄 삽입 (100개씩 배치)
      final rows =
          hashes.map((h) => {'user_id': userId, 'phone_hash': h}).toList();
      for (var i = 0; i < rows.length; i += 100) {
        final batch = rows.sublist(i, (i + 100).clamp(0, rows.length));
        await client.from('blocked_phone_hashes').insert(batch);
        if (!mounted) return;
      }

      // profiles 업데이트
      final now = DateTime.now();
      await client.from('profiles').update({
        'contact_sync_enabled': true,
        'contact_synced_at': now.toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      setState(() {
        _enabled = true;
        _lastSyncedAt = now;
        _syncing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연락처 동기화에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _disableContactBlock() async {
    setState(() => _syncing = true);

    try {
      final user = await ref.read(currentUserProfileProvider.future);
      if (!mounted) return;
      if (user == null) {
        if (mounted) setState(() => _syncing = false);
        return;
      }

      final userId = user.id;
      final client = ref.read(supabaseClientProvider);

      // 해시 전체 삭제
      await client.from('blocked_phone_hashes').delete().eq('user_id', userId);
      if (!mounted) return;

      // profiles 업데이트
      await client.from('profiles').update({
        'contact_sync_enabled': false,
      }).eq('id', userId);

      if (!mounted) return;
      setState(() {
        _enabled = false;
        _lastSyncedAt = null;
        _syncing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 변경에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      await _syncContacts();
    } else {
      await _disableContactBlock();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            '아는 사람 피하기',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.sajuColors.textPrimary,
            ),
          ),
          subtitle: Text(
            _syncing
                ? '연락처 동기화 중...'
                : _enabled && _lastSyncedAt != null
                    ? '마지막 동기화: ${_formatDate(_lastSyncedAt!)}'
                    : '연락처에 있는 사람을 매칭에서 제외해요',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: context.sajuColors.textSecondary,
            ),
          ),
          value: _enabled,
          onChanged: (_loading || _syncing) ? null : _toggle,
        ),
        if (_enabled && !_syncing)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _syncContacts,
                child: Text(
                  '다시 동기화',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.sajuColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Task 7: Logout
// =============================================================================

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.logout,
        color: context.sajuColors.textSecondary,
      ),
      title: Text(
        '로그아웃',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.sajuColors.textPrimary,
        ),
      ),
      onTap: () => _showLogoutDialog(context, ref),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    // Capture notifier before async gap
    final authNotifier = ref.read(authNotifierProvider.notifier);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '로그아웃',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '정말 로그아웃 하시겠어요?',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.sajuColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await authNotifier.signOut();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
            child: Text(
              '로그아웃',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Task 7: Delete Account (회원 탈퇴)
// =============================================================================

class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(
        Icons.delete_forever,
        color: Colors.red,
      ),
      title: Text(
        '회원 탈퇴',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
      onTap: () => _showDeleteDialog(context, ref),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    // Capture dependencies before async gaps
    final client = ref.read(supabaseClientProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '회원 탈퇴',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없어요.\n정말 탈퇴하시겠어요?',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.sajuColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showFinalConfirmDialog(context, client, authNotifier);
            },
            child: Text(
              '탈퇴하기',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmDialog(
    BuildContext context,
    dynamic client,
    dynamic authNotifier,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '정말 탈퇴하시겠어요?',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '이 작업은 되돌릴 수 없어요.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.sajuColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final authId = client.auth.currentUser?.id;
                if (authId != null) {
                  await client.from('profiles').update({
                    'deleted_at': DateTime.now().toUtc().toIso8601String(),
                  }).eq('auth_id', authId);
                }
                if (!context.mounted) return;
                await authNotifier.signOut();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('탈퇴 처리에 실패했어요. 다시 시도해 주세요.'),
                    ),
                  );
                }
              }
            },
            child: Text(
              '네, 탈퇴할게요',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
