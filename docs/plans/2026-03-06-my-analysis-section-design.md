# "내 운명 분석" 홈 섹션 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 홈 연애운 아래에 "내 사주 + 내 관상" 가로 2카드 상설 섹션을 추가하여 콜드 스타트 시 홈이 비어 보이지 않게 하고, 분석 결과 재진입점을 제공한다.

**Architecture:** 홈 feature 내에 `MyAnalysisSection` 위젯을 추가한다. 현재 유저의 사주/관상 데이터를 DB에서 조회하는 프로바이더를 home providers에 생성하고, 기존 repository 메서드(`getSajuProfileByUserId`, `getGwansangProfile`)를 활용한다. 캐릭터 에셋은 expressions/poses 풀에서 랜덤 선택한다.

**Tech Stack:** Flutter, Riverpod (code generation), go_router, 기존 SajuRepository/GwansangRepository

---

### Task 1: 내 분석 데이터 프로바이더 생성

**Files:**
- Create: `lib/features/home/presentation/providers/my_analysis_provider.dart`

**Step 1: 프로바이더 파일 생성**

현재 유저의 사주/관상 프로필을 DB에서 조회하는 Riverpod provider.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saju/domain/entities/saju_entity.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';

part 'my_analysis_provider.g.dart';

/// 현재 유저의 사주 + 관상 프로필 (홈 카드 표시용)
@riverpod
Future<({SajuProfile? saju, GwansangProfile? gwansang})> myAnalysis(Ref ref) async {
  final user = await ref.watch(currentUserProfileProvider.future);
  if (user == null) return (saju: null, gwansang: null);

  final sajuDs = ref.watch(sajuRemoteDatasourceProvider);
  final gwansangRepo = ref.watch(gwansangRepositoryProvider);

  final results = await Future.wait([
    sajuDs.getSajuProfileByUserId(user.id),
    gwansangRepo.getGwansangProfile(user.id),
  ]);

  final sajuModel = results[0];
  final gwansang = results[1] as GwansangProfile?;

  // SajuProfileModel → SajuProfile 변환
  SajuProfile? saju;
  if (sajuModel != null) {
    saju = (sajuModel as dynamic).toEntity() as SajuProfile?;
  }

  return (saju: saju, gwansang: gwansang);
}
```

> **Note:** SajuProfileModel.toEntity() 존재 여부를 확인하고, 없으면 SajuRemoteDatasource의 기존 변환 로직을 참고하여 조정한다. SajuProfileModel이 SajuProfile을 상속/구현하고 있을 수도 있다.

**Step 2: code generation 실행**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 3: 컴파일 확인**

Run: `flutter analyze lib/features/home/presentation/providers/my_analysis_provider.dart`

**Step 4: Commit**

```bash
git add lib/features/home/presentation/providers/my_analysis_provider.dart
git add lib/features/home/presentation/providers/my_analysis_provider.g.dart
git commit -m "feat: 홈 내 분석 카드용 myAnalysis 프로바이더 추가"
```

---

### Task 2: MyAnalysisSection 위젯 생성

**Files:**
- Create: `lib/features/home/presentation/widgets/my_analysis_section.dart`

**Step 1: 위젯 파일 생성**

가로 2카드 레이아웃. 사주 카드 + 관상 카드.
캐릭터 에셋은 expressions/poses 중 랜덤 선택.

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../constants/home_layout.dart';
import '../providers/my_analysis_provider.dart';
import 'section_header.dart';

/// 홈 섹션: 내 운명 분석 (사주 + 관상 가로 2카드)
///
/// 모든 유저에게 항상 표시 (온보딩 완료 = 사주+관상 데이터 있음).
/// 캐릭터는 expressions/poses 중 랜덤으로 보여줘서 재미 요소 제공.
class MyAnalysisSection extends ConsumerWidget {
  const MyAnalysisSection({super.key});

  // 오행별 사용 가능한 expressions (공통)
  static const _expressions = ['love', 'laugh', 'surprised', 'default'];
  static const _poses = ['waving', 'sitting', 'standing'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(myAnalysisProvider);

    return analysisAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final saju = data.saju;
        final gwansang = data.gwansang;
        if (saju == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '내 운명 분석'),
            HomeLayout.gapHeaderContent,
            Row(
              children: [
                // 사주 카드
                Expanded(
                  child: _SajuCard(saju: saju),
                ),
                const SizedBox(width: 12),
                // 관상 카드
                Expanded(
                  child: _GwansangCard(gwansang: gwansang),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

사주 카드, 관상 카드는 private 위젯으로 같은 파일에 구현한다.

**_SajuCard 핵심:**
- 유저 dominantElement로 CharacterAssets.pathFor() → 랜덤 expression/pose 선택
- 캐릭터명 + "목(木) 기운" 라벨
- personalityTraits 중 1~2개 표시
- 탭 → DestinyResultPage (사주 탭)

**_GwansangCard 핵심:**
- animalModifier + animalTypeKorean + "상" 표시
- charmKeywords 1~2개 표시
- 탭 → DestinyResultPage (관상 탭)

**랜덤 캐릭터 로직:**
```dart
String _randomCharacterAsset(CharacterPath char) {
  final random = Random();
  // expressions + poses 합쳐서 랜덤
  final allVariants = [
    ...MyAnalysisSection._expressions.map((e) => char.expression(e)),
    ...MyAnalysisSection._poses.map((p) => char.pose(p)),
  ];
  return allVariants[random.nextInt(allVariants.length)];
}
```

**Step 2: 컴파일 확인**

Run: `flutter analyze lib/features/home/presentation/widgets/my_analysis_section.dart`

**Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/my_analysis_section.dart
git commit -m "feat: 홈 내 운명 분석 섹션 위젯 (사주+관상 2카드)"
```

