/// 관상 브릿지 페이지 — 사주 결과 → 관상 유도 화면
///
/// 사주 분석 후 관상 분석을 유도하는 전환 페이지.
/// 다크 테마(미스틱 모드)로 신비로운 분위기를 연출하며,
/// 캐릭터 말풍선과 CTA로 자연스럽게 관상 퍼널로 진입시킨다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../saju/presentation/providers/saju_provider.dart';

/// 관상 브릿지 페이지 — 사주 결과에서 관상 분석으로 전환을 유도
class GwansangBridgePage extends ConsumerStatefulWidget {
  const GwansangBridgePage({super.key, this.sajuResult});

  /// 사주 분석 결과 (GoRouter extra)
  final dynamic sajuResult;

  @override
  ConsumerState<GwansangBridgePage> createState() => _GwansangBridgePageState();
}

class _GwansangBridgePageState extends ConsumerState<GwansangBridgePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  SajuAnalysisResult? get _sajuResult {
    if (widget.sajuResult is SajuAnalysisResult) {
      return widget.sajuResult as SajuAnalysisResult;
    }
    return null;
  }

  String get _characterName =>
      _sajuResult?.characterName ?? '나무리';

  String get _characterAssetPath =>
      _sajuResult?.characterAssetPath ?? CharacterAssets.namuriWoodDefault;

  SajuColor get _elementColor {
    final element = _sajuResult?.profile.dominantElement;
    return switch (element) {
      FiveElementType.wood => SajuColor.wood,
      FiveElementType.fire => SajuColor.fire,
      FiveElementType.earth => SajuColor.earth,
      FiveElementType.metal => SajuColor.metal,
      FiveElementType.water => SajuColor.water,
      null => SajuColor.primary,
    };
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: SajuSpacing.page,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // 캐릭터 말풍선
                        SajuCharacterBubble(
                          characterName: _characterName,
                          message:
                              '사주를 봤으니 이제 관상도 볼까?\n얼굴에서 보이는 운명의 기운을 읽어줄게!',
                          elementColor: _elementColor,
                          characterAssetPath: _characterAssetPath,
                          size: SajuSize.md,
                        ),

                        SajuSpacing.gap32,

                        // AI 관상 분석 안내 카드
                        SajuCard(
                          variant: SajuVariant.elevated,
                          content: Column(
                            children: [
                              // Face icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.mysticGlow
                                      .withValues(alpha: 0.15),
                                ),
                                child: const Icon(
                                  Icons.face_retouching_natural,
                                  size: 28,
                                  color: AppTheme.mysticGlow,
                                ),
                              ),

                              SajuSpacing.gap16,

                              // Heading
                              Text(
                                'AI 관상 분석',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),

                              SajuSpacing.gap12,

                              // Body
                              Text(
                                '정면 사진 1장으로 당신의 관상을 읽어드려요\n사주와 관상을 함께 보면 운명이 더 선명해져요',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.6,
                                    ),
                              ),

                              SajuSpacing.gap16,

                              // Free badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.mysticGlow
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  '\u2728 무료',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.mysticGlow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        // CTA: 내 관상 알아보기
                        SajuButton(
                          label: '내 관상 알아보기',
                          onPressed: () => context.go(
                            RoutePaths.gwansangPhoto,
                            extra: widget.sajuResult,
                          ),
                          variant: SajuVariant.filled,
                          color: _elementColor,
                          size: SajuSize.lg,
                          leadingIcon: Icons.face_retouching_natural,
                        ),

                        SajuSpacing.gap12,

                        // 나중에 할게요 → 홈으로 복귀
                        SajuButton(
                          label: '나중에 할게요',
                          onPressed: () =>
                              context.go(RoutePaths.home),
                          variant: SajuVariant.ghost,
                          color: SajuColor.primary,
                          size: SajuSize.sm,
                        ),

                        SajuSpacing.gap16,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
