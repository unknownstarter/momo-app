/// 관상 분석 로딩 페이지 — 분석 중 애니메이션 연출
///
/// 최소 8초간 관상 분석 과정을 단계별로 연출하며,
/// 실제 API 호출도 동시에 진행한다.
/// 애니메이션과 API 호출이 모두 완료되면 결과 페이지로 이동.
/// 다크 테마(미스틱 모드).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../saju/presentation/providers/saju_provider.dart';
import '../providers/gwansang_provider.dart';

/// 분석 단계 텍스트
const _phaseTexts = [
  '관상을 읽고 있어요...',
  '이목구비를 분석하는 중...',
  '삼정(이마\u00B7눈\u00B7턱)을 읽고 있어요...',
  '사주와 관상을 교차 분석 중...',
  '거의 다 됐어요...',
];

/// 관상 분석 로딩 페이지
class GwansangAnalysisPage extends ConsumerStatefulWidget {
  const GwansangAnalysisPage({super.key, this.analysisData});

  /// 분석에 필요한 데이터 (GoRouter extra)
  final Map<String, dynamic>? analysisData;

  @override
  ConsumerState<GwansangAnalysisPage> createState() =>
      _GwansangAnalysisPageState();
}

class _GwansangAnalysisPageState extends ConsumerState<GwansangAnalysisPage>
    with TickerProviderStateMixin {
  // 애니메이션 상태
  int _currentPhase = 0;
  bool _animationComplete = false;
  Timer? _phaseTimer;

  // 프로그레스 바
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  // 캐릭터 펄스
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // 텍스트 페이드
  late final AnimationController _textFadeController;
  late final Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 프로그레스 바: 8초에 걸쳐 0→1
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    // 캐릭터 펄스 애니메이션 (반복)
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

    // 단계 타이머 시작
    _startPhaseTimer();

    // 실제 API 호출 시작
    _startAnalysis();
  }

  void _startPhaseTimer() {
    // 각 단계 2초
    _phaseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPhase < _phaseTexts.length - 1) {
        // 텍스트 전환 애니메이션
        _textFadeController.reverse().then((_) {
          if (!mounted) return;
          setState(() => _currentPhase++);
          _textFadeController.forward();
        });
      } else {
        timer.cancel();
        setState(() => _animationComplete = true);
        _tryNavigateToResult();
      }
    });
  }

  void _startAnalysis() {
    final photoUrls =
        widget.analysisData?['photoUrls'] as List<String>? ?? [];
    final sajuResultRaw = widget.analysisData?['sajuResult'];

    SajuAnalysisResult? sajuResult;
    if (sajuResultRaw is SajuAnalysisResult) {
      sajuResult = sajuResultRaw;
    }

    // 사주 데이터를 Map으로 변환 (SajuProfile에 toJson이 없으므로 수동 구성)
    final sajuData = <String, dynamic>{};
    if (sajuResult != null) {
      final profile = sajuResult.profile;
      sajuData['dominant_element'] = profile.dominantElement?.name;
      sajuData['day_stem'] = profile.dayPillar.heavenlyStem;
      sajuData['personality_traits'] = profile.personalityTraits;
    }

    // Provider를 통해 분석 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gwansangAnalysisNotifierProvider.notifier).analyze(
            userId: widget.analysisData?['userId'] as String? ?? '',
            photoUrls: photoUrls,
            sajuData: sajuData,
            gender: widget.analysisData?['gender'] as String? ?? 'unknown',
            age: widget.analysisData?['age'] as int? ?? 25,
          );
    });
  }

  void _tryNavigateToResult() {
    if (!_animationComplete) return;

    final state = ref.read(gwansangAnalysisNotifierProvider);
    if (state.hasValue && state.value != null) {
      if (mounted) {
        context.go(RoutePaths.gwansangResult, extra: state.value);
      }
    }
    // 에러인 경우에도 이동 (결과 페이지에서 기본 데이터로 표시)
    if (state.hasError) {
      if (mounted) {
        context.go(RoutePaths.gwansangResult);
      }
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider 상태 감시
    ref.listen(gwansangAnalysisNotifierProvider, (prev, next) {
      if ((next.hasValue && next.value != null) || next.hasError) {
        _tryNavigateToResult();
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
              child: Center(
                child: Padding(
                  padding: SajuSpacing.page,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // 캐릭터 이미지 (펄스 애니메이션)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.mysticGlow.withValues(alpha: 0.08),
                            border: Border.all(
                              color:
                                  AppTheme.mysticGlow.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.mysticGlow.withValues(alpha: 0.15),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            size: 56,
                            color: AppTheme.mysticGlow,
                          ),
                        ),
                      ),

                      SajuSpacing.gap32,

                      // 단계별 텍스트 (페이드 애니메이션)
                      SizedBox(
                        height: 28,
                        child: FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Text(
                            _phaseTexts[_currentPhase],
                            key: ValueKey(_currentPhase),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      SajuSpacing.gap32,

                      // 프로그레스 바
                      Padding(
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
                                    backgroundColor:
                                        colors.bgElevated,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppTheme.mysticGlow,
                                    ),
                                  ),
                                ),
                                SajuSpacing.gap8,
                                Text(
                                  '${(_progressAnimation.value * 100).toInt()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.mysticGlow
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      SajuSpacing.gap24,

                      // 안내 캡션
                      Text(
                        '잠시만 기다려주세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                      ),

                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
