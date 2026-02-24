# Phase 5: 사주 분석 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 온보딩 완료 후 사주팔자를 계산하고, AI가 해석한 결과를 캐릭터 연출과 함께 보여주는 전체 플로우를 구현한다.

**Architecture:** Supabase Edge Function(Deno)에서 만세력 계산 + Claude API 해석을 수행하고, Flutter 클린 아키텍처(domain→data→presentation)를 통해 결과를 화면에 표시한다. 사주 분석 로딩 화면에서 5캐릭터 애니메이션을 보여준 뒤, 결과 화면에서 오행 차트 + 배정 캐릭터 + AI 해석을 표시한다.

**Tech Stack:** Flutter 3.38+, Riverpod 2.x (@riverpod codegen), go_router, Supabase Edge Functions (Deno/TypeScript), Claude API, 한지 디자인 시스템

**Existing Code References:**
- Domain entity: `lib/features/saju/domain/entities/saju_entity.dart` (Pillar, FiveElements, SajuProfile, Compatibility, CompatibilityGrade)
- Constants: `lib/core/constants/app_constants.dart` (HeavenlyStems, EarthlyBranches, FiveElementType, FiveElementRelations, SupabaseFunctions, RoutePaths)
- Design system: `lib/core/widgets/saju_enums.dart` (SajuSize, SajuVariant, SajuColor)
- Theme: `lib/core/theme/app_theme.dart` (woodColor, fireColor, earthColor, metalColor, waterColor + pastels)
- Supabase helper: `lib/core/network/supabase_client.dart` (SupabaseHelper.invokeFunction)
- Router: `lib/app/routes/app_router.dart` (sajuAnalysis, sajuResult 라우트 — 현재 placeholder)
- Character assets: `assets/images/characters/{name}_{element}_default.png`

---

## Task 19: Saju 계산 Edge Function

**개요:** 생년월일시를 받아 사주팔자(4기둥 8자)와 오행 분포를 계산하는 Supabase Edge Function. 순수 TypeScript로 만세력 알고리즘을 구현한다 (외부 npm 의존성 없이, Deno 호환).

**Files:**
- Create: `supabase/functions/calculate-saju/index.ts`

**Step 1: Edge Function 생성**

