import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/momo_loading.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens/saju_animation.dart';
import '../providers/notification_badge_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/matching/presentation/pages/matching_page.dart';
import '../../features/matching/presentation/pages/post_analysis_match_list_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/profile/presentation/pages/matching_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/gwansang/presentation/pages/gwansang_analysis_page.dart';
import '../../features/gwansang/presentation/pages/gwansang_bridge_page.dart';
import '../../features/gwansang/presentation/pages/gwansang_photo_page.dart';
import '../../features/gwansang/presentation/pages/gwansang_result_page.dart';
import '../../features/destiny/presentation/pages/destiny_analysis_page.dart';
import '../../features/destiny/presentation/pages/destiny_result_page.dart';
import '../../features/matching/presentation/pages/profile_detail_page.dart';
import '../../features/matching/domain/entities/match_profile.dart';
import '../../features/saju/presentation/pages/saju_analysis_page.dart';
import '../../features/saju/presentation/pages/saju_result_page.dart';
import '../../features/saju/presentation/providers/saju_provider.dart';

part 'app_router.g.dart';

// =============================================================================
// 인증 상태 감시 (go_router 리다이렉트용)
// =============================================================================

/// go_router가 인증 상태 변경 시 자동으로 리다이렉트하도록
/// Listenable을 구현한 인증 상태 노티파이어
class RouterAuthNotifier extends ChangeNotifier {
  RouterAuthNotifier(this._ref) {
    // Supabase 인증 상태 스트림을 구독
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
    // 유저 프로필 변경 시 리다이렉트 재평가 (퍼널 게이트)
    _ref.listen(currentUserProfileProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

// =============================================================================
// 라우터 Provider
// =============================================================================

/// go_router 인스턴스를 Riverpod으로 관리
///
/// 인증 상태가 변경되면 자동으로 refreshListenable이 트리거되어
/// redirect 로직이 재평가됩니다.
@riverpod
GoRouter appRouter(Ref ref) {
  final authNotifier = RouterAuthNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,

    // 인증 상태 변경 시 리다이렉트 재평가
    refreshListenable: authNotifier,

    // --- 글로벌 리다이렉트 로직 ---
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentPath = state.matchedLocation;

      final isLoggedIn = authState.valueOrNull != null;

      // 인증이 필요 없는 경로들 (둘러보기 모드 지원)
      const publicPaths = [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.loginCallback, // Kakao OAuth 딥링크 콜백
        RoutePaths.onboarding,
        RoutePaths.home, // 둘러보기 모드
        RoutePaths.matching, // TODO(PROD): [BYPASS-8] 인증 연결 후 제거 — 비로그인 접근 차단
        RoutePaths.chat, // TODO(PROD): [BYPASS-8] 인증 연결 후 제거 — 비로그인 접근 차단
        RoutePaths.profile, // TODO(PROD): [BYPASS-8] 인증 연결 후 제거 — 비로그인 접근 차단
        RoutePaths.sajuAnalysis,
        RoutePaths.sajuResult,
        RoutePaths.destinyAnalysis,
        RoutePaths.destinyResult,
        RoutePaths.matchingProfile,
        RoutePaths.gwansangBridge,
        RoutePaths.gwansangPhoto,
        RoutePaths.gwansangAnalysis,
        RoutePaths.gwansangResult,
        RoutePaths.postAnalysisMatches,
        RoutePaths.profileDetail,
      ];
      final isPublicPath = publicPaths.contains(currentPath);

      // 로그인하지 않은 상태에서 보호된 페이지 접근 시 → 로그인으로
      if (!isLoggedIn && !isPublicPath) {
        return RoutePaths.login;
      }

      // 로그인한 상태에서 로그인/스플래시/콜백 페이지 접근 시 → 프로필 유무에 따라 분기
      if (isLoggedIn &&
          (currentPath == RoutePaths.login ||
           currentPath == RoutePaths.splash ||
           currentPath == RoutePaths.loginCallback)) {
        final profileState = ref.read(currentUserProfileProvider);
        if (profileState.hasValue) {
          // 프로필 로딩 완료 — 유무에 따라 홈/온보딩 분기
          return profileState.valueOrNull != null
              ? RoutePaths.home
              : RoutePaths.onboarding;
        }
        // 프로필 아직 로딩 중 → 콜백 페이지에서 대기
        // (currentUserProfileProvider 로딩 완료 시 RouterAuthNotifier가 재평가)
        if (currentPath != RoutePaths.loginCallback) {
          return RoutePaths.loginCallback;
        }
        return null;
      }

      // --- 퍼널 게이트: 매칭 탭 접근 제어 ---
      if (isLoggedIn && currentPath == RoutePaths.matching) {
        final userProfile = ref.read(currentUserProfileProvider).valueOrNull;
        if (userProfile != null) {
          // 사주 미완료 → 사주 분석으로
          if (!userProfile.isSajuComplete) {
            return RoutePaths.sajuAnalysis;
          }
          // 프로필 미완성 → 매칭 프로필 완성으로
          if (!userProfile.isProfileComplete) {
            return RoutePaths.matchingProfile;
          }
        }
      }

      // 리다이렉트 불필요
      return null;
    },

    // --- 라우트 정의 ---
    routes: [
      // 스플래시 (앱 초기 로딩 — 세션 복원 대기)
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _SplashPage(),
      ),

      // 온보딩
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // 로그인
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),

      // OAuth 로그인 콜백 (카카오 등 — 딥링크 복귀 후 세션 처리 대기)
      GoRoute(
        path: RoutePaths.loginCallback,
        name: RouteNames.loginCallback,
        builder: (context, state) => const _AuthCallbackPage(),
      ),

      // SMS 인증
      GoRoute(
        path: RoutePaths.phoneVerification,
        name: RouteNames.phoneVerification,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Phone Verification'),
      ),

      // --- 메인 탭 네비게이션 (ShellRoute) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 탭 1: 홈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) =>
                    const HomePage(),
              ),
            ],
          ),

          // 탭 2: 매칭
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.matching,
                name: RouteNames.matching,
                builder: (context, state) =>
                    const MatchingPage(),
                routes: [
                  // 매칭 상세
                  GoRoute(
                    path: ':matchId',
                    name: RouteNames.matchDetail,
                    builder: (context, state) {
                      final matchId = state.pathParameters['matchId']!;
                      return _PlaceholderPage(
                          title: 'Match Detail: $matchId');
                    },
                  ),
                ],
              ),
            ],
          ),

          // 탭 3: 채팅
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.chat,
                name: RouteNames.chat,
                builder: (context, state) =>
                    const ChatListPage(),
                routes: [
                  // 채팅방
                  GoRoute(
                    path: ':roomId',
                    name: RouteNames.chatRoom,
                    builder: (context, state) {
                      final roomId = state.pathParameters['roomId']!;
                      return ChatRoomPage(roomId: roomId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // 탭 4: 프로필
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // --- 독립 페이지 (탭 밖) ---

      // 사주 분석 (로딩 애니메이션)
      GoRoute(
        path: RoutePaths.sajuAnalysis,
        name: RouteNames.sajuAnalysis,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return SajuAnalysisPage(analysisData: data);
        },
      ),

      // 사주 결과
      GoRoute(
        path: RoutePaths.sajuResult,
        name: RouteNames.sajuResult,
        builder: (context, state) {
          final result = state.extra as SajuAnalysisResult?;
          return SajuResultPage(result: result);
        },
      ),

      // --- 통합 운명 분석 ---

      // 통합 분석 (사주 + 관상 순차 실행)
      GoRoute(
        path: RoutePaths.destinyAnalysis,
        name: RouteNames.destinyAnalysis,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return DestinyAnalysisPage(analysisData: data);
        },
      ),

      // 통합 결과 (TabBar [사주 | 관상])
      GoRoute(
        path: RoutePaths.destinyResult,
        name: RouteNames.destinyResult,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return DestinyResultPage(
            sajuResult: data['sajuResult'],
            gwansangResult: data['gwansangResult'],
          );
        },
      ),

      // 분석 완료 후 매칭 리스트
      GoRoute(
        path: RoutePaths.postAnalysisMatches,
        name: RouteNames.postAnalysisMatches,
        builder: (context, state) => const PostAnalysisMatchListPage(),
      ),

      // --- 관상 퍼널 ---

      // 관상 브릿지 (사주 결과 → 관상 유도)
      GoRoute(
        path: RoutePaths.gwansangBridge,
        name: RouteNames.gwansangBridge,
        builder: (context, state) {
          final sajuResult = state.extra;
          return GwansangBridgePage(sajuResult: sajuResult);
        },
      ),

      // 관상 사진 업로드
      GoRoute(
        path: RoutePaths.gwansangPhoto,
        name: RouteNames.gwansangPhoto,
        builder: (context, state) {
          final sajuResult = state.extra;
          return GwansangPhotoPage(sajuResult: sajuResult);
        },
      ),

      // 관상 분석 (로딩 애니메이션)
      GoRoute(
        path: RoutePaths.gwansangAnalysis,
        name: RouteNames.gwansangAnalysis,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return GwansangAnalysisPage(analysisData: data);
        },
      ),

      // 관상 결과 (동물상 리빌)
      GoRoute(
        path: RoutePaths.gwansangResult,
        name: RouteNames.gwansangResult,
        builder: (context, state) {
          final result = state.extra;
          return GwansangResultPage(result: result);
        },
      ),

      // 프로필 상세 (블러 사진 + 캐릭터 + 궁합)
      GoRoute(
        path: RoutePaths.profileDetail,
        name: RouteNames.profileDetail,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final profile = data['profile'] as MatchProfile;
          final heroTag = data['heroTag'] as String?;
          final sourceStr = data['source'] as String?;
          final likeId = data['likeId'] as String?;
          final source = switch (sourceStr) {
            'sent' => ProfileDetailSource.sent,
            'received' => ProfileDetailSource.received,
            _ => ProfileDetailSource.recommendation,
          };
          return ProfileDetailPage(
            profile: profile,
            heroTag: heroTag,
            source: source,
            likeId: likeId,
          );
        },
      ),

      // 매칭 프로필 완성 (Phase B 온보딩)
      // extra: Map<String, dynamic>? — {quickMode: bool, gwansangPhotoUrls: List<String>?}
      GoRoute(
        path: RoutePaths.matchingProfile,
        name: RouteNames.matchingProfile,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          final quickMode = data['quickMode'] as bool? ?? false;
          final gwansangPhotoUrls =
              data['gwansangPhotoUrls'] as List<String>?;
          return MatchingProfilePage(
            quickMode: quickMode,
            gwansangPhotoUrls: gwansangPhotoUrls,
          );
        },
      ),

      // 프로필 편집
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Edit Profile'),
      ),

      // 설정
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Settings'),
      ),

      // 결제
      GoRoute(
        path: RoutePaths.payment,
        name: RouteNames.payment,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Payment'),
      ),
    ],

    // --- 에러 페이지 ---
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없어요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// 메인 스캐폴드 (하단 네비게이션)
// =============================================================================

