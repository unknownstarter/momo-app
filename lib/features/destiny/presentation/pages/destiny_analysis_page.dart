/// 통합 운명 분석 로딩 페이지 — 사주 + 관상 순차 분석
///
/// 온보딩에서 수집한 (이름, 성별, 생년월일시, 사진) 데이터를 기반으로
/// 사주 분석(~3s) → 관상 분석(~5s)을 순차 실행하며,
/// 하나의 연출 흐름(~10s)으로 보여준다.
///
/// | 구간 | 시간 | 텍스트 |
/// |------|------|--------|
/// | Phase 1 | 0-2s | "사주팔자를 풀어보고 있어요..." |
/// | Phase 2 | 2-4s | "오행의 기운을 읽고 있어요..." |
/// | Phase 3 | 4-6s | "당신의 관상을 분석하고 있어요..." |
/// | Phase 4 | 6-8s | "닮은 동물상을 찾고 있어요..." |
/// | Phase 5 | 8-10s | "운명을 정리하고 있어요..." |
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/presentation/providers/saju_provider.dart';

/// 분석 단계 텍스트
const _phaseTexts = [
  '사주팔자를 풀어보고 있어요...',
  '오행의 기운을 읽고 있어요...',
  '당신의 관상을 분석하고 있어요...',
  '닮은 동물상을 찾고 있어요...',
  '운명을 정리하고 있어요...',
];

class DestinyAnalysisPage extends ConsumerStatefulWidget {
  const DestinyAnalysisPage({super.key, required this.analysisData});

  /// 온보딩에서 넘어온 분석 데이터
  ///
  /// keys: userId, birthDate, birthTime, isLunar, userName, gender, photoPath
  final Map<String, dynamic> analysisData;

  @override
  ConsumerState<DestinyAnalysisPage> createState() =>
      _DestinyAnalysisPageState();
}

