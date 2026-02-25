import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 프로필 탭 — 내 프로필 보기
///
/// 하단 네비게이션 "프로필" 탭에서 진입.
/// 현재 사용자 정보, 완성도, 프로필 편집/설정/로그아웃 액션을 제공합니다.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => SajuErrorState(
            message: '프로필을 불러오지 못했어요',
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  '로그인이 필요해요',
                  style: textTheme.bodyLarge,
                ),
              );
            }
            return _ProfileContent(user: user);
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap24,

          // ---- 1. 프로필 헤더 (아바타 + 이름, 나이 + 내 캐릭터) ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SajuAvatar(
                  name: user.name,
                  imageUrl: user.primaryPhotoUrl,
                  size: SajuSize.xl,
                ),
                SajuSpacing.hGap16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SajuSpacing.gap4,
                      Text(
                        '${user.age}세 · ${user.gender.label}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.sajuColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 내 캐릭터 (오행 배정 전에는 기본 나무리)
                Image.asset(
                  CharacterAssets.namuriWoodDefault,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          SajuSpacing.gap32,

          // ---- 2. 프로필 완성도 ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CompletionSection(percent: user.completionPercent),
          ),

          SajuSpacing.gap16,

          // ---- 3. 한 줄 정보 (지역, 직업, MBTI) ----
          if (user.location != null ||
              user.occupation != null ||
              user.mbti != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (user.location != null)
                    SajuChip(
                      label: user.location!,
                      size: SajuSize.sm,
                    ),
                  if (user.occupation != null)
                    SajuChip(
                      label: user.occupation!,
                      size: SajuSize.sm,
                    ),
                  if (user.mbti != null)
                    SajuChip(
                      label: user.mbti!,
                      size: SajuSize.sm,
                    ),
                ],
              ),
            ),
            SajuSpacing.gap24,
          ],

          // ---- 4. 사주 분석 상태 ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SajuCard(
              content: Row(
                children: [
                  Icon(
                    user.hasSajuProfile
                        ? Icons.check_circle_outline
                        : Icons.schedule_outlined,
                    size: 20,
                    color: user.hasSajuProfile
                        ? AppTheme.woodColor
                        : context.sajuColors.textTertiary,
                  ),
                  SajuSpacing.hGap8,
                  Text(
                    user.hasSajuProfile
                        ? '사주 분석 완료'
                        : '사주 분석을 완료하면 궁합 추천을 받을 수 있어요',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              variant: SajuVariant.flat,
              padding: const EdgeInsets.symmetric(
                horizontal: SajuSpacing.space16,
                vertical: SajuSpacing.space8,
              ),
            ),
          ),

          SajuSpacing.gap32,

          // ---- 5. 메뉴 (편집, 설정, 결제) ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.edit_outlined,
                  label: '프로필 편집',
                  onTap: () => context.push(RoutePaths.editProfile),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: '설정',
                  onTap: () => context.push(RoutePaths.settings),
                ),
                _MenuTile(
                  icon: Icons.card_giftcard_outlined,
                  label: '결제·구독',
                  onTap: () => context.push(RoutePaths.payment),
                ),
              ],
            ),
          ),

          SajuSpacing.gap32,

          // ---- 6. 로그아웃 ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LogoutButton(),
          ),

          SajuSpacing.gap32,
        ],
      ),
    );
  }
}

class _CompletionSection extends StatelessWidget {
  const _CompletionSection({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '프로필 완성도',
              style: textTheme.titleSmall?.copyWith(
                color: context.sajuColors.textSecondary,
              ),
            ),
            Text(
              '$percent%',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: context.sajuColors.bgSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.woodColor.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SajuSpacing.space16,
          horizontal: SajuSpacing.space8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.sajuColors.textSecondary),
            SajuSpacing.hGap16,
            Text(
              label,
              style: textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.sajuColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () async {
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
          if (context.mounted) {
            context.go(RoutePaths.login);
          }
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: context.sajuColors.textSecondary,
      ),
      child: const Text('로그아웃'),
    );
  }
}
