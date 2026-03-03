import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_animation.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/entities/match_profile.dart';

/// 받은 좋아요 리스트 타일
///
/// MatchListTile 기반 + 수락/건너뛰기 액션 버튼.
/// 프리미엄 좋아요는 금색 테두리로 구분.
class ReceivedLikeTile extends StatefulWidget {
  const ReceivedLikeTile({
    super.key,
    required this.like,
    required this.profile,
    required this.onAccept,
    required this.onReject,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  final Like like;
  final MatchProfile profile;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onTap;
  final Duration animationDelay;

  @override
  State<ReceivedLikeTile> createState() => _ReceivedLikeTileState();
}

class _ReceivedLikeTileState extends State<ReceivedLikeTile>
    with SingleTickerProviderStateMixin {
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
    final isPremium = widget.like.isPremium;
    final elementColor = AppTheme.fiveElementColor(profile.elementType);
    final elementPastel = AppTheme.fiveElementPastel(profile.elementType);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isPremium
                    ? AppTheme.mysticGlow.withValues(alpha: 0.4)
                    : colors.borderDefault,
                width: isPremium ? 1.5 : 1,
              ),
              boxShadow: context.sajuElevation.lowShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // 아바타
                    _buildAvatar(elementColor, elementPastel, profile),
                    SajuSpacing.hGap12,

                    // 이름 + 태그 + 시간
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isPremium) ...[
                                SajuSpacing.hGap4,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mysticGlow
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.mysticGlow,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SajuSpacing.gap4,
                          Row(
                            children: [
                              SajuBadge(
                                label: profile.characterName,
                                color: SajuColor.fromElement(
                                    profile.elementType),
                                size: SajuSize.xs,
                              ),
                              SajuSpacing.hGap4,
                              Text(
                                '${profile.compatibilityScore}% 궁합',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.compatibilityColor(
                                      profile.compatibilityScore),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          SajuSpacing.gap4,
                          Text(
                            _timeAgo(widget.like.sentAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 셰브론
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  ],
                ),

                SajuSpacing.gap12,

                // 수락/건너뛰기 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: SajuButton(
                        label: '건너뛰기',
                        onPressed: widget.onReject,
                        variant: SajuVariant.outlined,
                        color: SajuColor.primary,
                        size: SajuSize.sm,
                      ),
                    ),
                    SajuSpacing.hGap8,
                    Expanded(
                      flex: 2,
                      child: SajuButton(
                        label: '수락하기',
                        onPressed: widget.onAccept,
                        variant: SajuVariant.filled,
                        color: SajuColor.primary,
                        size: SajuSize.sm,
                        leadingIcon: Icons.favorite_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      Color elementColor, Color elementPastel, MatchProfile profile) {
    return Container(
      width: 52,
      height: 52,
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
        child: profile.characterAssetPath != null
            ? Image.asset(
                profile.characterAssetPath!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    profile.name.characters.first,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: elementColor,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  profile.name.characters.first,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: elementColor,
                  ),
                ),
              ),
      ),
    );
  }

  static String _timeAgo(DateTime sentAt) {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${sentAt.month}/${sentAt.day}';
  }
}
