import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/entities/compatibility_entity.dart';
import '../theme/app_theme.dart';

/// CompatibilityGauge — 궁합 점수 원형 게이지 위젯
///
/// 0~100 궁합 점수를 원형 프로그레스 바로 시각화하고,
/// 중앙에 점수와 등급 라벨을 표시한다.
/// easeOutCubic 애니메이션으로 0에서 목표 점수까지 부드럽게 채워진다.
///
/// ```dart
/// CompatibilityGauge(
///   score: 85,
///   size: 120,
///   animate: true,
/// )
/// ```
class CompatibilityGauge extends StatefulWidget {
  const CompatibilityGauge({
    super.key,
    required this.score,
    this.grade,
    this.size = 120,
    this.strokeWidth = 8,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1000),
  });

  /// 궁합 점수 (0~100)
  final int score;

  /// 궁합 등급 (미지정 시 점수에서 자동 도출)
  final CompatibilityGrade? grade;

  /// 게이지 크기 (정사각형 변 길이)
  final double size;

  /// 원형 프로그레스 바 두께
  final double strokeWidth;

  /// 애니메이션 사용 여부
  final bool animate;

  /// 애니메이션 지속 시간
  final Duration duration;

  @override
  State<CompatibilityGauge> createState() => _CompatibilityGaugeState();
}

class _CompatibilityGaugeState extends State<CompatibilityGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// 점수에서 궁합 등급을 도출한다
  CompatibilityGrade get _effectiveGrade {
    if (widget.grade != null) return widget.grade!;
    if (widget.score >= 90) return CompatibilityGrade.destined;
    if (widget.score >= 75) return CompatibilityGrade.excellent;
    if (widget.score >= 60) return CompatibilityGrade.good;
    if (widget.score >= 40) return CompatibilityGrade.average;
    return CompatibilityGrade.challenging;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CompatibilityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = AppTheme.compatibilityColor(widget.score);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: _animation.value / 100,
              progressColor: progressColor,
              trackColor: trackColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 점수 숫자 ---
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return Text(
                    '${_animation.value.round()}',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w700,
                      color: progressColor,
                      height: 1.1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              // --- 등급 라벨 ---
              Text(
                _effectiveGrade.label,
                style: TextStyle(
                  fontSize: widget.size * 0.1,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 원형 게이지 CustomPainter
///
/// - 회색 트랙 (전체 원)
/// - 컬러 프로그레스 아크 (0 → progress * 2π)
/// - 둥근 선 끝 (StrokeCap.round)
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// 0.0 ~ 1.0 진행률
  final double progress;

  /// 프로그레스 아크 색상
  final Color progressColor;

  /// 트랙(배경 원) 색상
  final Color trackColor;

  /// 선 두께
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // --- 트랙 (배경 원) ---
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // --- 프로그레스 아크 ---
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // 시작: 12시 방향 (-π/2), 스윕: progress * 2π
      const startAngle = -math.pi / 2;
      final sweepAngle = progress * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
