import 'package:flutter/material.dart';

import '../constants/home_layout.dart';

/// 홈 섹션 래퍼 — 패딩 + 등장 애니메이션을 통합 관리
///
/// 기존 `_FadeSlideSection` + `SizedBox(height: gap)` + `Padding` 3종을
/// 하나의 위젯으로 통합.
///
/// [applyHorizontalPadding] — 섹션 내부에서 직접 패딩을 관리하는 경우(그리드 등) false.
/// [staggerIndex] — 등장 딜레이 = staggerIndex × 100ms.
class HomeSection extends StatefulWidget {
  const HomeSection({
    super.key,
    required this.child,
    required this.sectionName,
    this.applyHorizontalPadding = true,
    this.staggerIndex = 0,
  });

  final Widget child;

  /// 섹션 식별자 — impression/CTA 트래킹에 사용
  final String sectionName;
  final bool applyHorizontalPadding;
  final int staggerIndex;

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    final delay = Duration(
      milliseconds: widget.staggerIndex * HomeLayout.sectionStaggerMs,
    );
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.applyHorizontalPadding) {
      content = Padding(
        padding: HomeLayout.screenPadding,
        child: content,
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: content,
      ),
    );
  }
}
