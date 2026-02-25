import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../providers/auth_provider.dart';

/// 로그인 페이지 — 신비 모드(다크) 디자인
///
/// 사주인연 앱의 첫 인상을 결정하는 페이지.
/// 다크 그라데이션 배경 위에 은은한 한지 톤의 텍스트와 버튼을 배치하여
/// "운명적 만남"이라는 앱의 핵심 내러티브를 시각적으로 전달한다.
///
/// 레이아웃 (위→아래):
/// 1. 배경: 먹색 → 짙은 먹 그라데이션 (신비 모드)
/// 2. 상단: 앱 로고 "사주인연" + 부제 "운명이 이끈 만남"
/// 3. 중앙: 오행이 캐릭터 일러스트 (placeholder)
/// 4. 하단: Apple / Google 소셜 로그인 버튼 + 둘러보기
/// 5. 맨 아래: 이용약관 동의 안내 문구
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isAppleLoading = false;
  bool _isGoogleLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isLoading => _isAppleLoading || _isGoogleLoading;

  Future<void> _handleSignIn({required bool isApple}) async {
    if (_isLoading) return;

    setState(() {
      if (isApple) {
        _isAppleLoading = true;
      } else {
        _isGoogleLoading = true;
      }
    });

    try {
      final notifier = ref.read(authNotifierProvider.notifier);

      if (isApple) {
        await notifier.signInWithApple();
      } else {
        await notifier.signInWithGoogle();
      }

      if (!mounted) return;

      // 프로필 존재 여부 확인 후 라우팅
      final hasProfile = await ref.read(hasProfileProvider.future);

      if (!mounted) return;

      if (hasProfile) {
        context.go(RoutePaths.home);
      } else {
        context.go(RoutePaths.onboarding);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyErrorMessage(e),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.fireColor.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: SajuSpacing.space16,
            vertical: SajuSpacing.space8,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('cancel')) {
      return '로그인이 취소되었어요';
    }
    if (message.contains('network') || message.contains('socket')) {
      return '네트워크 연결을 확인해 주세요';
    }
    return '로그인 중 문제가 발생했어요. 다시 시도해 주세요';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1D1E23), // 먹색 (상단)
              Color(0xFF15161A), // 짙은 먹 (중단)
              Color(0xFF1A1B20), // 약간 밝은 먹 (하단)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.only(
                left: SajuSpacing.space24,
                right: SajuSpacing.space24,
                bottom: bottomPadding > 0 ? 0 : SajuSpacing.space16,
              ),
              child: Column(
                children: [
                  // === 상단 여백 ===
                  SizedBox(height: screenSize.height * 0.08),

                  // === 앱 로고 + 부제 ===
                  _buildLogoSection(),

                  // === 중앙 캐릭터 영역 (확장) ===
                  Expanded(
                    child: _buildCharacterSection(),
                  ),

                  // === 하단 로그인 버튼 영역 ===
                  _buildLoginSection(),

                  SajuSpacing.gap16,

                  // === 이용약관 안내 ===
                  _buildTermsNotice(),

                  SajuSpacing.gap8,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 앱 로고 텍스트 + 부제
  Widget _buildLogoSection() {
    return Column(
      children: [
        // 메인 로고 텍스트
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFD4C9A8), // mysticAccent
              Color(0xFFC8B68E), // mysticGlow
              Color(0xFFD4C9A8), // mysticAccent
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            '사주인연',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              height: 1.2,
              color: Colors.white, // ShaderMask가 이 색을 대체
            ),
          ),
        ),

        SajuSpacing.gap8,

        // 부제
        Text(
          '운명이 이끈 만남',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
            height: 1.5,
            color: const Color(0xFFA09B94).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// 중앙 캐릭터 영역 — 오행이 5종 가로 배치
  Widget _buildCharacterSection() {
    const characters = [
      (CharacterAssets.namuriWoodDefault, AppTheme.woodColor),
      (CharacterAssets.bulkkoriFireDefault, AppTheme.fireColor),
      (CharacterAssets.heuksuniEarthDefault, AppTheme.earthColor),
      (CharacterAssets.soedongiMetalDefault, AppTheme.metalColor),
      (CharacterAssets.mulgyeoriWaterDefault, AppTheme.waterColor),
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 캐릭터 5종 가로 배치
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (path, color) in characters) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.auto_awesome,
                          color: color.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          SajuSpacing.gap16,

          // 은은한 장식선
          Container(
            width: 60,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.mysticGlow.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 소셜 로그인 버튼 + 둘러보기
  Widget _buildLoginSection() {
    return Column(
      children: [
        // Apple Sign In 버튼
        _AppleSignInButton(
          onPressed: () => _handleSignIn(isApple: true),
          isLoading: _isAppleLoading,
          isDisabled: _isGoogleLoading,
        ),

        const SizedBox(height: SajuSpacing.space8 + 4),

        // Google Sign In 버튼
        _GoogleSignInButton(
          onPressed: () => _handleSignIn(isApple: false),
          isLoading: _isGoogleLoading,
          isDisabled: _isAppleLoading,
        ),

        SajuSpacing.gap24,

        // 구분선 "또는"
        _buildDividerWithText('또는'),

        SajuSpacing.gap16,

        // 둘러보기 텍스트 버튼
        TextButton(
          onPressed: _isLoading ? null : () {
            // TODO: 둘러보기 모드 구현
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFA09B94),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('둘러보기'),
        ),
      ],
    );
  }

  /// "또는" 구분선
  Widget _buildDividerWithText(String text) {
    final dividerColor = const Color(0xFFA09B94).withValues(alpha: 0.2);

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFA09B94).withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 0.5)),
      ],
    );
  }

  /// 이용약관 안내 문구
  Widget _buildTermsNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space16),
      child: Text(
        '로그인하면 이용약관에 동의하는 것으로 간주합니다',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: const Color(0xFFA09B94).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// =============================================================================
// Apple Sign In 버튼
// =============================================================================

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.onPressed,
    required this.isLoading,
    required this.isDisabled,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Apple로 계속하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// =============================================================================
// Google Sign In 버튼
// =============================================================================

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
    required this.isDisabled,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8E4DF),
          side: BorderSide(
            color: const Color(0xFFA09B94).withValues(alpha: 0.3),
            width: 1,
          ),
          disabledForegroundColor:
              const Color(0xFFE8E4DF).withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFE8E4DF).withValues(alpha: 0.7),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" 로고 (텍스트 대체 — 실제 앱에서는 SVG 에셋 사용)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Google로 계속하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
