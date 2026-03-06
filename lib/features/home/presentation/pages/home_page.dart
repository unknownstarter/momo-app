import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/home_layout.dart';
import '../widgets/daily_fortune_section.dart';
import '../widgets/destiny_section.dart';
import '../widgets/greeting_section.dart';
import '../widgets/gwansang_match_section.dart';
import '../widgets/home_section.dart';
import '../widgets/my_analysis_section.dart';
import '../widgets/new_users_section.dart';
import '../widgets/received_likes_section.dart';
import '../widgets/recommendation_section.dart';

/// HomePage — 홈 탭 오케스트레이터
///
/// ## 섹션 구조 (Screen → Section → Item)
/// 1. 인사 + 캐릭터                [GreetingSection]
/// 2. 오늘의 연애운                [DailyFortuneSection]
/// 3. 내 운명 분석 (사주+관상)      [MyAnalysisSection]    — 둘 다 없으면 자동 숨김
/// 4. 운명 매칭 (궁합 85%+)         [DestinySection]       — 비어있으면 자동 숨김
/// 5. 궁합이 좋은 인연들            [RecommendationSection] — 비어있으면 자동 숨김
/// 6. 받은 좋아요                  [ReceivedLikesSection]
/// 7. 관상 매칭                    [GwansangMatchSection]  — 비어있으면 자동 숨김
/// 8. 새로 가입한 인연              [NewUsersSection]       — 비어있으면 자동 숨김
///
/// 각 섹션은 독립 위젯 파일로 분리.
/// [HomeSection] 래퍼가 패딩 + 등장 애니메이션을 통합 관리.
/// [HomeLayout] 상수가 모든 간격/크기를 중앙화.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: HomeLayout.screenTopInset),

              // ---- 1. 인사 + 캐릭터 ----
              const HomeSection(
                sectionName: 'greeting',
                staggerIndex: 0,
                child: GreetingSection(),
              ),

              HomeLayout.gapSection,

              // ---- 2. 오늘의 연애운 ----
              const HomeSection(
                sectionName: 'daily_fortune',
                staggerIndex: 1,
                child: DailyFortuneSection(),
              ),

              HomeLayout.gapSection,

              // ---- 3. 내 운명 분석 (사주 + 관상 카드) ----
              const HomeSection(
                sectionName: 'my_analysis',
                staggerIndex: 2,
                child: MyAnalysisSection(),
              ),

              // ---- 4~8: 조건부 섹션 — 빈 데이터면 간격 포함 자동 숨김 ----
              // 각 섹션이 내부에서 상단 간격을 관리하여 빈 섹션의 간격 누적을 방지.

              const HomeSection(
                sectionName: 'destiny',
                staggerIndex: 3,
                applyHorizontalPadding: false,
                child: DestinySection(),
              ),

              const HomeSection(
                sectionName: 'compatibility',
                staggerIndex: 4,
                applyHorizontalPadding: false,
                child: RecommendationSection(),
              ),

              const HomeSection(
                sectionName: 'received_likes',
                staggerIndex: 5,
                child: ReceivedLikesSection(),
              ),

              const HomeSection(
                sectionName: 'gwansang',
                staggerIndex: 6,
                applyHorizontalPadding: false,
                child: GwansangMatchSection(),
              ),

              const HomeSection(
                sectionName: 'new_users',
                staggerIndex: 7,
                applyHorizontalPadding: false,
                child: NewUsersSection(),
              ),

              // 플로팅 네비바 뒤 여백
              SizedBox(height: HomeLayout.bottomInset(context)),
            ],
          ),
        ),
      ),
    );
  }
}
