import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_animation.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/match_profile.dart';

/// 분석 완료 후 매칭 프로필 리스트 타일
///
/// 수평 레이아웃: 아바타 | 이름+태그 | 궁합점수+프로그레스바 | 셰브론
/// [isBestMatch]가 true이면 하단에 "Best Match" 배지를 표시한다.
class MatchListTile extends StatefulWidget {
  const MatchListTile({
    super.key,
    required this.profile,
    this.isBestMatch = false,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  final MatchProfile profile;
  final bool isBestMatch;
  final VoidCallback? onTap;
  final Duration animationDelay;

  @override
  State<MatchListTile> createState() => _MatchListTileState();
}

class _MatchListTileState extends State<MatchListTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: SajuAnimation.entrance,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: SajuAnimation.entrance,
      ),
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sajuColors;
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profile;
    final elementColor = AppTheme.fiveElementColor(profile.elementType);
    final elementPastel = AppTheme.fiveElementPastel(profile.elementType);
    final scoreColor = AppTheme.compatibilityColor(profile.compatibilityScore);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Semantics(
          button: true,
          label:
              '${profile.name}, ${profile.age}세, 궁합 ${profile.compatibilityScore}점',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1.0,
              duration: SajuAnimation.fast,
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _pressed ? 0.9 : 1.0,
                duration: SajuAnimation.fast,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: widget.isBestMatch
                          ? AppTheme.compatibilityExcellent
                              .withValues(alpha: 0.4)
                          : colors.borderDefault,
                      width: widget.isBestMatch ? 1.5 : 1,
                    ),
                    boxShadow: context.sajuElevation.mediumShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // 아바타
                          _buildAvatar(
                              elementColor, elementPastel, profile),
                          SajuSpacing.hGap12,

                          // 이름 + 태그
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SajuSpacing.gap4,
                                Text(
                                  _elementKorean(profile.elementType),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                SajuSpacing.gap8,
                                Row(
                                  children: [
                                    SajuBadge(
                                      label: profile.characterName,
                                      color: SajuColor.fromElement(
                                          profile.elementType),
                                      size: SajuSize.xs,
                                    ),
                                    if (profile.animalType !=
                                        null) ...[
                                      SajuSpacing.hGap4,
                                      SajuBadge(
                                        label:
                                            profile.animalType!,
                                        color: SajuColor.primary,
                                        size: SajuSize.xs,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SajuSpacing.hGap8,

                          // 점수 + 프로그레스 바 + 셰브론
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${profile.compatibilityScore}%',
                                style:
                                    textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MiniProgressBar(
                                score:
                                    profile.compatibilityScore,
                                color: scoreColor,
                              ),
                              SajuSpacing.gap8,
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: colors.textTertiary,
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Best Match 배지
                      if (widget.isBestMatch) ...[
                        SajuSpacing.gap12,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.compatibilityExcellent
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color:
                                    AppTheme.compatibilityExcellent,
                              ),
                              SajuSpacing.hGap4,
                              Text(
                                'Best Match',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme
                                      .compatibilityExcellent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      Color elementColor, Color elementPastel, MatchProfile profile) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            elementPastel.withValues(alpha: 0.5),
            elementPastel,
          ],
        ),
        border: Border.all(
          color: elementColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: profile.photoUrl != null
            ? Image.network(
                profile.photoUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildAvatarFallback(elementColor, profile),
              )
            : _buildAvatarFallback(elementColor, profile),
      ),
    );
  }

  Widget _buildAvatarFallback(Color elementColor, MatchProfile profile) {
    if (profile.characterAssetPath != null) {
      return Image.asset(
        profile.characterAssetPath!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            profile.name.characters.first,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: elementColor,
            ),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        profile.name.characters.first,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: elementColor,
        ),
      ),
    );
  }

  static String _elementKorean(String type) {
    return switch (type) {
      'wood' => '나무(木)',
      'fire' => '불(火)',
      'earth' => '흙(土)',
      'metal' => '금(金)',
      'water' => '물(水)',
      _ => type,
    };
  }
}

/// 48px 너비의 미니 프로그레스 바
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Stack(
          children: [
            // Track
            Container(color: color.withValues(alpha: 0.15)),
            // Fill
            FractionallySizedBox(
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
