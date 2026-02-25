import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/saju_spacing.dart';

/// 빈 상태 공통 위젯 — 캐릭터 + 메시지 + 선택적 CTA
///
/// 디자인 원칙: "빈 상태에서 캐릭터가 위로/격려" (app-design §4.2)
/// 채팅 없음, 매칭 필터 결과 없음 등에 사용.
class SajuEmptyState extends StatelessWidget {
  const SajuEmptyState({
    super.key,
    required this.message,
    this.characterAssetPath = CharacterAssets.namuriWoodDefault,
    this.characterName = '나무리',
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String message;
  final String characterAssetPath;
  final String characterName;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SajuSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
              SajuSpacing.gap16,
            ] else
              Image.asset(
                characterAssetPath,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 72, width: 72),
              ),
            SajuSpacing.gap16,
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (subtitle != null) ...[
              SajuSpacing.gap8,
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SajuSpacing.gap24,
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
