/// 통합 운명 분석 로딩 페이지 — 토스 스타일 미니멀 로딩
///
/// 온보딩에서 수집한 (이름, 성별, 생년월일시, 사진) 데이터를 기반으로
/// 사주 분석(~3s) → 관상 분석(~5s)을 순차 실행하며,
/// 하나의 깔끔한 연출 흐름(~10s)으로 보여준다.
///
/// 디자인 원칙:
/// - 캐릭터/장식 요소 없음 — 타이포 위계 + 미니멀 인디케이터
/// - 다크 배경 + 은은한 골드 악센트
/// - 단계별 텍스트가 자연스럽게 전환
/// - 토스 송금 로딩처럼 깔끔하고 신뢰감 있는 UX
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../gwansang/domain/entities/animal_type.dart';
import '../../../gwansang/domain/entities/face_measurements.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/domain/entities/saju_entity.dart';
import '../../../saju/presentation/providers/saju_provider.dart';

/// 분석 단계 데이터
const _phases = [
  _Phase('사주팔자를 풀어보고 있어요', '생년월일시를 바탕으로 사주를 계산해요'),
  _Phase('오행의 기운을 읽고 있어요', '목·화·토·금·수의 균형을 살펴봐요'),
  _Phase('당신의 관상을 분석하고 있어요', '얼굴의 이목구비 비율을 측정해요'),
  _Phase('닮은 동물상을 찾고 있어요', '10가지 동물상 중 가장 닮은 상을 찾아요'),
  _Phase('운명을 정리하고 있어요', '사주와 관상을 하나로 통합해요'),
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

  /// 텍스트 페이드
  late final AnimationController _textFadeController;

  /// 전체 페이드인
  late final AnimationController _fadeInController;

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
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.forward();

    // 텍스트 페이드
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    // 전체 페이드인
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInController.forward();
  }

  // ---------------------------------------------------------------------------
  // 단계 타이머 (2초 간격)
  // ---------------------------------------------------------------------------

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPhase < _phases.length - 1) {
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
    _textFadeController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 사주 분석 상태 감시
    ref.listen(sajuAnalysisNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && _sajuResult == null) {
        _sajuResult = next.value;
        _startGwansangAnalysis(next.value!);
      } else if (next.hasError) {
        // TODO(PROD): 디버그 바이패스 제거 — 사주 Edge Function 연결 후 이 블록 삭제
        // [BYPASS-3] 사주 분석 실패 시 Mock 결과로 진행
        if (kDebugMode) {
          final mockSaju = _createMockSajuResult();
          _sajuResult = mockSaju;
          _startGwansangAnalysis(mockSaju);
          return;
        }
        setState(() {
          _hasError = true;
          _errorMessage = '사주 분석 중에 문제가 생겼어요';
        });
      }
    });

    // 관상 분석 상태 감시
    ref.listen(gwansangAnalysisNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && _gwansangResult == null) {
        _gwansangResult = next.value;
        _tryNavigate();
      } else if (next.hasError) {
        // TODO(PROD): 디버그 바이패스 제거 — 관상 분석 API 연결 후 이 블록 삭제
        // [BYPASS-4] 관상 분석 실패 시 Mock 결과로 진행
        if (kDebugMode && _gwansangResult == null) {
          _gwansangResult = _createMockGwansangResult();
          _tryNavigate();
          return;
        }
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
              child: _hasError
                  ? _buildErrorState(colors)
                  : _buildContent(colors),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 메인 콘텐츠 — 토스 스타일 미니멀 로딩
  // ---------------------------------------------------------------------------

  Widget _buildContent(SajuColors colors) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeInController,
        curve: Curves.easeOut,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 3),

            // --- 단계 인디케이터 (스텝 dots) ---
            _buildStepIndicator(colors),

            const SizedBox(height: SajuSpacing.space32),

            // --- 메인 텍스트 ---
            SizedBox(
              height: 72,
              child: FadeTransition(
                opacity: _textFadeController,
                child: Column(
                  key: ValueKey(_currentPhase),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _phases[_currentPhase].title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.3,
                        color: Color(0xFFE8E4DF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phases[_currentPhase].subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: const Color(0xFFE8E4DF).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: SajuSpacing.space48),

            // --- 프로그레스 바 ---
            _buildProgressBar(colors),

            const Spacer(flex: 5),

            // --- 하단 안내 ---
            Center(
              child: Text(
                '잠시만 기다려 주세요',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFE8E4DF).withValues(alpha: 0.3),
                ),
              ),
            ),

            const SizedBox(height: SajuSpacing.space32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 스텝 인디케이터 — 현재 단계를 시각적으로 표시
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator(SajuColors colors) {
    return Row(
      children: List.generate(_phases.length, (index) {
        final isActive = index == _currentPhase;
        final isPast = index < _currentPhase;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? AppTheme.mysticGlow
                : isPast
                    ? AppTheme.mysticGlow.withValues(alpha: 0.4)
                    : const Color(0xFFE8E4DF).withValues(alpha: 0.1),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 프로그레스 바 — 얇고 깔끔한 라인
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar(SajuColors colors) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        final value = _progressAnimation.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 퍼센트
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.mysticGlow.withValues(alpha: 0.8),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            // 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor:
                      const Color(0xFFE8E4DF).withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.mysticGlow,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
            // 에러 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.statusError.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusError.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            SajuSpacing.gap24,
            Text(
              _errorMessage ?? '분석 중에 문제가 생겼어요',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SajuSpacing.gap8,
            Text(
              '다시 한 번 시도해 볼까요?',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
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

  // ---------------------------------------------------------------------------
  // DEV: Mock 데이터 (디버그 모드 전용)
  // ---------------------------------------------------------------------------

  SajuAnalysisResult _createMockSajuResult() {
    return SajuAnalysisResult(
      profile: SajuProfile(
        id: 'mock-saju-001',
        userId: 'dev-mock-user-001',
        yearPillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
        monthPillar: const Pillar(heavenlyStem: '을', earthlyBranch: '축'),
        dayPillar: const Pillar(heavenlyStem: '병', earthlyBranch: '인'),
        hourPillar: const Pillar(heavenlyStem: '정', earthlyBranch: '묘'),
        fiveElements: const FiveElements(
          wood: 3, fire: 2, earth: 1, metal: 1, water: 1,
        ),
        dominantElement: FiveElementType.wood,
        personalityTraits: const ['창의적', '감성적', '따뜻한', '성장지향적'],
        aiInterpretation: '갑자일주는 큰 나무와 같은 기운을 가졌어요. '
            '새로운 것을 시작하는 에너지가 넘치고, '
            '사람들을 이끄는 자연스러운 리더십이 있답니다. '
            '목(木)의 기운이 강해서 봄날처럼 따뜻하고 포용력 있는 성격이에요. '
            '다만 가끔은 너무 이상이 높아 현실과의 갭에서 고민할 수 있어요.',
        birthDateTime: DateTime(1995, 3, 15, 14, 0),
        calculatedAt: DateTime.now(),
      ),
      characterName: '나무리',
      characterAssetPath: CharacterAssets.heuksuniEarthDefault,
      characterGreeting: '안녕! 나는 나무리야. 너의 성장하는 기운이 느껴져!',
    );
  }

  GwansangAnalysisResult _createMockGwansangResult() {
    return GwansangAnalysisResult(
      profile: GwansangProfile(
        id: 'mock-gwansang-001',
        userId: 'dev-mock-user-001',
        animalType: AnimalType.fox,
        measurements: const FaceMeasurements(
          faceShape: 'oval',
          upperThird: 0.33, middleThird: 0.34, lowerThird: 0.33,
          eyeSpacing: 0.32, eyeSlant: 0.05, eyeSize: 0.14,
          noseBridgeHeight: 0.17, noseWidth: 0.28,
          mouthWidth: 0.38, lipThickness: 0.07,
          eyebrowArch: 0.03, eyebrowThickness: 0.04,
          foreheadHeight: 0.33, jawlineAngle: 0.48,
          faceSymmetry: 0.91, faceLengthRatio: 1.28,
        ),
        photoUrls: const [],
        headline: '본능적으로 분위기를 읽는 타고난 매력가',
        personalitySummary: '첫인상은 차분하지만, 알수록 매력이 넘치는 스타일이에요. '
            '상대방의 감정을 잘 읽고 그에 맞는 반응을 하는 데 탁월해요. '
            '유머 감각이 뛰어나고, 대화를 이끄는 능력이 있어요.',
        romanceSummary: '밀당의 달인이라 불릴 만큼 연애 감각이 뛰어나요. '
            '한번 마음을 주면 깊이 빠지지만, 쉽게 다가가지 않는 타입이에요. '
            '상대방이 먼저 다가오게 만드는 묘한 매력이 있어요.',
        sajuSynergy: '목(木)의 성장 에너지와 여우상의 예리한 관찰력이 만나 '
            '사람을 꿰뚫어보는 직관력이 탁월해요. '
            '새로운 인연 앞에서 본능적으로 "이 사람이다" 하는 감이 잘 맞아요.',
        charmKeywords: const ['밀당의 달인', '분위기 메이커', '감성 지능 만렙', '은근한 카리스마'],
        elementModifier: '봄바람의',
        createdAt: DateTime.now(),
      ),
      isNewAnalysis: true,
    );
  }
}

// =============================================================================
// 단계 데이터
// =============================================================================

class _Phase {
  const _Phase(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
