import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../constants/home_layout.dart';
import 'section_header.dart';

/// 홈 섹션 5: 관상 매칭 (관상 케미)
class GwansangMatchSection extends StatelessWidget {
  const GwansangMatchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.sajuColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '관상 매칭'),
        HomeLayout.gapHeaderContent,
        GestureDetector(
          onTap: () => context.go(RoutePaths.matching),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.firePastel.withValues(alpha: 0.25),
                  AppTheme.waterPastel.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.firePastel.withValues(alpha: 0.4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 24,
                          color: AppTheme.fireColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '관상으로 보는 우리의 케미는?',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '리더십 · 따뜻함 · 독립성 · 섬세함 · 에너지',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '나와 케미 좋은 관상 TOP 3',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TraitChip(
                        icon: Icons.shield_outlined,
                        label: '리더십',
                        value: '높음'),
                    const SizedBox(width: 16),
                    _TraitChip(
                        icon: Icons.favorite_outline,
                        label: '따뜻함',
                        value: '높음'),
                    const SizedBox(width: 16),
                    _TraitChip(
                        icon: Icons.bolt_outlined,
                        label: '에너지',
                        value: '중간'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '관상 매칭 보러가기',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: context.sajuColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: textTheme.labelSmall),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: context.sajuColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
