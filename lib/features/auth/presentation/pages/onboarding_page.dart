import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_form_page.dart';

/// OnboardingPage -- 온보딩 메인 컨테이너
///
/// 인트로 슬라이드를 먼저 보여준 후, "시작하기" 버튼을 누르면
/// 4단계 온보딩 폼([OnboardingFormPage])으로 전환된다.
///
/// 인트로 → 폼 전환은 내부 state로 관리하며,
/// 폼 완료 시 사주 분석 페이지([RoutePaths.sajuAnalysis])로 이동한다.
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

  // 인트로 슬라이드 데이터
  static const _introSlides = [
    _IntroSlide(
      characterName: '나무리',
      characterAsset: CharacterAssets.namuriWoodDefault,
      elementColor: SajuColor.wood,
      title: '운명의 인연을 찾아서',
      subtitle: '사주팔자로 알아보는\n나와 꼭 맞는 사람',
    ),
    _IntroSlide(
      characterName: '물결이',
      characterAsset: CharacterAssets.mulgyeoriWaterDefault,
      elementColor: SajuColor.water,
      title: '사주가 말해주는 궁합',
      subtitle: '수천 년 동양 지혜가\n당신의 인연을 이어줍니다',
    ),
    _IntroSlide(
      characterName: '불꼬리',
      characterAsset: CharacterAssets.bulkkoriFireDefault,
      elementColor: SajuColor.fire,
      title: '스와이프는 그만!',
      subtitle: '운명이 정해준 만남,\n지금 시작해볼까요?',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장에 실패했어요. 다시 시도해주세요.'),
            backgroundColor: AppTheme.fireColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: OnboardingFormPage(onComplete: _onFormComplete),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          children: [
            // --- 인트로 슬라이드 영역 ---
            Expanded(
              child: PageView.builder(
                controller: _introPageController,
                itemCount: _introSlides.length,
                onPageChanged: (index) {
                  setState(() => _currentIntroPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildIntroSlide(_introSlides[index]);
                },
              ),
            ),

            // --- 페이지 인디케이터 ---
            Padding(
              padding: const EdgeInsets.only(bottom: SajuSpacing.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _introSlides.length,
                  (index) => _buildDot(index),
                ),
              ),
            ),

            // --- CTA 버튼 ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SajuSpacing.space24,
              ),
              child: Column(
                children: [
                  SajuButton(
                    label: _currentIntroPage == _introSlides.length - 1
                        ? '시작하기'
                        : '다음',
                    onPressed: () {
                      if (_currentIntroPage < _introSlides.length - 1) {
                        _introPageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _startForm();
                      }
                    },
                    color: _introSlides[_currentIntroPage].elementColor,
                    size: SajuSize.xl,
                  ),
                  const SizedBox(height: SajuSpacing.space8),
                  SajuButton(
                    label: '건너뛰기',
                    onPressed: _startForm,
                    variant: SajuVariant.ghost,
                    color: SajuColor.primary,
                    size: SajuSize.md,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SajuSpacing.space32),
          ],
        ),
      ),
    );
  }

  /// 인트로 슬라이드 한 장 빌드
  Widget _buildIntroSlide(_IntroSlide slide) {
    final color = slide.elementColor.resolve(context);
    final pastel = slide.elementColor.resolvePastel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 캐릭터 이미지
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pastel,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                slide.characterAsset,
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    slide.characterName.characters.first,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SajuSpacing.space8),
          // 캐릭터 이름 태그
          SajuChip(
            label: slide.characterName,
            color: slide.elementColor,
            isSelected: true,
            size: SajuSize.sm,
          ),
          const SizedBox(height: SajuSpacing.space32),
          // 타이틀
          Text(
            slide.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SajuSpacing.space16),
          // 서브타이틀
          Text(
            slide.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B6B6B),
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 페이지 인디케이터 dot
  Widget _buildDot(int index) {
    final isActive = index == _currentIntroPage;
    final color = _introSlides[_currentIntroPage].elementColor.resolve(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// 인트로 슬라이드 데이터 모델
class _IntroSlide {
  const _IntroSlide({
    required this.characterName,
    required this.characterAsset,
    required this.elementColor,
    required this.title,
    required this.subtitle,
  });

  final String characterName;
  final String characterAsset;
  final SajuColor elementColor;
  final String title;
  final String subtitle;
}
