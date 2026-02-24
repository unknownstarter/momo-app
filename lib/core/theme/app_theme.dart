import 'package:flutter/material.dart';

/// 앱 테마 설정 — "한지(韓紙)" 디자인 시스템
///
/// 한국 전통 한지의 은은한 자연색을 기반으로 한 디자인 시스템.
/// - Primary: 한지 하늘색 (은은한 청색)
/// - Secondary: 한지 연분홍 (옅은 핑크)
/// - Tertiary: 먹회색 (짙은 회색)
///
/// 듀얼 무드: 라이트(캐주얼) ↔ 다크(신비) 컨텍스트 기반 전환
abstract final class AppTheme {
  // ===========================================================================
  // 컬러 시스템 — 한지 팔레트
  // ===========================================================================

  // 브랜드 시드 컬러
  static const _primarySeed = Color(0xFFA8C8E8); // 한지 하늘색
  static const _secondarySeed = Color(0xFFF2D0D5); // 한지 연분홍
  static const _tertiarySeed = Color(0xFF4A4F54); // 먹회색

  // 한지 배경 컬러
  static const _lightBackground = Color(0xFFF7F3EE); // 한지색
  static const _lightSurface = Color(0xFFFEFCF9); // 밝은 한지
  static const _lightElevated = Color(0xFFF0EDE8); // 어두운 한지
  static const _darkBackground = Color(0xFF1D1E23); // 먹색
  static const _darkSurface = Color(0xFF2A2B32); // 짙은 먹
  static const _darkCard = Color(0xFF35363F); // 밝은 먹

  // 오행 컬러 — 한지 톤 (비비드 금지)
  static const woodColor = Color(0xFF8FB89A); // 목(木) - 수묵 초록
  static const fireColor = Color(0xFFD4918E); // 화(火) - 연지 핑크
  static const earthColor = Color(0xFFC8B68E); // 토(土) - 황토 한지
  static const metalColor = Color(0xFFB8BCC0); // 금(金) - 먹탄 은회
  static const waterColor = Color(0xFF89B0CB); // 수(水) - 쪽빛 하늘

  // 오행 파스텔 (배경, 뱃지 등)
  static const woodPastel = Color(0xFFD4E4D7);
  static const firePastel = Color(0xFFF0D4D2);
  static const earthPastel = Color(0xFFE8DFC8);
  static const metalPastel = Color(0xFFE0E2E4);
  static const waterPastel = Color(0xFFC8DBEA);

  // 궁합 점수 컬러 — 한지 톤
  static const compatibilityExcellent = Color(0xFFC27A88); // 90-100: 연지색
  static const compatibilityGood = Color(0xFFC49A7C); // 70-89: 황토 살구
  static const compatibilityNormal = Color(0xFFA8B0A0); // 50-69: 회녹색
  static const compatibilityLow = Color(0xFF959EA2); // 0-49: 구색

  // 신비 모드 전용
  static const mysticGlow = Color(0xFFC8B68E); // 은은한 골드 글로우
  static const mysticAccent = Color(0xFFD4C9A8); // 밝은 황토

  /// 궁합 점수에 따른 컬러 반환
  static Color compatibilityColor(int score) {
    if (score >= 90) return compatibilityExcellent;
    if (score >= 70) return compatibilityGood;
    if (score >= 50) return compatibilityNormal;
    return compatibilityLow;
  }

  /// 오행 타입에 따른 메인 컬러 반환
  static Color fiveElementColor(String element) {
    return switch (element) {
      '목' || '木' || 'wood' => woodColor,
      '화' || '火' || 'fire' => fireColor,
      '토' || '土' || 'earth' => earthColor,
      '금' || '金' || 'metal' => metalColor,
      '수' || '水' || 'water' => waterColor,
      _ => metalColor,
    };
  }

  /// 오행 타입에 따른 파스텔 컬러 반환
  static Color fiveElementPastel(String element) {
    return switch (element) {
      '목' || '木' || 'wood' => woodPastel,
      '화' || '火' || 'fire' => firePastel,
      '토' || '土' || 'earth' => earthPastel,
      '금' || '金' || 'metal' => metalPastel,
      '수' || '水' || 'water' => waterPastel,
      _ => metalPastel,
    };
  }