/// _MainScaffold — 하단 네비게이션 (Production-level)
///
/// ## Layout Structure
/// ```
/// ┌─────────────────────────────────────────┐
/// │              body content                │
/// ├────┬────┬────┬────┬─────────────────────┤
/// │ 🏠 │ 💕 │ 💬 │ 👤 │                     │
/// │ 홈  │매칭│채팅│프로필│                     │ ← 4 tabs, 56px bar
/// └────┴────┴────┴────┴─────────────────────┘
/// ```
///
/// ## Padding Rules
/// - Bar height: 56px (safe area 별도)
/// - Icon: 24px, label: 10px
/// - Active indicator: pill shape, 64×32, 4px radius
/// - Badge: 16px circle (count) or 8px dot (boolean)
///
/// ## States
/// - active: filled icon + tinted pill bg + bold label
/// - inactive: outlined icon + muted label
/// - badge: red dot or count badge on icon
/// - pressed: haptic(selection) on tap
///
/// ## Animation
/// - Tab switch: icon crossfade 150ms
/// - Badge appear: scale bounce 200ms (0→1)
///
/// ## Accessibility
/// - Semantics: tab role on each item
/// - Badge count announced: "{tab} {count}개 알림"
class _MainScaffold extends ConsumerWidget {
  const _MainScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatBadge = ref.watch(chatBadgeCountProvider);
    final matchingBadge = ref.watch(matchingBadgeCountProvider);
    final isDark = context.isDarkMode;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: '홈',
        isActive: navigationShell.currentIndex == 0,
        onTap: () => _onTap(0),
      ),
      _NavItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite_rounded,
        label: '매칭',
        isActive: navigationShell.currentIndex == 1,
        badgeCount: matchingBadge,
        onTap: () => _onTap(1),
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble_rounded,
        label: '채팅',
        isActive: navigationShell.currentIndex == 2,
        badgeCount: chatBadge,
        onTap: () => _onTap(2),
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: '프로필',
        isActive: navigationShell.currentIndex == 3,
        onTap: () => _onTap(3),
      ),
    ];

    // 5-Layer iOS Glassmorphism: blur → tint → highlight → border → shadow
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SizedBox(
        height: 64 + bottomPadding + 8,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomPadding + 8,
          ),
          child: DecoratedBox(
            // Layer 5: Shadow
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: isDark ? 0.30 : 0.06),
                  blurRadius: isDark ? 20.0 : 16.0,
                  offset: Offset(0, isDark ? 6.0 : 4.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // Layer 1: Blur only
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                // Layer 2: Tint overlay + Layer 4: Border
                child: Container(
                  decoration: BoxDecoration(
                    // 유리처럼 맑게 — 상단 밝고 하단 살짝 어둡게 (유리 굴절 느낌)
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.05),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.10),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFC8A96E).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.7),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Layer 3: Inner highlight (상단 빛 반사 — 유리 하이라이트)
                      Positioned(
                        top: 0, left: 0.5, right: 0.5,
                        height: 0.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFC8A96E).withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      // Nav items
                      Row(children: navItems),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Individual nav bar item with icon, label, optional badge, bounce animation
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.sajuColors.textPrimary;
    final inactiveColor = context.sajuColors.textSecondary;

    return Expanded(
      child: Semantics(
        label: widget.badgeCount > 0
            ? '${widget.label} ${widget.badgeCount}개 알림'
            : widget.label,
        button: true,
        selected: widget.isActive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _pressed ? 0.85 : 1.0),
            duration: _pressed
                ? SajuAnimation.fast
                : const Duration(milliseconds: 350),
            curve: _pressed ? Curves.easeInOut : Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with optional badge
                SizedBox(
                  width: 40,
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Pill background for active tab
                      if (widget.isActive)
                        Container(
                          width: 56,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (context.isDarkMode
                                    ? AppTheme.mysticGlow
                                    : AppTheme.waterColor)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          widget.isActive ? widget.activeIcon : widget.icon,
                          key: ValueKey(widget.isActive),
                          size: 22,
                          color:
                              widget.isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      // Badge
                      if (widget.badgeCount > 0)
                        Positioned(
                          right: -4,
                          top: -2,
                          child: _Badge(count: widget.badgeCount),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Red badge with count (99+ overflow)
class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    final isWide = count > 9;

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isWide ? 20 : 16,
          minHeight: 16,
        ),
        padding: EdgeInsets.symmetric(horizontal: isWide ? 4 : 0),
        decoration: BoxDecoration(
          color: AppTheme.statusError,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.sajuColors.bgPrimary,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 스플래시 페이지 — 브랜드 로딩
// =============================================================================

/// 앱 시작 시 세션 복원을 기다리는 동안 표시되는 브랜드 스플래시
///
/// auth 상태를 직접 감시하여:
/// - 로그인됨 → 홈으로 이동
/// - 로그인 안 됨 → 로그인으로 이동
/// - 3초 타임아웃 → 로그인으로 이동 (스트림 미방출 방지)
class _SplashPage extends ConsumerStatefulWidget {
  const _SplashPage();

  @override
  ConsumerState<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<_SplashPage> {
  @override
  void initState() {
    super.initState();
    // 타임아웃 안전장치: 3초 후에도 스플래시에 있으면 로그인으로
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final authState = ref.read(authStateProvider);
        if (authState.isLoading) {
          context.go(RoutePaths.login);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // auth 상태 감시 → 확정되면 즉시 이동
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading) {
        final isLoggedIn = next.valueOrNull != null;
        if (isLoggedIn) {
          context.go(RoutePaths.home);
        } else {
          context.go(RoutePaths.login);
        }
      }
    });

    return Scaffold(
      backgroundColor: context.sajuColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로고 텍스트
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.mysticAccent, AppTheme.mysticGlow],
              ).createShader(bounds),
              child: const Text(
                '사주인연',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '운명이 이끈 만남',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            const MomoLoading(size: 48),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// OAuth 콜백 대기 페이지
// =============================================================================

/// Kakao OAuth 등 브라우저 기반 소셜 로그인 후 딥링크로 앱 복귀 시
/// Supabase가 세션을 설정하는 동안 표시되는 로딩 페이지.
///
/// authStateProvider 변경 → RouterAuthNotifier → redirect가
/// 자동으로 홈/온보딩으로 이동시킵니다.
class _AuthCallbackPage extends ConsumerStatefulWidget {
  const _AuthCallbackPage();

  @override
  ConsumerState<_AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<_AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    // 타임아웃 안전장치: 5초 후에도 여기 있으면 로그인으로
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) context.go(RoutePaths.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sajuColors.bgPrimary,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MomoLoading(size: 48),
            SizedBox(height: 20),
            Text(
              '로그인 중이에요...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A8A8E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 임시 플레이스홀더 페이지
// =============================================================================

/// 각 피처 페이지가 구현되기 전까지 사용할 플레이스홀더
///
/// TODO: 각 피처 구현 시 실제 페이지 위젯으로 교체할 것
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '구현 예정',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
