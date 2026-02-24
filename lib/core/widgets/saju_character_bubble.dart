import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// SajuCharacterBubble — 캐릭터 말풍선 컴포넌트
///
/// 가이드 메시지, 사주 해석, 빈 상태 등에서 캐릭터가 말하는 형태로
/// 정보를 전달하는 위젯이다.
///
/// Row 레이아웃: [캐릭터 원] [SizedBox(8)] [Expanded 말풍선]
///
/// ```dart
/// SajuCharacterBubble(
///   characterName: '나무리',
///   message: '안녕! 네 사주를 봐줄게~',
///   elementColor: SajuColor.wood,
///   size: SajuSize.md,
/// )
/// ```
class SajuCharacterBubble extends StatelessWidget {
  const SajuCharacterBubble({
    super.key,
    required this.characterName,
    required this.message,
    required this.elementColor,
    this.characterAssetPath,
    this.size = SajuSize.md,
  });

  /// 캐릭터 이름 (필수). 말풍선 위에 표시되고, 첫 글자가 원 안에 표시된다.
  final String characterName;

  /// 말풍선 메시지 텍스트 (필수)
  final String message;

  /// 오행 컬러 (필수). 캐릭터 원과 말풍선 색상을 결정한다.
  final SajuColor elementColor;

  /// 캐릭터 에셋 경로 (선택). 지정 시 원 안에 이미지가 표시된다.
  final String? characterAssetPath;

  /// 컴포넌트 크기. 기본값: [SajuSize.md]
  final SajuSize size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = elementColor.resolve(context);
    final pastelColor = elementColor.resolvePastel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 캐릭터 원 ---
        _buildCharacterCircle(color, pastelColor),
        const SizedBox(width: AppTheme.spacingSm),
        // --- 말풍선 ---
        Expanded(
          child: _buildSpeechBubble(context, isDark, color, pastelColor),
        ),
      ],
    );
  }

  /// 캐릭터 원: 에셋 이미지 또는 이름 첫 글자 fallback
  Widget _buildCharacterCircle(Color color, Color pastelColor) {
    final dimension = size.height;
    final firstChar = characterName.characters.first;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pastelColor,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: characterAssetPath != null
            ? Image.asset(
                characterAssetPath!,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackText(
                  firstChar, color,
                ),
              )
            : _buildFallbackText(firstChar, color),
      ),
    );
  }

  Widget _buildFallbackText(String char, Color color) {
    return Center(
      child: Text(
        char,
        style: TextStyle(
          fontSize: size.fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// 말풍선: 캐릭터 이름 + 메시지 Container
  Widget _buildSpeechBubble(
    BuildContext context,
    bool isDark,
    Color color,
    Color pastelColor,
  ) {
    // 말풍선 배경: 다크 모드이면 color alpha 0.1, 라이트 모드이면 pastel alpha 0.6
    final bubbleBg = isDark
        ? color.withValues(alpha: 0.1)
        : pastelColor.withValues(alpha: 0.6);

    // 말풍선 border: 1px, color alpha 0.15
    final bubbleBorder = Border.all(
      color: color.withValues(alpha: 0.15),
      width: 1,
    );

    // 말풍선 모서리: topLeft = 0 (speech bubble effect), 나머지 = radiusLg
    const bubbleRadius = BorderRadius.only(
      topLeft: Radius.zero,
      topRight: Radius.circular(AppTheme.radiusLg),
      bottomLeft: Radius.circular(AppTheme.radiusLg),
      bottomRight: Radius.circular(AppTheme.radiusLg),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 캐릭터 이름 (작은 글씨, 컬러)
        Text(
          characterName,
          style: TextStyle(
            fontSize: size.fontSize - 2,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        // 메시지 말풍선
        Container(
          padding: size.padding,
          decoration: BoxDecoration(
            color: bubbleBg,
            border: bubbleBorder,
            borderRadius: bubbleRadius,
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: size.fontSize,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}