```typescript
// supabase/functions/calculate-saju/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── 천간(天干) ───
const HEAVENLY_STEMS = ['갑','을','병','정','무','기','경','신','임','계'] as const
const STEM_HANJA: Record<string, string> = {
  '갑':'甲','을':'乙','병':'丙','정':'丁','무':'戊',
  '기':'己','경':'庚','신':'辛','임':'壬','계':'癸',
}
const STEM_ELEMENT: Record<string, string> = {
  '갑':'wood','을':'wood','병':'fire','정':'fire','무':'earth',
  '기':'earth','경':'metal','신':'metal','임':'water','계':'water',
}

// ─── 지지(地支) ───
const EARTHLY_BRANCHES = ['자','축','인','묘','진','사','오','미','신','유','술','해'] as const
const BRANCH_HANJA: Record<string, string> = {
  '자':'子','축':'丑','인':'寅','묘':'卯','진':'辰','사':'巳',
  '오':'午','미':'未','신':'申','유':'酉','술':'戌','해':'亥',
}
const BRANCH_ELEMENT: Record<string, string> = {
  '자':'water','축':'earth','인':'wood','묘':'wood','진':'earth','사':'fire',
  '오':'fire','미':'earth','신':'metal','유':'metal','술':'earth','해':'water',
}
const BRANCH_ANIMAL: Record<string, string> = {
  '자':'쥐','축':'소','인':'호랑이','묘':'토끼','진':'용','사':'뱀',
  '오':'말','미':'양','신':'원숭이','유':'닭','술':'개','해':'돼지',
}

// ─── 절기(節氣) 기반 월주 경계 ───
// 각 월의 시작 절기 (양력 대략적 날짜). 정밀 계산은 KASI 데이터 필요.
// 간략화: 월별 절기 시작일 (일반적 기준)
const MONTH_BOUNDARIES = [
  { month: 1, startDay: 6 },   // 소한
  { month: 2, startDay: 4 },   // 입춘 ← 연주 경계!
  { month: 3, startDay: 6 },   // 경칩
  { month: 4, startDay: 5 },   // 청명
  { month: 5, startDay: 6 },   // 입하
  { month: 6, startDay: 6 },   // 망종
  { month: 7, startDay: 7 },   // 소서
  { month: 8, startDay: 8 },   // 입추
  { month: 9, startDay: 8 },   // 백로
  { month: 10, startDay: 8 },  // 한로
  { month: 11, startDay: 7 },  // 입동
  { month: 12, startDay: 7 },  // 대설
]

// ─── 시주(時柱) 시간 경계 ───
// 자시(23:00~01:00), 축시(01:00~03:00), ... 해시(21:00~23:00)
const HOUR_BRANCHES = [
  { branch: '자', start: 23, end: 1 },
  { branch: '축', start: 1, end: 3 },
  { branch: '인', start: 3, end: 5 },
  { branch: '묘', start: 5, end: 7 },
  { branch: '진', start: 7, end: 9 },
  { branch: '사', start: 9, end: 11 },
  { branch: '오', start: 11, end: 13 },
  { branch: '미', start: 13, end: 15 },
  { branch: '신', start: 15, end: 17 },
  { branch: '유', start: 17, end: 19 },
  { branch: '술', start: 19, end: 21 },
  { branch: '해', start: 21, end: 23 },
]

/**
 * 연주(年柱) 계산
 * 입춘(2월 4일경) 기준으로 연도가 바뀜
 */
function getYearPillar(year: number, month: number, day: number) {
  // 입춘 전이면 전년도 기준
  let adjustedYear = year
  if (month < 2 || (month === 2 && day < 4)) {
    adjustedYear -= 1
  }

  // 갑자년(1984)을 기준점으로 60갑자 순환
  const base = adjustedYear - 4 // 4 AD = 갑자년
  const stemIdx = ((base % 10) + 10) % 10
  const branchIdx = ((base % 12) + 12) % 12

  return {
    heavenlyStem: HEAVENLY_STEMS[stemIdx],
    earthlyBranch: EARTHLY_BRANCHES[branchIdx],
  }
}

/**
 * 월주(月柱) 계산
 * 절기 기준으로 월이 바뀜. 연간(年干)에 따라 월간(月干)이 결정됨.
 */
function getMonthPillar(year: number, month: number, day: number, yearStemIdx: number) {
  // 절기 기준 월 결정 (인월=1, 묘월=2, ... 축월=12)
  let sajuMonth = month - 1 // 0-indexed
  const boundary = MONTH_BOUNDARIES[month - 1]
  if (day < boundary.startDay) {
    sajuMonth = sajuMonth - 1
    if (sajuMonth < 0) sajuMonth = 11
  }

  // 지지: 인(1월), 묘(2월), ... 축(12월) → 인=index 2
  const branchIdx = (sajuMonth + 2) % 12

  // 월간 공식: 연간 × 2 + 월 (mod 10)
  // 갑기 → 병인월, 을경 → 무인월, 병신 → 경인월, 정임 → 임인월, 무계 → 갑인월
  const stemBase = (yearStemIdx % 5) * 2 + 2
  const stemIdx = (stemBase + sajuMonth) % 10

  return {
    heavenlyStem: HEAVENLY_STEMS[stemIdx],
    earthlyBranch: EARTHLY_BRANCHES[branchIdx],
  }
}

/**
 * 일주(日柱) 계산
 * 율리우스 적일수(Julian Day Number)를 이용한 60갑자 순환
 */
function getDayPillar(year: number, month: number, day: number) {
  // 율리우스 적일수 계산 (그레고리력)
  const a = Math.floor((14 - month) / 12)
  const y = year + 4800 - a
  const m = month + 12 * a - 3
  const jdn = day + Math.floor((153 * m + 2) / 5) + 365 * y +
    Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045

  // 갑자일 기준점 (2000-01-07 = JDN 2451551 = 갑자일)
  const base = jdn - 2451551
  const stemIdx = ((base % 10) + 10) % 10
  const branchIdx = ((base % 12) + 12) % 12

  return {
    heavenlyStem: HEAVENLY_STEMS[stemIdx],
    earthlyBranch: EARTHLY_BRANCHES[branchIdx],
  }
}

/**
 * 시주(時柱) 계산
 * 일간(日干)에 따라 시간(時干)이 결정됨
 */
function getHourPillar(hour: number, dayStemIdx: number) {
  // 시지 결정
  let branchIdx: number
  if (hour === 23 || hour === 0) {
    branchIdx = 0 // 자시
  } else {
    branchIdx = Math.floor((hour + 1) / 2)
  }

  // 시간 공식: 일간 × 2 + 시지 (mod 10)
  const stemBase = (dayStemIdx % 5) * 2
  const stemIdx = (stemBase + branchIdx) % 10

  return {
    heavenlyStem: HEAVENLY_STEMS[stemIdx],
    earthlyBranch: EARTHLY_BRANCHES[branchIdx],
  }
}

/**
 * 오행 분포 계산
 */
function calculateFiveElements(pillars: Array<{heavenlyStem: string, earthlyBranch: string}>) {
  const counts = { wood: 0, fire: 0, earth: 0, metal: 0, water: 0 }

  for (const pillar of pillars) {
    const stemEl = STEM_ELEMENT[pillar.heavenlyStem] as keyof typeof counts
    const branchEl = BRANCH_ELEMENT[pillar.earthlyBranch] as keyof typeof counts
    if (stemEl) counts[stemEl]++
    if (branchEl) counts[branchEl]++
  }

  return counts
}

/**
 * 주도 오행 결정 (일간 기준)
 */
function getDominantElement(dayStem: string): string {
  return STEM_ELEMENT[dayStem] || 'earth'
}

serve(async (req) => {
  try {
    const { birthDate, birthTime, isLunar } = await req.json()
    // birthDate: "1995-03-15", birthTime: "14:30" or null, isLunar: false

    if (!birthDate) {
      return new Response(JSON.stringify({ error: 'birthDate is required' }), {
        status: 400, headers: { 'Content-Type': 'application/json' }
      })
    }

    const [yearStr, monthStr, dayStr] = birthDate.split('-')
    const year = parseInt(yearStr)
    const month = parseInt(monthStr)
    const day = parseInt(dayStr)

    // TODO: 음력→양력 변환 (isLunar가 true인 경우). MVP에서는 양력만 지원.

    // 4기둥 계산
    const yearPillar = getYearPillar(year, month, day)
    const yearStemIdx = HEAVENLY_STEMS.indexOf(yearPillar.heavenlyStem as typeof HEAVENLY_STEMS[number])
    const monthPillar = getMonthPillar(year, month, day, yearStemIdx)
    const dayPillar = getDayPillar(year, month, day)

    let hourPillar = null
    if (birthTime) {
      const [hourStr] = birthTime.split(':')
      const hour = parseInt(hourStr)
      const dayStemIdx = HEAVENLY_STEMS.indexOf(dayPillar.heavenlyStem as typeof HEAVENLY_STEMS[number])
      hourPillar = getHourPillar(hour, dayStemIdx)
    }

    // 오행 분포
    const pillars = [yearPillar, monthPillar, dayPillar]
    if (hourPillar) pillars.push(hourPillar)
    const fiveElements = calculateFiveElements(pillars)
    const dominantElement = getDominantElement(dayPillar.heavenlyStem)

    // 응답 구성
    const result = {
      yearPillar: {
        ...yearPillar,
        hanja: `${STEM_HANJA[yearPillar.heavenlyStem]}${BRANCH_HANJA[yearPillar.earthlyBranch]}`,
        animal: BRANCH_ANIMAL[yearPillar.earthlyBranch],
      },
      monthPillar: {
        ...monthPillar,
        hanja: `${STEM_HANJA[monthPillar.heavenlyStem]}${BRANCH_HANJA[monthPillar.earthlyBranch]}`,
      },
      dayPillar: {
        ...dayPillar,
        hanja: `${STEM_HANJA[dayPillar.heavenlyStem]}${BRANCH_HANJA[dayPillar.earthlyBranch]}`,
      },
      hourPillar: hourPillar ? {
        ...hourPillar,
        hanja: `${STEM_HANJA[hourPillar.heavenlyStem]}${BRANCH_HANJA[hourPillar.earthlyBranch]}`,
      } : null,
      fiveElements,
      dominantElement,
      birthDate,
      birthTime,
      isLunar: isLunar ?? false,
    }

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

**Step 2: 로컬 테스트**

Run: `cd supabase && supabase functions serve calculate-saju --no-verify-jwt`
Then: `curl -X POST http://localhost:54321/functions/v1/calculate-saju -H "Content-Type: application/json" -d '{"birthDate":"1995-03-15","birthTime":"14:30","isLunar":false}'`
Expected: JSON with yearPillar, monthPillar, dayPillar, hourPillar, fiveElements

