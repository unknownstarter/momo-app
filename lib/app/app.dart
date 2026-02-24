import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/app_router.dart';
import '../core/theme/app_theme.dart';

/// 앱의 루트 위젯
///
/// MaterialApp.router를 사용하여 go_router 기반 선언적 라우팅을 적용합니다.
/// ConsumerWidget으로 Riverpod 상태를 직접 구독할 수 있습니다.
class SajuApp extends ConsumerWidget {
  const SajuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // go_router 인스턴스를 Riverpod provider로부터 가져옴
    // 인증 상태 변경 시 자동으로 리다이렉트 처리됨
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // --- 기본 설정 ---
      title: '사주인연',
      debugShowCheckedModeBanner: false,

      // --- 라우팅 (go_router) ---
      routerConfig: router,

      // --- 테마 ---
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // 시스템 설정 따름

      // --- 한국어 로케일 ---
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'), // 영어 폴백
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // --- 빌더: 글로벌 UI 설정 ---
      builder: (context, child) {
        // 시스템 텍스트 스케일링 제한 (접근성과 레이아웃 안정성 균형)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
