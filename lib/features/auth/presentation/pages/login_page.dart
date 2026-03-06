import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../providers/auth_provider.dart';

/// 로그인 페이지 — 토스 스타일 라이트 모드
///
/// 디자인 원칙:
/// - 한지 아이보리 배경, 깔끔한 화이트 기반
/// - 캐릭터 없음 — 타이포 위계만으로 브랜드 전달
/// - 상단 60%: 카피 영역 (큰 제목 + 서브카피로 시선 집중)
/// - 하단 40%: CTA 영역 (버튼 위계: filled(Apple) → filled(Kakao) → text)
/// - 넉넉한 여백, 절제된 컬러, 명확한 정보 위계
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isAppleLoading = false;
  bool _isKakaoLoading = false;
  bool _awaitingKakaoCallback = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Supabase auth 스트림 직접 구독 — 위젯 빌드 사이클과 무관하게 동작
    // 카카오 OAuth 브라우저가 열려 있어도 딥링크 수신 시 확실히 감지
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint('[LoginPage] onAuthStateChange: ${data.event}');
        if (_awaitingKakaoCallback &&
            (data.event == AuthChangeEvent.signedIn ||
             data.event == AuthChangeEvent.tokenRefreshed)) {
          debugPrint('[LoginPage] 카카오 로그인 성공 감지 — 브라우저 닫기 시도');
          closeInAppWebView();
          if (mounted) {
            setState(() {
              _awaitingKakaoCallback = false;
              _isKakaoLoading = false;
            });
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // OAuth 에러 (이메일 중복 등) — 딥링크 또는 내부 에러
        debugPrint('[LoginPage] onAuthStateChange 에러: $error');
        closeInAppWebView();
        if (mounted) {
          setState(() {
            _awaitingKakaoCallback = false;
            _isKakaoLoading = false;
            _isAppleLoading = false;
          });
          _showErrorSnackBar(_friendlyErrorMessage(error));
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  /// 카카오 OAuth 브라우저에서 앱 복귀 시 인앱 브라우저 닫기 + 스피너 해제
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingKakaoCallback) {
      debugPrint('[LoginPage] 앱 resumed — 브라우저 닫기 시도');
      // 인앱 브라우저(SFSafariViewController)가 자동으로 안 닫히는 iOS 이슈 대응
      closeInAppWebView();

      // Supabase가 딥링크를 처리할 시간을 준 뒤 스피너 해제
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isKakaoLoading) {
          setState(() {
            _isKakaoLoading = false;
            _awaitingKakaoCallback = false;
          });
        }
      });
    }
  }

  bool get _isLoading => _isAppleLoading || _isKakaoLoading;

  /// Apple 로그인 — 네이티브 SDK, 동기적 결과
  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    AnalyticsService.clickAppleLoginInLogin();

    setState(() => _isAppleLoading = true);

    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.signInWithApple();
      AnalyticsService.loginSuccess(method: 'apple');

      if (!mounted) return;
      final hasProfile = await ref.read(hasProfileProvider.future);
      if (!mounted) return;

      context.go(hasProfile ? RoutePaths.home : RoutePaths.onboarding);
    } catch (e, st) {
      debugPrint('[LoginPage] Apple 로그인 에러: $e');
      debugPrint('[LoginPage] 에러 타입: ${e.runtimeType}');
      debugPrint('[LoginPage] 스택트레이스: $st');
      if (!mounted) return;
      _showErrorSnackBar(_friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  /// Kakao 로그인 — Supabase OAuth, 브라우저 기반
  ///
  /// 브라우저 오픈 후 카카오 인증 → 딥링크로 앱 복귀 →
  /// Supabase가 세션 자동 설정 → authStateProvider 변경 → 라우터 자동 리다이렉트
  Future<void> _handleKakaoSignIn() async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    AnalyticsService.clickKakaoLoginInLogin();

    setState(() => _isKakaoLoading = true);

    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final launched = await notifier.signInWithKakao();

      if (!mounted) return;

      if (launched) {
        // 브라우저 오픈 성공 → 사용자가 카카오에서 인증 후 앱 복귀 대기
        // 스피너는 didChangeAppLifecycleState에서 앱 resumed 시 해제
        _awaitingKakaoCallback = true;
      } else {
        setState(() => _isKakaoLoading = false);
        _showErrorSnackBar('카카오 로그인 페이지를 열 수 없어요');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isKakaoLoading = false);
      _showErrorSnackBar(_friendlyErrorMessage(e));
    }
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
    // AuthException: errorCode 필드로 정확히 매칭 (toString보다 신뢰성 높음)
    if (error is AuthException) {
      final code = (error.code ?? '').toLowerCase();
      final message = error.message.toLowerCase();
      if (code.contains('identity_already_exists') ||
          code.contains('user_already_exists') ||
          message.contains('already linked')) {
        return '이미 다른 방법으로 가입된 계정이에요. 기존 로그인 방법을 이용해 주세요';
      }
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('cancel')) return '로그인이 취소되었어요';
    if (msg.contains('network') || msg.contains('socket')) {
      return '네트워크 연결을 확인해 주세요';
    }
    // fallback: toString에서도 identity 충돌 감지
    if (msg.contains('identity_already_exists') ||
        msg.contains('user_already_exists') ||
        msg.contains('already linked')) {
      return '이미 다른 방법으로 가입된 계정이에요. 기존 로그인 방법을 이용해 주세요';
    }
    if (msg.contains('kakao')) {
      return '카카오 로그인에 문제가 발생했어요';
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
          '사주가 알고 있는\n나의 인연',
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
          '사주 궁합으로 찾는, 운명이 이끄는 만남',
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

  /// CTA 섹션 — 버튼 위계: Apple(검정 filled) → Kakao(옐로우 filled) → 둘러보기(text)
  Widget _buildCTASection() {
    return Column(
      children: [
        // Apple — Primary CTA (검정 filled)
        _buildAppleButton(),

        const SizedBox(height: 10),

        // Kakao — Secondary CTA (카카오 옐로우 filled)
        _buildKakaoButton(),

        const SizedBox(height: 20),

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
          onPressed: (_isAppleLoading || disabled) ? null : _handleAppleSignIn,
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

  /// 카카오 로그인 버튼 — 카카오 브랜드 가이드라인 준수
  /// 배경: #FEE500 (카카오 옐로우), 텍스트: #191919
  Widget _buildKakaoButton() {
    final disabled = _isLoading && !_isKakaoLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: (_isKakaoLoading || disabled) ? null : _handleKakaoSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEE500), // 카카오 옐로우
            foregroundColor: const Color(0xFF191919), // 카카오 텍스트
            disabledBackgroundColor: const Color(0xFFFEE500),
            disabledForegroundColor: const Color(0xFF191919).withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isKakaoLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF191919).withValues(alpha: 0.4),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/kakao_logo.svg',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '카카오로 계속하기',
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