**Step 3: Commit**

```bash
git add supabase/functions/calculate-saju/index.ts
git commit -m "feat: 사주 계산 Edge Function (4기둥 + 오행 분포)"
```

---

## Task 20: AI 해석 Edge Function (Claude API)

**개요:** 사주 계산 결과를 Claude API에 보내 성격 분석, 캐릭터 배정, 개인화 해석 텍스트를 생성한다.

**Files:**
- Create: `supabase/functions/generate-saju-insight/index.ts`

**Step 1: Edge Function 생성**

```typescript
// supabase/functions/generate-saju-insight/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'

serve(async (req) => {
  try {
    const { sajuResult, userName } = await req.json()

    if (!sajuResult) {
      return new Response(JSON.stringify({ error: 'sajuResult is required' }), {
        status: 400, headers: { 'Content-Type': 'application/json' },
      })
    }

    const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'ANTHROPIC_API_KEY not configured' }), {
        status: 500, headers: { 'Content-Type': 'application/json' },
      })
    }

    const systemPrompt = `당신은 "사주인연" 앱의 사주 해석 AI입니다.
사용자의 사주팔자 데이터를 분석하여 다음을 생성합니다:

1. **성격 특성 키워드** (5개): 한국어, 긍정적이고 매력적인 표현
2. **AI 해석문** (200~300자): 따뜻하고 희망적인 톤, 연애/인연 관점 포함
3. **캐릭터 배정**: 주도 오행에 따라 아래 캐릭터 중 하나
   - wood(목): 나무리 🌿 — 따뜻하고 성장을 좋아하는 곰
   - fire(화): 불꼬리 🔥 — 열정적이고 에너지 넘치는 여우
   - earth(토): 흙순이 🌍 — 든든하고 안정적인 두더지
   - metal(금): 쇠동이 ⚡ — 날카롭고 결단력 있는 토끼
   - water(수): 물결이 🌊 — 지혜롭고 유연한 물개

