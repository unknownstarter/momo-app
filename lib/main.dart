import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

/// Momo — 사주 기반 소개팅 앱
///
/// Clean Architecture + Riverpod + go_router + Supabase
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
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://csjdfvxyjnpmbkjbomyf.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzamRmdnh5am5wbWJramJvbXlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNjUyNDksImV4cCI6MjA4Nzc0MTI0OX0.E3-4aMdDkzY8VGxqh_GEQXnkGAdPjDWpB8XDLQBqyek',
    ),
    authOptions: const FlutterAuthClientOptions(
      // PKCE 플로우 (소셜 로그인 리다이렉트용)
      // 딥링크 콜백은 Info.plist/AndroidManifest의 URL scheme으로 자동 처리됨
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
      child: MomoApp(),
    ),
  );
}
