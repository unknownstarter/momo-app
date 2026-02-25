import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/saju_provider.dart';

/// SajuAnalysisPage -- 사주 분석 로딩 애니메이션 페이지
///
/// 온보딩에서 넘어온 생년월일시 데이터를 기반으로 사주 분석을 실행하면서,
/// 5캐릭터 회전 애니메이션 + 캐릭터 배정 연출을 보여준다.
///
/// 애니메이션 단계:
/// 1. (0-1.5s) 나무리 인사 말풍선
/// 2. (1.5-4.5s) 5캐릭터 원형 회전
/// 3. (4.5-5.5s) 캐릭터 하나씩 사라지고 내 캐릭터만 남음
/// 4. (5.5-6.5s) 캐릭터 바운스 + 인사
/// 5. 분석 완료 시 결과 페이지로 자동 이동
class SajuAnalysisPage extends ConsumerStatefulWidget {
  const SajuAnalysisPage({
    super.key,
    required this.analysisData,
  });

  /// 온보딩에서 넘어온 분석 데이터
  ///
  /// 키: userId, birthDate, birthTime, isLunar, userName
  final Map<String, dynamic> analysisData;

  @override
  ConsumerState<SajuAnalysisPage> createState() => _SajuAnalysisPageState();
}

class _SajuAnalysisPageState extends ConsumerState<SajuAnalysisPage>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 애니메이션 컨트롤러
  // ---------------------------------------------------------------------------

  /// Phase 1: 나무리 말풍선 페이드인 (0-1.5s)
  late final AnimationController _phase1Controller;
  late final Animation<double> _phase1Fade;

  /// Phase 2: 5캐릭터 원형 회전 (1.5-4.5s)
  late final AnimationController _rotationController;

  /// Phase 3: 캐릭터 하나씩 사라짐 (4.5-5.5s)
  late final AnimationController _phase3Controller;
  late final List<Animation<double>> _fadeOutAnimations;

  /// Phase 4: 배정 캐릭터 바운스 (5.5-6.5s)
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  /// Phase 4: 인사 텍스트 페이드인
  late final AnimationController _greetingController;
  late final Animation<double> _greetingFade;

  /// 진행 텍스트 펄스 효과
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ---------------------------------------------------------------------------
  // 상태
  // ---------------------------------------------------------------------------

  /// 현재 애니메이션 단계 (1~5)
  int _currentPhase = 0;

  /// 분석 완료 여부
  bool _analysisComplete = false;

  /// 애니메이션 완료 여부
  bool _animationComplete = false;

  /// 에러 발생 여부
  bool _hasError = false;

  /// 배정된 캐릭터 인덱스 (0-4, Phase 3에서 결정)
  int _assignedIndex = 0;

  /// 네비게이션 완료 여부 (중복 방지)
  bool _hasNavigated = false;

  // ---------------------------------------------------------------------------
  // 캐릭터 데이터
  // ---------------------------------------------------------------------------

  static const _characters = [
    _CharacterData('나무리', CharacterAssets.namuriWoodDefault, SajuColor.wood),
    _CharacterData('불꼬리', CharacterAssets.bulkkoriFireDefault, SajuColor.fire),
    _CharacterData('흙순이', CharacterAssets.heuksuniEarthDefault, SajuColor.earth),
    _CharacterData('쇠동이', CharacterAssets.soedongiMetalDefault, SajuColor.metal),
    _CharacterData('물결이', CharacterAssets.mulgyeoriWaterDefault, SajuColor.water),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnalysis();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Phase 1: 말풍선 페이드인
    _phase1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _phase1Fade = CurvedAnimation(
      parent: _phase1Controller,
      curve: Curves.easeInOut,
    );

    // Phase 2: 원형 회전 (무한 반복)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Phase 3: 캐릭터 개별 페이드아웃
    _phase3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // 5개 캐릭터에 대해 시차를 두고 사라지는 애니메이션
    _fadeOutAnimations = List.generate(5, (i) {
      final start = (i * 0.2).clamp(0.0, 0.8);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _phase3Controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });

    // Phase 4: 바운스
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Phase 4: 인사 텍스트 페이드인
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _greetingFade = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    );

    // 진행 텍스트 펄스
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// 사주 분석 시작
  void _startAnalysis() {
    final data = widget.analysisData;
    ref.read(sajuAnalysisNotifierProvider.notifier).analyze(
      userId: data['userId'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '',
      birthTime: data['birthTime'] as String?,
      isLunar: data['isLunar'] as bool? ?? false,
      userName: data['userName'] as String?,
    );
  }

  /// 애니메이션 시퀀스 실행
  Future<void> _startAnimationSequence() async {
    // Phase 1: 나무리 인사 (0-1.5s)
    setState(() => _currentPhase = 1);
    _phase1Controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Phase 2: 5캐릭터 원형 회전 (1.5-4.5s)
    setState(() => _currentPhase = 2);
    _phase1Controller.reverse(); // 말풍선 페이드아웃
    _rotationController.repeat(); // 무한 회전
    _pulseController.repeat(reverse: true); // 펄스 시작
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    // Phase 3: 캐릭터 하나씩 사라짐 (4.5-5.5s)
    setState(() => _currentPhase = 3);
    _rotationController.stop();
    _pulseController.stop();

    // 배정 캐릭터 결정 (분석 결과 있으면 그걸 사용)
    _determineAssignedCharacter();

    _phase3Controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Phase 4: 배정 캐릭터 바운스 + 인사 (5.5-6.5s)
    setState(() => _currentPhase = 4);
    _bounceController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _greetingController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // 애니메이션 완료
    _animationComplete = true;
    _tryNavigate();
  }

  /// 분석 결과에서 배정 캐릭터 인덱스 결정
  void _determineAssignedCharacter() {
    final state = ref.read(sajuAnalysisNotifierProvider);
    final result = state.valueOrNull;
    if (result != null) {
      // 캐릭터 이름으로 매칭
      final idx = _characters.indexWhere(
        (c) => c.name == result.characterName,
      );
      _assignedIndex = idx >= 0 ? idx : 0;
    } else {
      // 분석 미완료 시 랜덤 (나중에 결과 나오면 override)
      _assignedIndex = 0;
    }
  }

  /// 분석 + 애니메이션 모두 완료 시 결과 페이지로 이동
  void _tryNavigate() {
    if (_hasNavigated || !mounted) return;

    final state = ref.read(sajuAnalysisNotifierProvider);
    if (state.hasError) {
      setState(() => _hasError = true);
      return;
    }

    if (_animationComplete && state.hasValue && state.value != null) {
      _hasNavigated = true;
      context.go(RoutePaths.sajuResult, extra: state.value);
    }
  }

  @override
  void dispose() {
    _phase1Controller.dispose();
    _rotationController.dispose();
    _phase3Controller.dispose();
    _bounceController.dispose();
    _greetingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 분석 상태 감시
    ref.listen(sajuAnalysisNotifierProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _analysisComplete = true;
        // 배정 캐릭터 업데이트
        final result = next.value!;
        final idx = _characters.indexWhere(
          (c) => c.name == result.characterName,
        );
        if (idx >= 0) {
          setState(() => _assignedIndex = idx);
        }
        _tryNavigate();
      } else if (next.hasError) {
        setState(() => _hasError = true);
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.sajuColors.bgPrimary, // 먹색
              const Color(0xFF15161A), // 짙은 먹
              const Color(0xFF1A1B20), // 중간 먹
            ],
          ),
        ),
        child: SafeArea(
          child: _hasError ? _buildErrorState() : _buildAnimationContent(),
        ),
      ),
    );
  }

  Widget _buildAnimationContent() {
    return Stack(
      children: [
        // 배경 장식 (은은한 빛)
        _buildBackgroundGlow(),

        // 메인 콘텐츠
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase 1: 나무리 말풍선
              if (_currentPhase == 1) _buildPhase1(),

              // Phase 2: 5캐릭터 원형 회전
              if (_currentPhase == 2) _buildPhase2(),

              // Phase 3: 캐릭터 사라지기
              if (_currentPhase == 3) _buildPhase3(),

              // Phase 4: 배정 캐릭터 바운스 + 인사
              if (_currentPhase >= 4) _buildPhase4(),

              // 분석 대기 중 표시
              if (_currentPhase >= 4 && _animationComplete && !_analysisComplete)
                _buildWaitingIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Phase 1: 나무리 인사 말풍선
  // ===========================================================================

  Widget _buildPhase1() {
    return FadeTransition(
      opacity: _phase1Fade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 나무리 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.woodPastel.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppTheme.woodColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  _characters[0].assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      '나',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.woodColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SajuSpacing.gap16,
            // 말풍선
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SajuSpacing.space16,
                vertical: SajuSpacing.space16,
              ),
              decoration: BoxDecoration(
                color: AppTheme.woodColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.circular(AppTheme.radiusLg),
                  bottomLeft: Radius.circular(AppTheme.radiusLg),
                  bottomRight: Radius.circular(AppTheme.radiusLg),
                ),
                border: Border.all(
                  color: AppTheme.woodColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '좋아! 이제 네 사주를 볼게~',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.sajuColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Phase 2: 5캐릭터 원형 회전
  // ===========================================================================

  Widget _buildPhase2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _CircleGlowPainter(
                  progress: _rotationController.value,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(5, (i) {
                    final angle = (2 * math.pi * i / 5) +
                        (2 * math.pi * _rotationController.value);
                    const radius = 90.0;
                    final dx = radius * math.cos(angle - math.pi / 2);
                    final dy = radius * math.sin(angle - math.pi / 2);

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: _buildCharacterCircle(i, 56),
                    );
                  }),
                ),
              );
            },
          ),
        ),
        SajuSpacing.gap24,
        // 진행 텍스트 + 펄스
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _pulseAnimation.value,
              child: Text(
                '사주팔자를 분석하고 있어요...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mysticAccent,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // Phase 3: 캐릭터 하나씩 사라짐
  // ===========================================================================

  Widget _buildPhase3() {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: _phase3Controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(5, (i) {
              final angle = (2 * math.pi * i / 5);
              const radius = 90.0;
              final dx = radius * math.cos(angle - math.pi / 2);
              final dy = radius * math.sin(angle - math.pi / 2);

              // 배정 캐릭터는 사라지지 않고 중앙으로 이동
              if (i == _assignedIndex) {
                final moveProgress = _phase3Controller.value;
                final currentDx = dx * (1 - moveProgress);
                final currentDy = dy * (1 - moveProgress);
                final scale = 1.0 + (0.4 * moveProgress);

                return Transform.translate(
                  offset: Offset(currentDx, currentDy),
                  child: Transform.scale(
                    scale: scale,
                    child: _buildCharacterCircle(i, 56),
                  ),
                );
              }

              // 나머지 캐릭터는 페이드아웃
              return Transform.translate(
                offset: Offset(dx, dy),
                child: FadeTransition(
                  opacity: _fadeOutAnimations[i],
                  child: _buildCharacterCircle(i, 56),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Phase 4: 배정 캐릭터 바운스 + 인사
  // ===========================================================================

  Widget _buildPhase4() {
    final character = _characters[_assignedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 캐릭터 바운스
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: _buildCharacterCircle(_assignedIndex, 100),
            );
          },
        ),
        SajuSpacing.gap16,
        // 캐릭터 이름
        FadeTransition(
          opacity: _greetingFade,
          child: SajuBadge(
            label: character.name,
            color: character.color,
            size: SajuSize.md,
          ),
        ),
        SajuSpacing.gap16,
        // 인사 텍스트
        FadeTransition(
          opacity: _greetingFade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SajuSpacing.space16,
                vertical: SajuSpacing.space16,
              ),
              decoration: BoxDecoration(
                color: character.color.resolve(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: character.color.resolve(context).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '찾았다! 네 사주를 봤어!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.sajuColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 대기 인디케이터 (분석이 애니메이션보다 오래 걸릴 때)
  // ===========================================================================

  Widget _buildWaitingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: SajuSpacing.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.mysticGlow.withValues(alpha: 0.6),
              ),
            ),
          ),
          SajuSpacing.gap8,
          Text(
            '조금만 더 기다려 줘...',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.mysticAccent.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 에러 상태
  // ===========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 나무리 슬픈 표정
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.woodPastel.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppTheme.woodColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  _characters[0].assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      '나',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.woodColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SajuSpacing.gap16,
            Text(
              '앗, 사주 분석 중에 문제가 생겼어...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.sajuColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SajuSpacing.gap8,
            Text(
              '다시 한 번 시도해 볼까?',
              style: TextStyle(
                fontSize: 14,
                color: context.sajuColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SajuSpacing.gap32,
            SajuButton(
              label: '다시 시도하기',
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _analysisComplete = false;
                  _animationComplete = false;
                  _hasNavigated = false;
                  _currentPhase = 0;
                });
                // 컨트롤러 리셋
                _phase1Controller.reset();
                _rotationController.reset();
                _phase3Controller.reset();
                _bounceController.reset();
                _greetingController.reset();
                _pulseController.reset();
                // 재시작
                _startAnalysis();
                _startAnimationSequence();
              },
              color: SajuColor.wood,
              size: SajuSize.lg,
            ),
            SajuSpacing.gap16,
            SajuButton(
              label: '돌아가기',
              onPressed: () => context.pop(),
              variant: SajuVariant.ghost,
              color: SajuColor.metal,
              size: SajuSize.md,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 배경 글로우
  // ===========================================================================

  Widget _buildBackgroundGlow() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.mysticGlow.withValues(alpha: 0.08),
                  AppTheme.mysticGlow.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 캐릭터 원형 위젯
  // ===========================================================================

  Widget _buildCharacterCircle(int index, double size) {
    final character = _characters[index];
    final color = character.color.resolve(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          character.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              character.name.characters.first,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 원형 글로우 페인터 (Phase 2 배경 효과)
// =============================================================================

class _CircleGlowPainter extends CustomPainter {
  _CircleGlowPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 90.0;

    // 회전하는 은은한 원형 트랙
    final trackPaint = Paint()
      ..color = AppTheme.mysticGlow.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, trackPaint);

    // 회전하는 글로우 점
    final glowAngle = 2 * math.pi * progress - math.pi / 2;
    final glowX = center.dx + radius * math.cos(glowAngle);
    final glowY = center.dy + radius * math.sin(glowAngle);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.mysticGlow.withValues(alpha: 0.3),
          AppTheme.mysticGlow.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(glowX, glowY), radius: 20),
      );

    canvas.drawCircle(Offset(glowX, glowY), 20, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CircleGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// 캐릭터 데이터 (내부용)
// =============================================================================

class _CharacterData {
  const _CharacterData(this.name, this.assetPath, this.color);

  final String name;
  final String assetPath;
  final SajuColor color;
}