응답은 반드시 아래 JSON 형식으로:
{
  "personalityTraits": ["특성1", "특성2", "특성3", "특성4", "특성5"],
  "interpretation": "해석 텍스트...",
  "characterName": "나무리",
  "characterElement": "wood",
  "characterGreeting": "캐릭터가 사용자에게 하는 첫 인사 (1문장)"
}`

    const userMessage = `사용자 이름: ${userName || '사용자'}

사주팔자 데이터:
- 연주(年柱): ${sajuResult.yearPillar.heavenlyStem}${sajuResult.yearPillar.earthlyBranch} (${sajuResult.yearPillar.hanja})
- 월주(月柱): ${sajuResult.monthPillar.heavenlyStem}${sajuResult.monthPillar.earthlyBranch} (${sajuResult.monthPillar.hanja})
- 일주(日柱): ${sajuResult.dayPillar.heavenlyStem}${sajuResult.dayPillar.earthlyBranch} (${sajuResult.dayPillar.hanja})
- 시주(時柱): ${sajuResult.hourPillar ? `${sajuResult.hourPillar.heavenlyStem}${sajuResult.hourPillar.earthlyBranch} (${sajuResult.hourPillar.hanja})` : '미입력'}

오행 분포:
- 목(木): ${sajuResult.fiveElements.wood}
- 화(火): ${sajuResult.fiveElements.fire}
- 토(土): ${sajuResult.fiveElements.earth}
- 금(金): ${sajuResult.fiveElements.metal}
- 수(水): ${sajuResult.fiveElements.water}

주도 오행: ${sajuResult.dominantElement}

