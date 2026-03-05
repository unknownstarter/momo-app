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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../gwansang/presentation/providers/gwansang_provider.dart';
import '../../../saju/presentation/providers/saju_provider.dart';

/// 분석 단계 데이터
const _phases = [
  _Phase('사주팔자를 한 자 한 자 풀고 있어요', '4,000년 된 비밀 노트를 꺼내는 중...'),
  _Phase('목·화·토·금·수, 어디에 힘이 실렸을까요?', '오행의 균형을 저울질하고 있어요'),
  _Phase('얼굴에서 복(福)의 기운을 찾고 있어요', '조상님이 물려주신 복을 읽는 중이에요'),
  _Phase('숨어있던 동물상이 슬슬 보여요...!', '여우? 곰? 고양이? 두근두근...'),
  _Phase('드디어 퍼즐이 맞춰지고 있어요!', '사주 × 관상, 운명의 그림이 완성돼요'),
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
    AnalyticsService.startDestinyAnalysis();
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

  /// analysisData가 비어있으면(리다이렉트 등) Supabase 프로필 DB에서 가져옴
  Map<String, dynamic>? _cachedData;

  Future<Map<String, dynamic>> _resolveData() async {
    if (_cachedData != null) return _cachedData!;

    final data = widget.analysisData;
    if (data.isNotEmpty && data['birthDate'] != null) {
      _cachedData = data;
      return data;
    }

    // 프로필 DB에서 가져오기
    final supabase = Supabase.instance.client;
    final authId = supabase.auth.currentUser?.id;
    if (authId == null) {
      _cachedData = data;
      return data;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select('id, auth_id, name, gender, birth_date, birth_time')
          .eq('auth_id', authId)
          .maybeSingle();
      if (row != null) {
        _cachedData = {
          'userId': row['id'] as String, // profiles.id (NOT authId)
          'birthDate': row['birth_date'] as String? ?? '',
          'birthTime': row['birth_time'] as String?,
          'isLunar': false,
          'userName': row['name'] as String?,
          'gender': row['gender'] == 'male' ? '남성' : '여성',
          'photoPath': data['photoPath'],
        };
        return _cachedData!;
      }
    } catch (_) {}

    _cachedData = data;
    return data;
  }

  void _startSajuAnalysis() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await _resolveData();
      if (!mounted) return;
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

  void _startGwansangAnalysis(SajuAnalysisResult sajuResult) async {
    if (_gwansangStarted) return;
    _gwansangStarted = true;

    final data = await _resolveData();
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
    if (!_animationComplete || _sajuResult == null) return;

    // 사주 완료 + (관상 완료 OR 관상 에러/미실행) + 애니메이션 완료 → 결과 페이지
    final gwansangState = ref.read(gwansangAnalysisNotifierProvider);
    final gwansangDone = _gwansangResult != null || gwansangState.hasError || !_gwansangStarted;

    if (gwansangDone) {
      _hasNavigated = true;
      AnalyticsService.completeDestinyAnalysis();
      context.go(RoutePaths.destinyResult, extra: {
        'sajuResult': _sajuResult,
        'gwansangResult': _gwansangResult, // null이면 사주만 표시
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
        AnalyticsService.completeSajuAnalysis();
        _sajuResult = next.value;
        _startGwansangAnalysis(next.value!);
      } else if (next.hasError) {
        debugPrint('[DestinyAnalysis] ❌ 사주 분석 에러: ${next.error}');
        debugPrint('[DestinyAnalysis] ❌ 스택: ${next.stackTrace}');
        setState(() {
          _hasError = true;
          _errorMessage = '사주 분석 중에 문제가 생겼어요';
        });
      }
    });

    // 관상 분석 상태 감시
    ref.listen(gwansangAnalysisNotifierProvider, (prev, next) {
      if (next.hasValue && next.value != null && _gwansangResult == null) {
        AnalyticsService.completeGwansangAnalysis();
        _gwansangResult = next.value;
        _tryNavigate();
      } else if (next.hasError) {
        debugPrint('[DestinyAnalysis] 관상 분석 실패 (graceful): ${next.error}');
        _gwansangResult = null;
        _tryNavigate();
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
            // --- 로딩 캐릭터 GIF ---
            const Spacer(flex: 2),

            Center(
              child: Image.asset(
                'assets/images/characters/loading_spinner.gif',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 8),

            // --- 안내 텍스트 ---
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

            const SizedBox(height: 60),

            // --- 단계 인디케이터 (스텝 dots) ---
            _buildStepIndicator(colors),

            const SizedBox(height: SajuSpacing.space32),

            // --- 메인 텍스트 ---
            SizedBox(
              height: 100,
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

            const SizedBox(height: SajuSpacing.space32),

            // --- 프로그레스 바 ---
            _buildProgressBar(colors),

            const Spacer(flex: 1),
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
              onPressed: () => context.go(RoutePaths.splash),
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
// 단계 데이터
// =============================================================================

class _Phase {
  const _Phase(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
