import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// SajuMatchCard — 매칭 프로필 카드 (토스 스타일 미니멀)
///
/// 사진 영역 + 하단 정보 영역으로 구성.
/// 오버레이 최소화, 여백 넉넉, 얇은 보더로 깔끔한 인상.
class SajuMatchCard extends StatelessWidget {
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
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elementColor = AppTheme.fiveElementColor(elementType);
    final elementPastel = AppTheme.fiveElementPastel(elementType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2B32) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isPremium
                ? AppTheme.mysticGlow.withValues(alpha: 0.6)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
            width: isPremium ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // --- 사진 영역 (60%) ---
            Expanded(
              flex: 3,
              child: _buildPhotoArea(elementColor, elementPastel),
            ),
            // --- 정보 영역 (40%) ---
            Expanded(
              flex: 2,
              child: _buildInfoArea(context, elementColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 사진: 깨끗한 영역, 오버레이 없음
  Widget _buildPhotoArea(Color elementColor, Color elementPastel) {
    return photoUrl != null
        ? Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) =>
                _buildPlaceholder(elementColor, elementPastel),
          )
        : _buildPlaceholder(elementColor, elementPastel);
  }

  /// 오행 그라데이션 placeholder — 은은한 톤
  Widget _buildPlaceholder(Color elementColor, Color elementPastel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            elementPastel.withValues(alpha: 0.4),
            elementPastel.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: characterAssetPath != null
            ? Image.asset(
                characterAssetPath!,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    _buildPlaceholderIcon(elementColor),
              )
            : _buildPlaceholderIcon(elementColor),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Color elementColor) {
    return Icon(
      Icons.person_rounded,
      size: 40,
      color: elementColor.withValues(alpha: 0.25),
    );
  }

  /// 정보 영역: 이름+나이 / 소개 / 오행+점수
  Widget _buildInfoArea(BuildContext context, Color elementColor) {
    final textTheme = Theme.of(context).textTheme;
    final scoreColor = AppTheme.compatibilityColor(compatibilityScore);

    final elementLabel = switch (elementType) {
      'wood' => '목(木)',
      'fire' => '화(火)',
      'earth' => '토(土)',
      'metal' => '금(金)',
      'water' => '수(水)',
      _ => elementType,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 이름 + 나이 ---
          Text(
            '$name, $age',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // --- 소개 ---
          Expanded(
            child: Text(
              bio,
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // --- 오행 + 궁합 점수 ---
          Row(
            children: [
              Text(
                elementLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: elementColor.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '$compatibilityScore점',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