class _DestinyAnalysisPageState extends ConsumerState<DestinyAnalysisPage>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 애니메이션
  // ---------------------------------------------------------------------------

  /// 프로그레스 바: 10초에 걸쳐 0→1
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  /// 캐릭터 회전
  late final AnimationController _rotationController;

  /// 펄스
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// 텍스트 페이드
  late final AnimationController _textFadeController;
  late final Animation<double> _textFadeAnimation;

  // ---------------------------------------------------------------------------
  // 상태
  // ---------------------------------------------------------------------------
  int _currentPhase = 0;
  bool _animationComplete = false;
  bool _hasNavigated = false;
  Timer? _phaseTimer;

  /// 사주 분석 결과
  SajuAnalysisResult? _sajuResult;

  /// 관상 분석 결과
  GwansangAnalysisResult? _gwansangResult;

  /// 관상 분석 시작 여부
  bool _gwansangStarted = false;

  /// 에러 상태
  bool _hasError = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // 캐릭터 데이터
  // ---------------------------------------------------------------------------
  static const _characters = [
    _CharData('나무리', CharacterAssets.namuriWoodDefault, SajuColor.wood),
    _CharData('불꼬리', CharacterAssets.bulkkoriFireDefault, SajuColor.fire),
    _CharData('흙순이', CharacterAssets.heuksuniEarthDefault, SajuColor.earth),
    _CharData('쇠동이', CharacterAssets.soedongiMetalDefault, SajuColor.metal),
    _CharData('물결이', CharacterAssets.mulgyeoriWaterDefault, SajuColor.water),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSajuAnalysis();
    _startPhaseTimer();
  }

  void _initAnimations() {
    // 프로그레스 바: 10초
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    // 캐릭터 회전 (무한)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // 펄스
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // 텍스트 페이드
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _textFadeAnimation = _textFadeController;
  }

  // ---------------------------------------------------------------------------
  // 단계 타이머 (2초 간격)
  // ---------------------------------------------------------------------------

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPhase < _phaseTexts.length - 1) {
        _textFadeController.reverse().then((_) {
          if (!mounted) return;
          setState(() => _currentPhase++);
          _textFadeController.forward();
        });
      } else {
        timer.cancel();
        setState(() => _animationComplete = true);
        _tryNavigate();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 사주 분석 시작
  // ---------------------------------------------------------------------------

  void _startSajuAnalysis() {
    final data = widget.analysisData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sajuAnalysisNotifierProvider.notifier).analyze(
            userId: data['userId'] as String? ?? '',
            birthDate: data['birthDate'] as String? ?? '',
            birthTime: data['birthTime'] as String?,
            isLunar: data['isLunar'] as bool? ?? false,
            userName: data['userName'] as String?,
          );
    });
  }

  // ---------------------------------------------------------------------------
  // 관상 분석 시작 (사주 완료 후)
  // ---------------------------------------------------------------------------

  void _startGwansangAnalysis(SajuAnalysisResult sajuResult) {
    if (_gwansangStarted) return;
    _gwansangStarted = true;

    final data = widget.analysisData;
    final photoPath = data['photoPath'] as String?;
    final gender = data['gender'] as String? ?? 'unknown';

    // 나이 계산
    final birthDateStr = data['birthDate'] as String?;
    int age = 25;
    if (birthDateStr != null) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }

    // 사주 데이터 맵 구성
    final profile = sajuResult.profile;
    final sajuData = <String, dynamic>{
      'dominant_element': profile.dominantElement?.name,
      'day_stem': profile.dayPillar.heavenlyStem,
      'personality_traits': profile.personalityTraits,
    };

    ref.read(gwansangAnalysisNotifierProvider.notifier).analyze(
          userId: data['userId'] as String? ?? '',
          photoLocalPaths: photoPath != null ? [photoPath] : [],
          sajuData: sajuData,
          gender: gender,
          age: age,
        );
  }

  // ---------------------------------------------------------------------------
  // 네비게이션
  // ---------------------------------------------------------------------------

  void _tryNavigate() {
    if (_hasNavigated || !mounted) return;

    // 둘 다 완료 + 애니메이션 완료
    if (_animationComplete && _sajuResult != null && _gwansangResult != null) {
      _hasNavigated = true;
      context.go(RoutePaths.destinyResult, extra: {
        'sajuResult': _sajuResult,
        'gwansangResult': _gwansangResult,
      });
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _progressController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 사주 분석 상태 감시
    ref.listen(sajuAnalysisNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && _sajuResult == null) {
        _sajuResult = next.value;
        // 사주 완료 → 관상 시작
        _startGwansangAnalysis(next.value!);
      } else if (next.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = '사주 분석 중에 문제가 생겼어요...';
        });
      }
    });

    // 관상 분석 상태 감시
    ref.listen(gwansangAnalysisNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && _gwansangResult == null) {
        _gwansangResult = next.value;
        _tryNavigate();
      } else if (next.hasError) {
        // 관상 에러 시에도 사주 결과만으로 진행
        _gwansangResult = null;
        if (_animationComplete && _sajuResult != null) {
          _hasNavigated = true;
          context.go(RoutePaths.destinyResult, extra: {
            'sajuResult': _sajuResult,
            'gwansangResult': null,
          });
        }
      }
    });

    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            body: SafeArea(
              child: _hasError ? _buildErrorState(colors) : _buildContent(colors),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 메인 콘텐츠
  // ---------------------------------------------------------------------------

  Widget _buildContent(SajuColors colors) {
    return Stack(
      children: [
        _buildBackgroundGlow(),
        Center(
          child: Padding(
            padding: SajuSpacing.page,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // 5캐릭터 원형 회전
                _buildCharacterCircles(),

                SajuSpacing.gap32,

                // 단계별 텍스트
                SizedBox(
                  height: 28,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Text(
                      _phaseTexts[_currentPhase],
                      key: ValueKey(_currentPhase),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SajuSpacing.gap32,

                // 프로그레스 바
                _buildProgressBar(colors),

                SajuSpacing.gap24,

                // 안내 캡션
                Text(
                  '사주와 관상을 함께 분석하고 있어요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5캐릭터 원형 회전
  // ---------------------------------------------------------------------------

  Widget _buildCharacterCircles() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 중앙 글로우
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.mysticGlow.withValues(alpha: 0.2),
                        AppTheme.mysticGlow.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // 5캐릭터
                ...List.generate(5, (i) {
                  final angle = (2 * math.pi * i / 5) +
                      (2 * math.pi * _rotationController.value);
                  const radius = 75.0;
                  final dx = radius * math.cos(angle - math.pi / 2);
                  final dy = radius * math.sin(angle - math.pi / 2);

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: _buildCharCircle(i, 48),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCharCircle(int index, double size) {
    final c = _characters[index];
    final color = c.color.resolve(context);

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
          c.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              c.name.characters.first,
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

  // ---------------------------------------------------------------------------
  // 프로그레스 바
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar(SajuColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 4,
                  backgroundColor: colors.bgElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.mysticGlow,
                  ),
                ),
              ),
              SajuSpacing.gap8,
              Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mysticGlow.withValues(alpha: 0.7),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 배경 글로우
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // 에러 상태
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(SajuColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              _errorMessage ?? '분석 중에 문제가 생겼어...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SajuSpacing.gap8,
            Text(
              '다시 한 번 시도해 볼까?',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SajuSpacing.gap32,
            SajuButton(
              label: '다시 시도하기',
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _animationComplete = false;
                  _hasNavigated = false;
                  _currentPhase = 0;
                  _sajuResult = null;
                  _gwansangResult = null;
                  _gwansangStarted = false;
                });
                _progressController.reset();
                _progressController.forward();
                _textFadeController.value = 1.0;
                _startSajuAnalysis();
                _startPhaseTimer();
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
}

// =============================================================================
// 캐릭터 데이터 (내부용)
// =============================================================================

class _CharData {
  const _CharData(this.name, this.assetPath, this.color);

  final String name;
  final String assetPath;
  final SajuColor color;
}
