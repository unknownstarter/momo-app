import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

/// Saju Dating App - 사주 기반 소개팅 앱
///
/// Clean Architecture + Riverpod + go_router + Supabase
/// 모든 초기화가 완료된 후에만 앱이 시작됩니다.
Future<void> main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정 (데이팅 앱 특성상 세로가 기본)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Supabase 초기화
  // TODO: 환경변수로 관리할 것 (--dart-define 또는 .env)
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project-ref.supabase.co', // TODO: 실제 URL로 교체
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'your-anon-key-here', // TODO: 실제 키로 교체
    ),
    authOptions: const FlutterAuthClientOptions(
      // 딥링크 콜백 스킴 (소셜 로그인 리다이렉트용)
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      // 채팅 기능을 위한 Realtime 활성화
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // ProviderScope로 Riverpod 상태 관리 트리 구성
  // overrides를 통해 런타임 의존성 주입 가능
  runApp(
    const ProviderScope(
      child: SajuApp(),
    ),
  );
}