이 사주를 분석하여 JSON 형식으로 응답해주세요.`

    const response = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1024,
        system: systemPrompt,
        messages: [{ role: 'user', content: userMessage }],
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Claude API error: ${response.status} ${errorText}`)
    }

    const data = await response.json()
    const content = data.content[0]?.text || ''

    // JSON 파싱 (Claude 응답에서 JSON 블록 추출)
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      throw new Error('Failed to parse Claude response as JSON')
    }

    const insight = JSON.parse(jsonMatch[0])

    return new Response(JSON.stringify(insight), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

**Step 2: Commit**

```bash
git add supabase/functions/generate-saju-insight/index.ts
git commit -m "feat: AI 사주 해석 Edge Function (Claude API)"
```

---

## Task 21: Saju Data Layer (Model + DataSource + Repository)

**개요:** 클린 아키텍처 data 레이어. Edge Function 호출 → JSON 파싱 → SajuProfile 엔티티 변환.

**Files:**
- Create: `lib/features/saju/data/models/saju_profile_model.dart`
- Create: `lib/features/saju/data/datasources/saju_remote_datasource.dart`
- Create: `lib/features/saju/domain/repositories/saju_repository.dart`
- Create: `lib/features/saju/data/repositories/saju_repository_impl.dart`

**Step 1: SajuProfileModel (DTO)**

```dart
// lib/features/saju/data/models/saju_profile_model.dart
import '../../domain/entities/saju_entity.dart';
import '../../../../core/constants/app_constants.dart';

/// Edge Function 응답 JSON → SajuProfile 엔티티 변환 DTO
class SajuProfileModel {
  const SajuProfileModel({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.fiveElements,
    required this.dominantElement,
    required this.birthDate,
    this.birthTime,
    required this.isLunar,
  });

  final Map<String, dynamic> yearPillar;
  final Map<String, dynamic> monthPillar;
  final Map<String, dynamic> dayPillar;
  final Map<String, dynamic>? hourPillar;
  final Map<String, dynamic> fiveElements;
  final String dominantElement;
  final String birthDate;
  final String? birthTime;
  final bool isLunar;

  factory SajuProfileModel.fromJson(Map<String, dynamic> json) {
    return SajuProfileModel(
      yearPillar: json['yearPillar'] as Map<String, dynamic>,
      monthPillar: json['monthPillar'] as Map<String, dynamic>,
      dayPillar: json['dayPillar'] as Map<String, dynamic>,
      hourPillar: json['hourPillar'] as Map<String, dynamic>?,
      fiveElements: json['fiveElements'] as Map<String, dynamic>,
      dominantElement: json['dominantElement'] as String,
      birthDate: json['birthDate'] as String,
      birthTime: json['birthTime'] as String?,
      isLunar: json['isLunar'] as bool? ?? false,
    );
  }

  /// DTO → Domain Entity 변환
  SajuProfile toEntity({
    required String id,
    required String userId,
    List<String> personalityTraits = const [],
    String? aiInterpretation,
  }) {
    return SajuProfile(
      id: id,
      userId: userId,
      yearPillar: _toPillar(yearPillar),
      monthPillar: _toPillar(monthPillar),
      dayPillar: _toPillar(dayPillar),
      hourPillar: hourPillar != null ? _toPillar(hourPillar!) : null,
      fiveElements: FiveElements(
        wood: (fiveElements['wood'] as num?)?.toInt() ?? 0,
        fire: (fiveElements['fire'] as num?)?.toInt() ?? 0,
        earth: (fiveElements['earth'] as num?)?.toInt() ?? 0,
        metal: (fiveElements['metal'] as num?)?.toInt() ?? 0,
        water: (fiveElements['water'] as num?)?.toInt() ?? 0,
      ),
      dominantElement: _toFiveElementType(dominantElement),
      personalityTraits: personalityTraits,
      aiInterpretation: aiInterpretation,
      isLunarCalendar: isLunar,
      birthDateTime: _parseBirthDateTime(),
      calculatedAt: DateTime.now(),
    );
  }

  Pillar _toPillar(Map<String, dynamic> json) {
    return Pillar(
      heavenlyStem: json['heavenlyStem'] as String,
      earthlyBranch: json['earthlyBranch'] as String,
    );
  }

  FiveElementType _toFiveElementType(String element) {
    return FiveElementType.values.firstWhere(
      (e) => e.name == element,
      orElse: () => FiveElementType.earth,
    );
  }

  DateTime _parseBirthDateTime() {
    final parts = birthDate.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    if (birthTime != null) {
      final timeParts = birthTime!.split(':');
      return DateTime(year, month, day, int.parse(timeParts[0]), int.parse(timeParts[1]));
    }
    return DateTime(year, month, day);
  }
}

/// AI 해석 응답 모델
class SajuInsightModel {
  const SajuInsightModel({
    required this.personalityTraits,
    required this.interpretation,
    required this.characterName,
    required this.characterElement,
    required this.characterGreeting,
  });

  final List<String> personalityTraits;
  final String interpretation;
  final String characterName;
  final String characterElement;
  final String characterGreeting;

  factory SajuInsightModel.fromJson(Map<String, dynamic> json) {
    return SajuInsightModel(
      personalityTraits: (json['personalityTraits'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      interpretation: json['interpretation'] as String,
      characterName: json['characterName'] as String,
      characterElement: json['characterElement'] as String,
      characterGreeting: json['characterGreeting'] as String,
    );
  }
}
```

**Step 2: Remote DataSource**

```dart
// lib/features/saju/data/datasources/saju_remote_datasource.dart
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/saju_profile_model.dart';

/// Saju Edge Function 호출 담당
class SajuRemoteDatasource {
  const SajuRemoteDatasource(this._helper);

  final SupabaseHelper _helper;

  /// 사주 계산 Edge Function 호출
  Future<SajuProfileModel> calculateSaju({
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
  }) async {
    final response = await _helper.invokeFunction(
      SupabaseFunctions.calculateSaju,
      body: {
        'birthDate': birthDate,
        'birthTime': birthTime,
        'isLunar': isLunar,
      },
    );
    return SajuProfileModel.fromJson(response as Map<String, dynamic>);
  }

  /// AI 사주 해석 Edge Function 호출
  Future<SajuInsightModel> generateInsight({
    required Map<String, dynamic> sajuResult,
    String? userName,
  }) async {
    final response = await _helper.invokeFunction(
      SupabaseFunctions.generateSajuInsight,
      body: {
        'sajuResult': sajuResult,
        'userName': userName,
      },
    );
    return SajuInsightModel.fromJson(response as Map<String, dynamic>);
  }
}
```

**Step 3: Repository Interface (domain)**

```dart
// lib/features/saju/domain/repositories/saju_repository.dart
import '../entities/saju_entity.dart';

/// 사주 분석 Repository 인터페이스
///
/// presentation → domain 의존만 허용 (클린 아키텍처)
abstract class SajuRepository {
  /// 생년월일시로 사주 분석 (계산 + AI 해석) 수행
  ///
  /// [birthDate]: "YYYY-MM-DD" 형식
  /// [birthTime]: "HH:mm" 형식 (null이면 삼주만 계산)
  /// [isLunar]: 음력 여부
  /// [userName]: AI 해석에 사용할 사용자 이름
  ///
  /// Returns: 완성된 SajuProfile (AI 해석 포함)
  Future<SajuProfile> analyzeSaju({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  });
}
```

**Step 4: Repository Implementation (data)**

```dart
// lib/features/saju/data/repositories/saju_repository_impl.dart
import '../../domain/entities/saju_entity.dart';
import '../../domain/repositories/saju_repository.dart';
import '../datasources/saju_remote_datasource.dart';

/// SajuRepository 구현체
///
/// Edge Function(계산) → Edge Function(AI 해석) → SajuProfile 조립
class SajuRepositoryImpl implements SajuRepository {
  const SajuRepositoryImpl(this._datasource);

  final SajuRemoteDatasource _datasource;

  @override
  Future<SajuProfile> analyzeSaju({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  }) async {
    // 1. 사주 계산
    final calculationResult = await _datasource.calculateSaju(
      birthDate: birthDate,
      birthTime: birthTime,
      isLunar: isLunar,
    );

    // 2. AI 해석 요청 (계산 결과를 JSON으로 전달)
    final insightResult = await _datasource.generateInsight(
      sajuResult: {
        'yearPillar': calculationResult.yearPillar,
        'monthPillar': calculationResult.monthPillar,
        'dayPillar': calculationResult.dayPillar,
        'hourPillar': calculationResult.hourPillar,
        'fiveElements': calculationResult.fiveElements,
        'dominantElement': calculationResult.dominantElement,
      },
      userName: userName,
    );

    // 3. SajuProfile 엔티티 조립
    final profileId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    return calculationResult.toEntity(
      id: profileId,
      userId: userId,
      personalityTraits: insightResult.personalityTraits,
      aiInterpretation: insightResult.interpretation,
    );
  }
}
```

**Step 5: Commit**

```bash
git add lib/features/saju/data/ lib/features/saju/domain/repositories/
git commit -m "feat: Saju data layer (Model + DataSource + Repository)"
```

---

## Task 22: Saju Providers (Riverpod)

**개요:** Repository를 Riverpod Provider로 감싸고, 사주 분석 상태를 관리하는 AsyncNotifier를 구현한다.

**Files:**
- Create: `lib/features/saju/presentation/providers/saju_provider.dart`
- Create: `lib/features/saju/presentation/providers/saju_provider.g.dart` (수동 작성)

**Step 1: Provider 작성**

```dart
// lib/features/saju/presentation/providers/saju_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/saju_remote_datasource.dart';
import '../../data/models/saju_profile_model.dart';
import '../../data/repositories/saju_repository_impl.dart';
import '../../domain/entities/saju_entity.dart';
import '../../domain/repositories/saju_repository.dart';

part 'saju_provider.g.dart';

/// SajuRemoteDatasource Provider
@riverpod
SajuRemoteDatasource sajuRemoteDatasource(Ref ref) {
  return SajuRemoteDatasource(ref.watch(supabaseHelperProvider));
}

/// SajuRepository Provider
@riverpod
SajuRepository sajuRepository(Ref ref) {
  return SajuRepositoryImpl(ref.watch(sajuRemoteDatasourceProvider));
}

/// 사주 분석 결과 상태
///
/// null: 아직 분석 안 함
/// AsyncData<SajuProfile>: 분석 완료
/// AsyncError: 분석 실패
/// AsyncLoading: 분석 중
@riverpod
class SajuAnalysisNotifier extends _$SajuAnalysisNotifier {
  @override
  FutureOr<SajuAnalysisResult?> build() => null;

  /// 사주 분석 시작
  Future<void> analyze({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(sajuRepositoryProvider);
      final profile = await repo.analyzeSaju(
        userId: userId,
        birthDate: birthDate,
        birthTime: birthTime,
        isLunar: isLunar,
        userName: userName,
      );

      // 캐릭터 정보는 dominantElement로 결정
      final characterInfo = _getCharacterInfo(profile.dominantElement);

      return SajuAnalysisResult(
        profile: profile,
        characterName: characterInfo.name,
        characterAssetPath: characterInfo.assetPath,
        characterGreeting: characterInfo.greeting,
      );
    });
  }

  _CharacterInfo _getCharacterInfo(FiveElementType? element) {
    return switch (element) {
      FiveElementType.wood => const _CharacterInfo(
        name: '나무리',
        assetPath: 'assets/images/characters/namuri_wood_default.png',
        greeting: '안녕! 나는 나무리야. 네 사주를 봤어!',
      ),
      FiveElementType.fire => const _CharacterInfo(
        name: '불꼬리',
        assetPath: 'assets/images/characters/bulkkori_fire_default.png',
        greeting: '반가워! 나는 불꼬리! 네 사주가 불타오르고 있어!',
      ),
      FiveElementType.earth => const _CharacterInfo(
        name: '흙순이',
        assetPath: 'assets/images/characters/heuksuni_earth_default.png',
        greeting: '어서와~ 나는 흙순이. 네 사주를 든든하게 봐줄게!',
      ),
      FiveElementType.metal => const _CharacterInfo(
        name: '쇠동이',
        assetPath: 'assets/images/characters/soedongi_metal_default.png',
        greeting: '안녕! 쇠동이야. 네 사주를 정확히 분석했어!',
      ),
      FiveElementType.water || null => const _CharacterInfo(
        name: '물결이',
        assetPath: 'assets/images/characters/mulgyeori_water_default.png',
        greeting: '안녕~ 물결이야. 네 사주 속 깊은 이야기를 들려줄게!',
      ),
    };
  }
}

/// 사주 분석 결과 (프로필 + 캐릭터 정보)
class SajuAnalysisResult {
  const SajuAnalysisResult({
    required this.profile,
    required this.characterName,
    required this.characterAssetPath,
    required this.characterGreeting,
  });

  final SajuProfile profile;
  final String characterName;
  final String characterAssetPath;
  final String characterGreeting;
}

class _CharacterInfo {
  const _CharacterInfo({
    required this.name,
    required this.assetPath,
    required this.greeting,
  });

  final String name;
  final String assetPath;
  final String greeting;
}
```

**Step 2: .g.dart 수동 작성**

```dart
// lib/features/saju/presentation/providers/saju_provider.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saju_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sajuRemoteDatasourceHash() => r'saju_remote_datasource_hash';

/// SajuRemoteDatasource Provider
@ProviderFor(sajuRemoteDatasource)
final sajuRemoteDatasourceProvider =
    AutoDisposeProvider<SajuRemoteDatasource>.internal(
  sajuRemoteDatasource,
  name: r'sajuRemoteDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuRemoteDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuRemoteDatasourceRef = AutoDisposeProviderRef<SajuRemoteDatasource>;

String _$sajuRepositoryHash() => r'saju_repository_hash';

/// SajuRepository Provider
@ProviderFor(sajuRepository)
final sajuRepositoryProvider = AutoDisposeProvider<SajuRepository>.internal(
  sajuRepository,
  name: r'sajuRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuRepositoryRef = AutoDisposeProviderRef<SajuRepository>;

String _$sajuAnalysisNotifierHash() => r'saju_analysis_notifier_hash';

/// 사주 분석 결과 상태
@ProviderFor(SajuAnalysisNotifier)
final sajuAnalysisNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SajuAnalysisNotifier, SajuAnalysisResult?>.internal(
  SajuAnalysisNotifier.new,
  name: r'sajuAnalysisNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sajuAnalysisNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SajuAnalysisNotifier
    = AutoDisposeAsyncNotifier<SajuAnalysisResult?>;

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
```

**Step 3: Commit**

```bash
git add lib/features/saju/presentation/providers/
git commit -m "feat: Saju providers (Repository + 분석 AsyncNotifier)"
```

---

## Task 23: 사주 분석 로딩 화면 (5캐릭터 애니메이션)

**개요:** 온보딩 완료 후 보여지는 사주 분석 로딩 화면. 5캐릭터가 원형 배치로 회전하다가 사용자의 오행 캐릭터만 남는 연출.

**Files:**
- Create: `lib/features/saju/presentation/pages/saju_analysis_page.dart`
- Modify: `lib/app/routes/app_router.dart` — placeholder를 실제 페이지로 교체

**Step 1: 분석 페이지 구현**

사주 분석 로딩 화면은 다음 단계로 구성:
1. "좋아! 이제 네 사주를 볼게~" (나무리 말풍선, 1.5초)
2. 5캐릭터 원형 배치 + 회전 애니메이션 (3초)
3. 하나씩 사라지며 내 캐릭터만 남음 (1초)
4. 캐릭터 바운스 등장 + "찾았다!" (1초)
5. 자동으로 결과 페이지 이동

페이지는 `ConsumerStatefulWidget`으로 구현. 온보딩에서 전달받은 birthDate/birthTime으로 Provider의 `analyze()`를 호출하고, 분석 완료 시 결과 화면으로 이동.

라우터에서 `state.extra`로 온보딩 데이터를 전달받음.

**Step 2: 라우터 업데이트**

`app_router.dart`의 sajuAnalysis, sajuResult 라우트에서 placeholder를 실제 페이지로 교체.

**Step 3: Commit**

```bash
git add lib/features/saju/presentation/pages/saju_analysis_page.dart lib/app/routes/app_router.dart
git commit -m "feat: 사주 분석 로딩 화면 (5캐릭터 회전 애니메이션)"
```

---

## Task 24: 사주 결과 화면 (오행 차트 + 캐릭터 + AI 해석)

**개요:** 사주 분석 결과를 보여주는 메인 화면. 오행 분포 바 차트, 배정된 캐릭터, 4기둥 카드, AI 해석 말풍선, 공유 버튼.

**Files:**
- Create: `lib/features/saju/presentation/pages/saju_result_page.dart`
- Create: `lib/features/saju/presentation/widgets/five_elements_chart.dart`
- Create: `lib/features/saju/presentation/widgets/pillar_card.dart`

**Step 1: 오행 바 차트 위젯**

5개 오행의 분포를 한지 톤 바 차트로 시각화.

**Step 2: 4기둥 카드 위젯**

연주/월주/일주/시주를 가로 배치 카드로 표시. 각 카드에 천간+지지 한글/한자, 오행 색상.

**Step 3: 결과 페이지 조립**

스크롤 가능한 화면에 다음 순서로 배치:
1. 배정 캐릭터 (큰 이미지 + 이름 + 오행 뱃지)
2. 캐릭터 인사 말풍선 (SajuCharacterBubble)
3. 4기둥 카드 (가로 배치)
4. 오행 분포 차트 (바 차트)
5. 성격 특성 칩 (SajuChip 5개)
6. AI 해석 텍스트 (말풍선)
7. 공유 버튼 + 홈으로 가기 버튼

**Step 4: 라우터 연결**

`app_router.dart`의 sajuResult를 실제 페이지로 교체.

**Step 5: Commit**

```bash
git add lib/features/saju/presentation/pages/saju_result_page.dart lib/features/saju/presentation/widgets/ lib/app/routes/app_router.dart
git commit -m "feat: 사주 결과 화면 (오행 차트 + 캐릭터 + AI 해석)"
```

---

## Summary

| Task | 내용 | 산출물 |
|------|------|--------|
| 19 | Saju 계산 Edge Function | `supabase/functions/calculate-saju/index.ts` |
| 20 | AI 해석 Edge Function | `supabase/functions/generate-saju-insight/index.ts` |
| 21 | Data Layer (Model+DS+Repo) | `lib/features/saju/data/` + `domain/repositories/` |
| 22 | Riverpod Providers | `lib/features/saju/presentation/providers/` |
| 23 | 분석 로딩 화면 | `lib/features/saju/presentation/pages/saju_analysis_page.dart` |
| 24 | 결과 화면 + 위젯 | `lib/features/saju/presentation/pages/saju_result_page.dart` + widgets |
