import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_animation.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/like_entity.dart';
import '../../domain/entities/sent_like.dart';

/// 보낸 좋아요 리스트 타일
///
/// MatchListTile 기반 + 상태 뱃지 (대기중/수락됨/만료됨).
/// 수락됨 상태일 경우 "채팅하기" CTA 표시.
class SentLikeTile extends StatefulWidget {
  const SentLikeTile({
    super.key,
    required this.sentLike,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  final SentLike sentLike;
  final VoidCallback? onTap;
  final Duration animationDelay;

  @override
  State<SentLikeTile> createState() => _SentLikeTileState();
}

class _SentLikeTileState extends State<SentLikeTile>
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
    final profile = widget.sentLike.profile;
    final like = widget.sentLike.like;
    final elementColor = AppTheme.fiveElementColor(profile.elementType);
    final elementPastel = AppTheme.fiveElementPastel(profile.elementType);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: context.sajuElevation.lowShadow,
                ),
                child: Row(
                  children: [
                    // 아바타
                    _buildAvatar(elementColor, elementPastel, profile),
                    SajuSpacing.hGap12,

                    // 이름 + 상태
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            children: [
                              SajuBadge(
                                label: profile.characterName,
                                color: SajuColor.fromElement(
                                    profile.elementType),
                                size: SajuSize.xs,
                              ),
                              SajuSpacing.hGap4,
                              _StatusBadge(status: like.status),
                            ],
                          ),
                          SajuSpacing.gap4,
                          Text(
                            _timeAgo(like.sentAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SajuSpacing.hGap8,

                    // 우측: 점수 + 셰브론
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${profile.compatibilityScore}%',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.compatibilityColor(
                                profile.compatibilityScore),
                          ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      Color elementColor, Color elementPastel, dynamic profile) {
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

/// 좋아요 상태 뱃지
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final LikeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LikeStatus.pending => ('대기중', AppTheme.earthColor),
      LikeStatus.accepted => ('수락됨', AppTheme.woodColor),
      LikeStatus.rejected => ('거절됨', AppTheme.metalColor),
      LikeStatus.expired => ('만료됨', AppTheme.metalColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
