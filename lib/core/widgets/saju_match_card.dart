import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens/saju_animation.dart';
import '../theme/tokens/saju_spacing.dart';

/// MatchCard — 매칭 프로필 카드 (Production-level)
///
/// ## Layout Structure
/// ```
/// ┌─────────────────────────────┐
/// │                             │
/// │       Photo Area (60%)      │  ← Image / Element gradient placeholder
/// │                             │
/// │  [Element Badge]            │  ← TopLeft overlay, 8px inset
/// │                     [Score] │  ← TopRight overlay, 궁합 점수
/// ├─────────────────────────────┤
/// │  Name, Age                  │  ← titleSmall (14px/w600)
/// │  Bio text max 2 lines...    │  ← bodySmall (12px/w400)
/// │  목(木)           87점      │  ← labelSmall (11px) + score
/// └─────────────────────────────┘
/// ```
///
/// ## Padding Rules
/// - Photo area: 0 (edge-to-edge)
/// - Photo overlays: 8px from edges
/// - Info area: 14px horizontal, 12px top, 14px bottom
/// - Inner gaps: 4px between name-bio, 8px between bio-footer
///
/// ## States
/// - default: normal render
/// - pressed: scale(0.97) + opacity(0.9), 100ms
/// - disabled: opacity(0.4), no pointer events
/// - loading: skeleton shimmer placeholder
/// - premium: mystic glow border (1.5px gold)
///
/// ## Monetization
/// - isPremium: gold border glow → indicates premium match (유료 매칭)
/// - Score display: drives curiosity → "궁합 상세 보기" upsell
///
/// ## Animation
/// - Press: 100ms scale(0.97) easeOut
/// - Appear: 200ms fadeIn + slideUp(8px) with stagger
///
/// ## Accessibility
/// - Semantics label: "{name}, {age}세, 궁합 {score}점"
/// - onTap is wrapped in semantic button
class SajuMatchCard extends StatefulWidget {
  const SajuMatchCard({
    super.key,
    required this.name,
    required this.age,
    required this.bio,
    this.photoUrl,
    required this.characterName,
    this.characterAssetPath,
    required this.elementType,
    required this.compatibilityScore,
    this.isPremium = false,
    this.isDisabled = false,
    this.isLoading = false,
    this.showCharacterInstead = false,
    this.isNew = false,
    this.heroTag,
    this.onTap,
    this.width,
    this.height,
  });

  final String name;
  final int age;
  final String bio;
  final String? photoUrl;
  final String characterName;
  final String? characterAssetPath;
  final String elementType;
  final int compatibilityScore;
  final bool isPremium;
  final bool isDisabled;
  final bool isLoading;
  final bool showCharacterInstead;
  final bool isNew;
  final String? heroTag;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  State<SajuMatchCard> createState() => _SajuMatchCardState();
}

class _SajuMatchCardState extends State<SajuMatchCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _onTap() {
    if (widget.isDisabled || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildSkeleton(context);

    final isDark = context.isDarkMode;
    final colors = context.sajuColors;
    final elementColor = AppTheme.fiveElementColor(widget.elementType);
    final elementPastel = AppTheme.fiveElementPastel(widget.elementType);

    return Semantics(
      button: true,
      label: '${widget.name}, ${widget.age}세, 궁합 ${widget.compatibilityScore}점',
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedScale(
          scale: _isPressed ? SajuAnimation.pressedScale : 1.0,
          duration: SajuAnimation.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: widget.isDisabled ? SajuAnimation.disabledOpacity : (_isPressed ? 0.9 : 1.0),
            duration: SajuAnimation.fast,
            child: Container(
              width: widget.width,
              height: widget.height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(
                  color: widget.isPremium
                      ? AppTheme.mysticGlow.withValues(alpha: 0.6)
                      : colors.borderDefault,
                  width: widget.isPremium ? 1.5 : 1,
                ),
                boxShadow: widget.isPremium
                    ? [BoxShadow(color: AppTheme.mysticGlow.withValues(alpha: 0.12), blurRadius: 12, spreadRadius: 1)]
                    : context.sajuElevation.mediumShadow,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildPhotoArea(elementColor, elementPastel, isDark),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildInfoArea(context, elementColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea(Color elementColor, Color elementPastel, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo or character placeholder
        (widget.showCharacterInstead || widget.photoUrl == null)
            ? _buildPlaceholder(elementColor, elementPastel)
            : Image.network(
                widget.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(elementColor, elementPastel),
              ),
        // Element badge + NEW badge (top-left)
        Positioned(
          top: SajuSpacing.space8,
          left: SajuSpacing.space8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _elementLabel(widget.elementType),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: elementColor,
                  ),
                ),
              ),
              if (widget.isNew) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.fireColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Score badge (top-right)
        Positioned(
          top: SajuSpacing.space8,
          right: SajuSpacing.space8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.compatibilityColor(widget.compatibilityScore).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${widget.compatibilityScore}%',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color elementColor, Color elementPastel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [elementPastel.withValues(alpha: 0.4), elementPastel.withValues(alpha: 0.8)],
        ),
      ),
      child: Center(
        child: widget.characterAssetPath != null
            ? _wrapHero(
                Image.asset(
                  widget.characterAssetPath!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(Icons.person_rounded, size: 40, color: elementColor.withValues(alpha: 0.25)),
                ),
              )
            : Icon(Icons.person_rounded, size: 40, color: elementColor.withValues(alpha: 0.25)),
      ),
    );
  }

  Widget _wrapHero(Widget child) {
    if (widget.heroTag == null) return child;
    return Hero(
      tag: widget.heroTag!,
      flightShuttleBuilder: (_, animation, direction, fromContext, toContext) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) => toContext.widget,
        );
      },
      child: child,
    );
  }

  Widget _buildInfoArea(BuildContext context, Color elementColor) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.name}, ${widget.age}',
            style: textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SajuSpacing.gap4,
          Expanded(
            child: Text(
              widget.bio,
              style: textTheme.bodySmall?.copyWith(height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final colors = context.sajuColors;
    final shimmerBase = colors.bgSecondary;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Expanded(flex: 3, child: Container(color: shimmerBase)),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(4))),
                  SajuSpacing.gap8,
                  Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(4))),
                  SajuSpacing.gap4,
                  Container(width: 140, height: 10, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _elementLabel(String type) {
    return switch (type) {
      'wood' => '목(木)',
      'fire' => '화(火)',
      'earth' => '토(土)',
      'metal' => '금(金)',
      'water' => '수(水)',
      _ => type,
    };
  }
}
