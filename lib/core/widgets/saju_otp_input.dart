import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/saju_animation.dart';
import 'saju_enums.dart';

/// SajuOtpInput — 6자리 OTP 개별 입력 박스
///
/// SMS 인증 코드 입력용 위젯. 한지 디자인 시스템에 맞춰 스타일링.
/// 각 칸에 한 자리씩 입력되며, 자동으로 다음 칸으로 이동한다.
/// 6자리 완성 시 [onCompleted] 콜백이 호출된다.
///
/// ```dart
/// SajuOtpInput(
///   color: SajuColor.earth,
///   onCompleted: (code) => verifyCode(code),
/// )
/// ```
class SajuOtpInput extends StatefulWidget {
  const SajuOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.color = SajuColor.earth,
    this.hasError = false,
  });

  /// OTP 자릿수 (기본 6)
  final int length;

  /// 모든 자릿수 입력 완료 시 콜백
  final ValueChanged<String> onCompleted;

  /// 오행 컬러
  final SajuColor color;

  /// 에러 상태 (shake + 빨간 보더)
  final bool hasError;

  @override
  State<SajuOtpInput> createState() => SajuOtpInputState();
}

class SajuOtpInputState extends State<SajuOtpInput>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.onKeyEvent = (_, event) => _onKeyEvent(i, event);
      return node;
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant SajuOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0);
      HapticService.error();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  /// 외부에서 OTP 입력 초기화
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  String get _currentCode =>
      _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // 붙여넣기 처리
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      // 단일 입력일 경우 현재 칸에만 첫 글자 유지
      if (digits.length == 1) {
        _controllers[index].text = digits[0];
      }
      final focusIndex = digits.length.clamp(0, widget.length - 1);
      _focusNodes[focusIndex].requestFocus();
      if (digits.length >= widget.length) {
        widget.onCompleted(_currentCode);
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      HapticService.selection();
      // 다음 칸으로 이동
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // 마지막 칸 완성
        _focusNodes[index].unfocus();
        widget.onCompleted(_currentCode);
      }
    }
    setState(() {});
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // 빈 칸에서 백스페이스 → 이전 칸으로 이동 후 삭제
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = widget.color.resolve(context);
    final errorColor = AppTheme.fireColor;

    // [FIX: I1] Row를 builder 내부에서 빌드 → 포커스/텍스트 변경 시 즉시 반영
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, _) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final isFilled = _controllers[index].text.isNotEmpty;
            final isFocused = _focusNodes[index].hasFocus;

            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.length - 1 ? 8 : 0,
              ),
              child: SizedBox(
                width: 48,
                height: 56,
                // [FIX: C1] KeyboardListener 제거 → FocusNode.onKeyEvent 사용
                child: AnimatedContainer(
                  duration: SajuAnimation.fast,
                  decoration: BoxDecoration(
                    color: widget.hasError
                        ? errorColor.withValues(alpha: 0.06)
                        : isFilled
                            ? resolvedColor.withValues(alpha: 0.08)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.hasError
                          ? errorColor
                          : isFocused
                              ? resolvedColor
                              : isFilled
                                  ? resolvedColor.withValues(alpha: 0.5)
                                  : const Color(0xFFE0DCD7),
                      width: (isFocused || widget.hasError) ? 2 : 1.5,
                    ),
                  ),
                  // [FIX: C2] maxLength 제거 → 붙여넣기 시 다중 글자 onChanged 허용
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: widget.hasError
                          ? errorColor
                          : resolvedColor,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _onChanged(index, value),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
