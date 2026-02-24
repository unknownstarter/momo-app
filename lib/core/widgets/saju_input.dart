import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'saju_enums.dart';

/// SajuInput — 사주 디자인 시스템 텍스트 입력 컴포넌트
///
/// 한지 팔레트 디자인 시스템에 맞춰 스타일링된 텍스트 입력 필드.
/// 라벨 + TextField의 Column 레이아웃으로 구성된다.
///
/// ```dart
/// SajuInput(
///   label: '이름',
///   hint: '이름을 입력해주세요',
///   controller: ctrl,
///   errorText: '필수 입력입니다',
///   onChanged: (v) {},
///   size: SajuSize.md,
/// )
/// ```
class SajuInput extends StatelessWidget {
  const SajuInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.size = SajuSize.md,
  });

  /// 입력 필드 위에 표시할 라벨 텍스트
  final String label;

  /// 입력 필드 힌트 텍스트 (placeholder)
  final String? hint;

  /// 텍스트 입력 컨트롤러
  final TextEditingController? controller;

  /// 에러 메시지. non-null이면 에러 상태로 표시된다.
  final String? errorText;

  /// 텍스트 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 키보드 제출(완료/엔터) 콜백
  final ValueChanged<String>? onSubmitted;

  /// 키보드 타입 (text, number, email 등)
  final TextInputType? keyboardType;

  /// 비밀번호 등 텍스트 숨김 여부
  final bool obscureText;

  /// 최대 줄 수
  final int maxLines;

  /// 최대 입력 글자 수 (카운터는 숨김)
  final int? maxLength;

  /// 입력 포맷터 (숫자만 허용 등)
  final List<TextInputFormatter>? inputFormatters;

  /// 입력 필드 앞 아이콘 위젯
  final Widget? prefixIcon;

  /// 입력 필드 뒤 아이콘 위젯
  final Widget? suffixIcon;

  /// 활성/비활성 여부
  final bool enabled;

  /// 자동 포커스 여부
  final bool autofocus;

  /// 컴포넌트 크기 (xs ~ xl)
  final SajuSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: size.fontSize * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // 입력 필드
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          enabled: enabled,
          autofocus: autofocus,
          style: TextStyle(fontSize: size.fontSize),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
