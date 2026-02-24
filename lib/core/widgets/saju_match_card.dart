import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'saju_badge.dart';
import 'saju_chip.dart';
import 'saju_enums.dart';

/// SajuMatchCard — 매칭 프로필 카드 컴포넌트
///
/// 매칭 추천 목록에서 상대방의 프로필을 카드 형태로 보여주는 위젯.
/// 사진, 캐릭터, 궁합 점수, 오행 정보를 한 눈에 파악할 수 있다.
///
/// ```dart
/// SajuMatchCard(
///   name: '하늘',
///   age: 27,
///   bio: '음악과 산책을 좋아해요',
///   characterName: '나무리',
///   elementType: 'wood',
///   compatibilityScore: 85,
///   onTap: () {},
/// )
/// ```
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

  /// 상대방 이름
  final String name;

  /// 상대방 나이
  final int age;

  /// 상대방 자기소개
  final String bio;

  /// 프로필 사진 URL (미지정 시 오행 그라데이션 placeholder)
  final String? photoUrl;

  /// 오행 캐릭터 이름 (예: '나무리', '불꼬리')
  final String characterName;

  /// 캐릭터 에셋 경로 (선택)
  final String? characterAssetPath;

  /// 오행 타입: 'wood', 'fire', 'earth', 'metal', 'water'
  final String elementType;

  /// 궁합 점수 (0~100)
  final int compatibilityScore;

  /// 프리미엄 여부 — true이면 골드 테두리가 표시된다
  final bool isPremium;

  /// 카드 탭 콜백
  final VoidCallback? onTap;

  /// 카드 너비 (미지정 시 부모에 맞춤)
  final double? width;

  /// 카드 높이 (미지정 시 콘텐츠에 맞춤)
  final double? height;

  /// elementType 문자열을 SajuColor enum으로 변환
  SajuColor get _sajuColor {
    return switch (elementType) {
      'wood' => SajuColor.wood,
      'fire' => SajuColor.fire,
      'earth' => SajuColor.earth,
      'metal' => SajuColor.metal,
      'water' => SajuColor.water,
      _ => SajuColor.primary,
    };
  }

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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF35363F) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: isPremium
              ? Border.all(color: AppTheme.mysticGlow, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 사진 영역 (상단 ~65%) ---
            Flexible(
              flex: 65,
              child: _buildPhotoArea(
                context,
                elementColor,
                elementPastel,
              ),
            ),
            // --- 정보 영역 (하단 ~35%) ---
            Flexible(
              flex: 35,
              child: _buildInfoArea(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 사진 영역: 프로필 사진 또는 오행 그라데이션 placeholder
  Widget _buildPhotoArea(
    BuildContext context,
    Color elementColor,
    Color elementPastel,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // --- 사진 또는 placeholder ---
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          child: photoUrl != null
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(
                    elementColor,
                    elementPastel,
                  ),
                )
              : _buildPlaceholder(elementColor, elementPastel),
        ),

        // --- 상단 좌측: 캐릭터 아이콘 ---
        Positioned(
          top: AppTheme.spacingSm,
          left: AppTheme.spacingSm,
          child: _buildCharacterCircle(elementColor, elementPastel),
        ),

        // --- 상단 우측: 궁합 점수 뱃지 ---
        Positioned(
          top: AppTheme.spacingSm,
          right: AppTheme.spacingSm,
          child: SajuBadge(
            label: '$compatibilityScore점',
            color: _sajuColor,
            size: SajuSize.sm,
          ),
        ),
      ],
    );
  }

  /// 오행 그라데이션 placeholder
  Widget _buildPlaceholder(Color elementColor, Color elementPastel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            elementPastel,
            elementColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 48,
          color: elementColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// 캐릭터 원형 아이콘 (32px)
  Widget _buildCharacterCircle(Color elementColor, Color elementPastel) {
    const dimension = 32.0;
    final firstChar = characterName.characters.first;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: elementPastel,
        border: Border.all(
          color: elementColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: characterAssetPath != null
            ? Image.asset(
                characterAssetPath!,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    firstChar,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: elementColor,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  firstChar,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: elementColor,
                  ),
                ),
              ),
      ),
    );
  }

  /// 정보 영역: 이름, 나이, 자기소개, 오행 칩
  Widget _buildInfoArea(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 오행 한글 라벨
    final elementLabel = switch (elementType) {
      'wood' => '목(木)',
      'fire' => '화(火)',
      'earth' => '토(土)',
      'metal' => '금(金)',
      'water' => '수(水)',
      _ => elementType,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 이름 + 나이 ---
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name, $age',
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // --- 자기소개 ---
          Expanded(
            child: Text(
              bio,
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // --- 오행 칩 ---
          SajuChip(
            label: elementLabel,
            color: _sajuColor,
            size: SajuSize.xs,
          ),
        ],
      ),
    );
  }
}
