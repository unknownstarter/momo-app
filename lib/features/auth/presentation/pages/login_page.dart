import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../providers/auth_provider.dart';

/// 로그인 페이지 — 토스 스타일 라이트 모드
///
/// 디자인 원칙:
/// - 한지 아이보리 배경, 깔끔한 화이트 기반
/// - 캐릭터 없음 — 타이포 위계만으로 브랜드 전달
/// - 상단 60%: 카피 영역 (큰 제목 + 서브카피로 시선 집중)
/// - 하단 40%: CTA 영역 (버튼 위계: filled → outlined → text)
/// - 넉넉한 여백, 절제된 컬러, 명확한 정보 위계
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
      duration: const Duration(milliseconds: 600),
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
    HapticFeedback.lightImpact();

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
      final hasProfile = await ref.read(hasProfileProvider.future);
      if (!mounted) return;

      context.go(hasProfile ? RoutePaths.home : RoutePaths.onboarding);
    } catch (e) {
      if (!mounted) return;

      // TODO(PROD): 디버그 바이패스 제거 — 실제 인증 연결 후 이 블록 삭제
      // [BYPASS-1] 로그인 인증 실패 시 온보딩으로 직행
      if (kDebugMode) {
        context.go(RoutePaths.onboarding);
        return;
      }

      _showErrorSnackBar(_friendlyErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _handleBrowse() {
    HapticFeedback.lightImpact();
    context.go(RoutePaths.home);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF3D3E45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('cancel')) return '로그인이 취소되었어요';
    if (msg.contains('network') || msg.contains('socket')) {
      return '네트워크 연결을 확인해 주세요';
    }
    if (msg.contains('client id') || msg.contains('설정되지')) {
      return 'Google 로그인이 아직 설정되지 않았어요';
    }
    return '로그인 중 문제가 발생했어요. 다시 시도해 주세요';
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3EE), // 한지 아이보리
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.only(
                left: SajuSpacing.space24,
                right: SajuSpacing.space24,
                bottom: bottomPadding > 0 ? 4 : SajuSpacing.space20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === 상단: 카피 영역 ===
                  const Spacer(flex: 3),
                  _buildCopySection(),
                  const Spacer(flex: 4),

                  // === 하단: CTA 영역 ===
                  _buildCTASection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 카피 섹션 — 타이포 위계로 브랜드 전달
  Widget _buildCopySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 브랜드명
        const Text(
          'momo',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFFB8A080), // 은은한 황토 골드
          ),
        ),

        const SizedBox(height: 16),

        // 메인 카피 — 토스 스타일 큰 텍스트
        const Text(
          '사주가 이끄는\n운명적 만남',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.35,
            letterSpacing: -0.5,
            color: Color(0xFF2D2D2D),
          ),
        ),

        const SizedBox(height: 12),

        // 서브 카피
        Text(
          '당신의 사주팔자로 찾는, 진짜 인연',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: const Color(0xFF2D2D2D).withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  /// CTA 섹션 — 버튼 위계: Apple(filled) → Google(outlined) → 둘러보기(text)
  Widget _buildCTASection() {
    return Column(
      children: [
        // Apple — Primary CTA (검정 filled)
        _buildAppleButton(),

        const SizedBox(height: 10),

        // Google — Secondary CTA (아웃라인)
        _buildGoogleButton(),

        const SizedBox(height: 20),

        // 둘러보기 — Tertiary
        GestureDetector(
          onTap: _isLoading ? null : _handleBrowse,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SajuSpacing.space16,
              vertical: SajuSpacing.space12,
            ),
            child: Text(
              '둘러보기',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D).withValues(alpha: _isLoading ? 0.2 : 0.4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 약관
        Text(
          '계속하면 이용약관 및 개인정보 처리방침에 동의하게 됩니다',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: const Color(0xFF2D2D2D).withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 버튼 위젯
  // =========================================================================

  Widget _buildAppleButton() {
    final disabled = _isLoading && !_isAppleLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: (_isAppleLoading || disabled) ? null : () => _handleSignIn(isApple: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF2D2D2D),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isAppleLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white60),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/apple_logo.svg',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Apple로 계속하기',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    final disabled = _isLoading && !_isGoogleLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: OutlinedButton(
          onPressed: (_isGoogleLoading || disabled) ? null : () => _handleSignIn(isApple: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D2D2D),
            side: BorderSide(
              color: const Color(0xFF2D2D2D).withValues(alpha: 0.12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isGoogleLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF2D2D2D).withValues(alpha: 0.4),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/google_logo.svg',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Google로 계속하기',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