---

### Task 3: HomePage에 섹션 삽입

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`

**Step 1: import 추가 & 섹션 삽입**

연애운(DailyFortuneSection, staggerIndex=1) 바로 아래, 기존 운명 매칭(DestinySection, staggerIndex=2) 위에 삽입.
새 섹션 staggerIndex=2, 나머지 기존 섹션 index를 +1씩 밀기.

```dart
// import 추가
import '../widgets/my_analysis_section.dart';

// DailyFortuneSection 뒤에 삽입:
HomeLayout.gapSection,

// ---- 3. 내 운명 분석 (사주+관상 카드) ----
const HomeSection(
  sectionName: 'my_analysis',
  staggerIndex: 2,
  child: MyAnalysisSection(),
),

// 기존 섹션들 staggerIndex 조정: 3, 4, 5, 6, 7
```

**Step 2: 전체 빌드 확인**

Run: `flutter analyze`

**Step 3: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart
git commit -m "feat: 홈에 내 운명 분석 섹션 삽입 (연애운 아래)"
```

---

### Task 4: DestinyResultPage 네비게이션 연결

**Files:**
- Modify: `lib/features/home/presentation/widgets/my_analysis_section.dart`

**Step 1: 탭 시 DestinyResultPage로 이동하는 로직 확인/구현**

DestinyResultPage는 `sajuResult`와 `gwansangResult`를 route extra로 받는다.
홈에서는 DB에서 조회한 SajuProfile/GwansangProfile을 SajuAnalysisResult/GwansangAnalysisResult로 래핑하여 전달해야 한다.

```dart
// 사주 카드 onTap:
void _navigateToSaju(BuildContext context, SajuProfile saju) {
  final element = saju.dominantElement ?? FiveElementType.wood;
  final characterPath = CharacterAssets.pathFor(element);

  context.push(RoutePaths.destinyResult, extra: {
    'sajuResult': SajuAnalysisResult(
      profile: saju,
      characterName: CharacterAssets.nameFor(element),
      characterAssetPath: characterPath.defaultImage,
      characterGreeting: '', // 재열람이므로 인사 생략 가능
    ),
    'initialTab': 0, // 사주 탭
  });
}

// 관상 카드 onTap:
void _navigateToGwansang(BuildContext context, SajuProfile saju, GwansangProfile gwansang) {
  final element = saju.dominantElement ?? FiveElementType.wood;
  final characterPath = CharacterAssets.pathFor(element);

  context.push(RoutePaths.destinyResult, extra: {
    'sajuResult': SajuAnalysisResult(
      profile: saju,
      characterName: CharacterAssets.nameFor(element),
      characterAssetPath: characterPath.defaultImage,
      characterGreeting: '',
    ),
    'gwansangResult': GwansangAnalysisResult(
      profile: gwansang,
      isNewAnalysis: false,
    ),
    'initialTab': 1, // 관상 탭
  });
}
```

> **Note:** DestinyResultPage가 `initialTab` extra를 지원하는지 확인. 미지원 시 DestinyResultPage에 initialTab 파라미터 추가 필요 (minor 수정).

**Step 2: import 확인 + 빌드**

Run: `flutter analyze`

**Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/my_analysis_section.dart
git commit -m "feat: 내 분석 카드 탭 → DestinyResultPage 네비게이션 연결"
```

---

### Task 5: 통합 확인 및 정리

**Step 1: 전체 빌드 + 분석**

Run: `flutter analyze && flutter build ios --no-codesign --debug 2>&1 | tail -5`

**Step 2: 시뮬레이터 확인 포인트**

- 홈 진입 시 연애운 아래에 "내 운명 분석" 섹션 표시
- 사주 카드: 유저 오행 캐릭터 (랜덤 표정/포즈) + 캐릭터명 + 오행 라벨 + 성격 키워드
- 관상 카드: 동물상 라벨 + 매력 키워드
- 각 카드 탭 시 DestinyResultPage 정상 이동 (사주/관상 탭)
- 홈 복귀 시 캐릭터가 랜덤으로 바뀌는지 확인

**Step 3: 최종 Commit**

```bash
git add -A
git commit -m "feat: 홈 내 운명 분석 섹션 완성 (사주+관상 2카드, 랜덤 캐릭터)"
```

---

## 구현 시 주의사항

1. **SajuProfileModel → SajuProfile 변환**: datasource가 Model을 반환하는데, Model이 Entity를 상속하는지 확인. 아니면 `.toEntity()` 또는 수동 변환 필요.
2. **캐릭터 에셋 유효성**: bulkkori는 expressions 폴더가 없음 (poses/views만). 캐릭터별로 사용 가능한 variants를 분기해야 함.
3. **DestinyResultPage initialTab**: 현재 미지원일 수 있음. route extra에서 `initialTab`을 읽어 TabController 초기값으로 설정하는 수정 필요.
4. **mounted 가드**: 이 위젯은 ConsumerWidget(stateless)이므로 async+ref 이슈 없음.
