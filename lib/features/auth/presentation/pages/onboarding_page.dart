import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_form_page.dart';

/// OnboardingPage -- 온보딩 메인 컨테이너
///
/// 인트로 슬라이드(3장)를 먼저 보여준 후, "시작하기" 버튼을 누르면
/// 6단계 온보딩 폼([OnboardingFormPage])으로 전환된다.
///
/// ## 인트로 슬라이드 설계 (토스 스타일)
///
/// | Slide | 역할 | 감정 |
/// |-------|------|------|
/// | 1 | 후킹 — Pain Point 공감 | "나도 그랬어" |
/// | 2 | 와우 — 핵심 가치 제안 | "이런 게 있어?" |
/// | 3 | CTA — 행동 유도 | "해볼까?" |
///
/// 캐릭터 없음 — 타이포 위계만으로 전달.
/// 캐릭터는 온보딩 폼 단계에서 가이드로 등장할 때 의미가 생김.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  bool _showForm = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // ---------------------------------------------------------------------------
  // 인트로 슬라이드 데이터 — Hook → Wow → CTA 퍼널
  // ---------------------------------------------------------------------------
  static const _introSlides = [
    _IntroSlide(
      title: '200번 스와이프해도\n못 찾은 그 사람',
      subtitle: '사주가 이미 알고 있었어요',
      accentColor: Color(0xFFB8A080), // 황토 골드
      icon: null,
    ),
    _IntroSlide(
      title: '3분이면 알 수 있는\n나의 연애 사주',
      subtitle: '조상님 덕에 쌓인 사주, AI가 풀어드려요',
      accentColor: Color(0xFF89B0CB), // 쪽빛 하늘 (water)
      icon: Icons.auto_awesome_outlined,
    ),
    _IntroSlide(
      title: '사주 궁합이 좋은 사람,\n먼저 만나볼래요?',
      subtitle: '수천 년 이어진 인연의 지혜가 여기 있어요',
      accentColor: Color(0xFFD4918E), // 연지 핑크 (fire)
      icon: null,
    ),
  ];

  final _introPageController = PageController();
  int _currentIntroPage = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _introPageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startForm() {
    setState(() => _showForm = true);
    _fadeController.forward();
  }

  Future<void> _onFormComplete(Map<String, dynamic> formData) async {
    try {
      final user = await ref
          .read(onboardingNotifierProvider.notifier)
          .saveOnboardingData(formData);
      if (mounted) {
        final analysisData = <String, dynamic>{
          'userId': user.id,
          'birthDate': formData['birthDate'] as String?,
          'birthTime': formData['birthTime'] as String?,
          'isLunar': false,
          'userName': formData['name'] as String?,
          'gender': formData['gender'] as String?,
          'photoPath': formData['photoPath'] as String?,
        };
        context.go(RoutePaths.destinyAnalysis, extra: analysisData);
      }
    } catch (e) {
      if (!mounted) return;

      // TODO(PROD): 디버그 바이패스 제거 — Supabase 연결 후 이 블록 삭제
      // [BYPASS-2] 프로필 저장 실패 시 Mock 데이터로 분석 진행
      if (kDebugMode) {
        final analysisData = <String, dynamic>{
          'userId': 'dev-mock-user-001',
          'birthDate': formData['birthDate'] as String? ?? '1995-03-15',
          'birthTime': formData['birthTime'] as String? ?? '14:00',
          'isLunar': false,
          'userName': formData['name'] as String? ?? '테스트',
          'gender': formData['gender'] as String? ?? '남성',
          'photoPath': formData['photoPath'] as String?,
        };
        context.go(RoutePaths.destinyAnalysis, extra: analysisData);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 저장에 실패했어요. 다시 시도해주세요.'),
          backgroundColor: AppTheme.fireColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Stack으로 인트로 슬라이드 위에 폼을 겹쳐서 fade-in.
    // 인트로가 배경으로 남아 있으므로 검은 화면이 비치지 않는다.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: Stack(
        children: [
          // --- 인트로 슬라이드 (배경으로 유지) ---
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: bottomPadding > 0 ? 4 : SajuSpacing.space16,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _introPageController,
                      itemCount: _introSlides.length,
                      onPageChanged: (index) {
                        setState(() => _currentIntroPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildIntroSlide(_introSlides[index], index);
                      },
                    ),
                  ),

                  // --- 하단 영역: 인디케이터 + 버튼 ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SajuSpacing.space24,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _introSlides.length,
                            (index) => _buildDot(index),
                          ),
                        ),

                        const SizedBox(height: SajuSpacing.space32),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentIntroPage <
                                  _introSlides.length - 1) {
                                _introPageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _startForm();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2D2D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _currentIntroPage == _introSlides.length - 1
                                  ? '시작하기'
                                  : '다음',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: SajuSpacing.space8),

                        GestureDetector(
                          onTap: _startForm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: SajuSpacing.space12,
                            ),
                            child: Text(
                              '건너뛰기',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2D2D2D)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 온보딩 폼 (인트로 위에 fade-in) ---
          if (_showForm)
            FadeTransition(
              opacity: _fadeAnimation,
              child: OnboardingFormPage(onComplete: _onFormComplete),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 인트로 슬라이드 한 장 — 토스 스타일 좌정렬 타이포
  // ---------------------------------------------------------------------------

  Widget _buildIntroSlide(_IntroSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),

          // 슬라이드 2에만 작은 아이콘 배지
          if (slide.icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: slide.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                slide.icon,
                size: 24,
                color: slide.accentColor,
              ),
            ),
            const SizedBox(height: SajuSpacing.space20),
          ],

          // 메인 타이틀 — 큰 타이포
          Text(
            slide.title,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: -0.8,
              color: Color(0xFF2D2D2D),
            ),
          ),

          const SizedBox(height: SajuSpacing.space16),

          // 서브타이틀
          Text(
            slide.subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: const Color(0xFF2D2D2D).withValues(alpha: 0.5),
            ),
          ),

          // 슬라이드별 보조 요소
          if (index == 1) ...[
            const SizedBox(height: SajuSpacing.space32),
            _buildFeaturePills(),
          ],

          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide 2 보조 요소 — 핵심 기능 3가지 필(pill)
  // ---------------------------------------------------------------------------

  Widget _buildFeaturePills() {
    const features = [
      ('사주 분석', Icons.stars_outlined),
      ('AI 동물상', Icons.pets_outlined),
      ('궁합 매칭', Icons.favorite_outline),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2D2D2D).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                f.$2,
                size: 16,
                color: const Color(0xFF89B0CB),
              ),
              const SizedBox(width: 6),
              Text(
                f.$1,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4F54),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 페이지 인디케이터 dot — 미니멀 스타일
  // ---------------------------------------------------------------------------

  Widget _buildDot(int index) {
    final isActive = index == _currentIntroPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2D2D2D)
            : const Color(0xFF2D2D2D).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// =============================================================================
// 인트로 슬라이드 데이터 모델
// =============================================================================

class _IntroSlide {
  const _IntroSlide({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData? icon;
}
