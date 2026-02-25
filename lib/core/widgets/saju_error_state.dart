import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/tokens/saju_spacing.dart';

/// 에러 상태 공통 위젯 — 캐릭터(당황/사과) + 메시지 + 다시 시도 CTA
///
/// 디자인 원칙: "에러 상태: 캐릭터가 당황/사과" (app-design §4.2)
/// 프로필/매칭 로드 실패 등에 사용.
class SajuErrorState extends StatelessWidget {
  const SajuErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.characterAssetPath = CharacterAssets.namuriWoodDefault,
    this.retryLabel = '다시 시도',
  });

  final String message;
  final VoidCallback onRetry;
  final String characterAssetPath;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SajuSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            SajuSpacing.gap24,
            FilledButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