  // ===========================================================================
  // 스페이싱 시스템 (4px 기반)
  // ===========================================================================

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;
  static const spacingXxl = 48.0;

  // ===========================================================================
  // Border Radius
  // ===========================================================================

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radiusFull = 999.0;

  // ===========================================================================
  // 라이트 테마 (기본 — 캐주얼 모드)
  // ===========================================================================

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // --- 컬러 스킴 ---
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      brightness: Brightness.light,
      surface: _lightSurface,
    ),

    // --- 스캐폴드 배경 ---
    scaffoldBackgroundColor: _lightBackground,

    // --- 타이포그래피 ---
    textTheme: _buildTextTheme(Brightness.light),

    // --- AppBar ---
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // --- Card ---
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),

    // --- FilledButton ---
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd + 2),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    ),

    // --- OutlinedButton ---
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd + 2),
        ),
        side: BorderSide(color: _primarySeed.withValues(alpha: 0.4)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    ),

    // --- TextButton ---
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // --- InputDecoration ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: _primarySeed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: fireColor.withValues(alpha: 0.6), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: fireColor.withValues(alpha: 0.8), width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFA0A0A0),
        fontSize: 15,
      ),
    ),

    // --- Chip ---
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),

    // --- BottomNavigationBar ---
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 64,
      indicatorColor: _primarySeed.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4F54),
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFA0A0A0),
        );
      }),
    ),

    // --- BottomSheet ---
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      backgroundColor: _lightSurface,
    ),

    // --- Dialog ---
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
      ),
    ),

    // --- SnackBar ---
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // --- Divider ---
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      space: 0,
      color: Color(0xFFE8E4DF),
    ),
  );

  // ===========================================================================
  // 다크 테마 (신비 모드 — 사주 분석, 궁합 결과)
  // ===========================================================================

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // --- 컬러 스킴 ---
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ),

    // --- 스캐폴드 배경 ---
    scaffoldBackgroundColor: _darkBackground,

    // --- 타이포그래피 ---
    textTheme: _buildTextTheme(Brightness.dark),

    // --- AppBar ---
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // --- Card ---
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      color: _darkCard,
      surfaceTintColor: Colors.transparent,
    ),

    // --- FilledButton ---
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd + 2),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    ),

    // --- OutlinedButton ---
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd + 2),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    ),

    // --- InputDecoration ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(
          color: _primarySeed.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF6B6B6B),
        fontSize: 15,
      ),
    ),

    // --- Chip ---
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),

    // --- BottomNavigationBar ---
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 0,
      height: 64,
    ),

    // --- BottomSheet ---
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      backgroundColor: _darkSurface,
    ),

    // --- Dialog ---
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
      ),
    ),

    // --- SnackBar ---
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // --- Divider ---
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      space: 0,
      color: Color(0xFF35363F),
    ),
  );

  // ===========================================================================
  // 타이포그래피 빌더
  // ===========================================================================

  /// 한국어 최적화 텍스트 테마
  ///
  /// 한국어는 영문 대비 시각적 밀도가 높으므로:
  /// - letterSpacing을 약간 넓힘 (-0.2 ~ 0)
  /// - 제목은 weight를 w700 대신 w600으로 (가독성)
  /// - 본문 lineHeight는 1.5 이상 확보
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF2D2D2D) // 짙은 먹 (순수 검정 대신)
        : const Color(0xFFE8E4DF); // 한지 백색

    final secondaryColor = brightness == Brightness.light
        ? const Color(0xFF6B6B6B) // 연한 먹
        : const Color(0xFFA09B94); // 한지 회

    return TextTheme(
      // 대형 타이틀 (사주 결과, 매칭 점수 등)
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: baseColor,
      ),

      // 섹션 제목
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: baseColor,
      ),

      // 리스트 제목, 카드 제목
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),

      // 본문
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: secondaryColor,
      ),

      // 라벨, 캡션
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: secondaryColor,
      ),
    );
  }
}
