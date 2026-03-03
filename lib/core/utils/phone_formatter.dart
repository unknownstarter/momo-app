import 'package:flutter/services.dart';

/// 한국 전화번호 자동 포맷터 (010-0000-0000)
///
/// 숫자만 입력받아 자동으로 하이픈을 삽입한다.
/// 최대 11자리 (하이픈 포함 13자리).
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 최대 11자리
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      // [FIX: M1] 10자리(XXX-XXX-XXXX) vs 11자리(XXX-XXXX-XXXX)
      if (i == 3) buffer.write('-');
      if (trimmed.length <= 10 && i == 6) buffer.write('-');
      if (trimmed.length == 11 && i == 7) buffer.write('-');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();

    // [FIX: I2] 커서를 항상 끝으로 보내지 않고, 올바른 위치 계산
    final oldCursorPos = oldValue.selection.baseOffset
        .clamp(0, oldValue.text.length);
    final digitsBeforeCursor = oldValue.text
        .substring(0, oldCursorPos)
        .replaceAll(RegExp(r'\D'), '')
        .length;

    // 새로운 포맷 문자열에서 같은 수의 숫자 뒤 위치 찾기
    int newCursorPos = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != '-') digitCount++;
      newCursorPos = i + 1;
      if (digitCount >= digitsBeforeCursor) break;
    }
    // 삭제 시 커서가 숫자 수보다 뒤에 있으면 끝으로
    if (digitsBeforeCursor > trimmed.length) {
      newCursorPos = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }
}

/// 전화번호 유틸리티
class PhoneUtils {
  const PhoneUtils._();

  /// 포맷된 전화번호에서 순수 숫자만 추출
  static String stripFormatting(String formatted) {
    return formatted.replaceAll(RegExp(r'\D'), '');
  }

  /// 한국 전화번호인지 검증 (01X로 시작, 10~11자리)
  static bool isValidKorean(String phone) {
    final digits = stripFormatting(phone);
    return digits.length >= 10 &&
        digits.length <= 11 &&
        digits.startsWith('01');
  }

  /// 로컬 번호 → E.164 형식 변환 (예: 01012345678 → +821012345678)
  static String toE164(String phone) {
    final digits = stripFormatting(phone);
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+82$digits';
  }
}
