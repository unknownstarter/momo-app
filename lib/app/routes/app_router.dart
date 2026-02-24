import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/supabase_client.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/matching/presentation/pages/matching_page.dart';
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
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // 인증이 필요 없는 경로들
      const publicPaths = [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.onboarding,
      ];
      final isPublicPath = publicPaths.contains(currentPath);

      // 로그인하지 않은 상태에서 보호된 페이지 접근 시 → 로그인으로
      if (!isLoggedIn && !isPublicPath) {
        return RoutePaths.login;
      }

      // 로그인한 상태에서 로그인/스플래시 페이지 접근 시 → 홈으로
      if (isLoggedIn && (currentPath == RoutePaths.login || currentPath == RoutePaths.splash)) {
        return RoutePaths.home;
      }

      // 리다이렉트 불필요
      return null;
    },

    // --- 라우트 정의 ---
    routes: [
      // 스플래시 (앱 초기 로딩)
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
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
                    const _PlaceholderPage(title: 'Chat'),
                routes: [
                  // 채팅방
                  GoRoute(
                    path: ':roomId',
                    name: RouteNames.chatRoom,
                    builder: (context, state) {
                      final roomId = state.pathParameters['roomId']!;
                      return _PlaceholderPage(
                          title: 'Chat Room: $roomId');
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
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Profile'),
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

/// 하단 네비게이션 바가 포함된 메인 레이아웃
///
/// StatefulShellRoute.indexedStack과 함께 사용하여
/// 각 탭의 상태를 유지합니다. (탭 전환 시 스크롤 위치 등 보존)
class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // 같은 탭을 다시 누르면 해당 탭의 루트로 이동
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: '매칭',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
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
