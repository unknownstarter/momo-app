// =============================================================================
// 배치 궁합 계산 Edge Function
// =============================================================================
// 한 유저의 사주를 기반으로 이성 전체와의 궁합을 일괄 계산하여
// saju_compatibility 테이블에 저장합니다.
// 궁합 점수 공식은 calculate-compatibility와 100% 동일합니다.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// 상수: 천간·지지·오행 (calculate-compatibility와 동일)
// ---------------------------------------------------------------------------
const HEAVENLY_STEMS = [
  "갑", "을", "병", "정", "무", "기", "경", "신", "임", "계",
] as const;
const EARTHLY_BRANCHES = [
  "자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해",
] as const;
type FiveElement = "wood" | "fire" | "earth" | "metal" | "water";

const STEM_TO_ELEMENT: Record<string, FiveElement> = {
  갑: "wood", 을: "wood", 병: "fire", 정: "fire", 무: "earth", 기: "earth",
  경: "metal", 신: "metal", 임: "water", 계: "water",
};

// 오행 상생: key가 value를 생함
const GENERATING: Record<FiveElement, FiveElement> = {
  wood: "fire", fire: "earth", earth: "metal", metal: "water", water: "wood",
};
// 오행 상극: key가 value를 극함
const OVERCOMING: Record<FiveElement, FiveElement> = {
  wood: "earth", earth: "water", water: "fire", fire: "metal", metal: "wood",
};

// ---------------------------------------------------------------------------
// 천간 합 (5종)
// ---------------------------------------------------------------------------
const STEM_PAIRS = new Set<string>([
  "갑기", "기갑", "을경", "경을", "병신", "신병", "정임", "임정", "무계", "계무",
]);
function isStemPair(a: string, b: string): boolean {
  return STEM_PAIRS.has(a + b) || STEM_PAIRS.has(b + a);
}

// ---------------------------------------------------------------------------
// 지지 육합 (6쌍)
// ---------------------------------------------------------------------------
const BRANCH_육합 = new Set<string>([
  "자축", "축자", "인해", "해인", "묘술", "술묘", "진유", "유진", "사신", "신사", "오미", "미오",
]);
function is육합(a: string, b: string): boolean {
  return BRANCH_육합.has(a + b) || BRANCH_육합.has(b + a);
}

// 지지 삼합 (4조) — 두 지지가 같은 삼합에 속하면 true
const BRANCH_삼합: string[][] = [
  ["인", "오", "술"], // 화
  ["해", "묘", "미"], // 목
  ["신", "자", "진"], // 수
  ["사", "유", "축"], // 금
];
function is삼합(a: string, b: string): boolean {
  for (const trio of BRANCH_삼합) {
    if (trio.includes(a) && trio.includes(b) && a !== b) return true;
  }
  return false;
}

// 지지 육충 (6쌍)
const BRANCH_충 = new Set<string>([
  "자오", "오자", "축미", "미축", "인신", "신인", "묘유", "유묘", "진술", "술진", "사해", "해사",
]);
function is충(a: string, b: string): boolean {
  return BRANCH_충.has(a + b) || BRANCH_충.has(b + a);
}

// 지지 형 (삼형 + 자묘형)
const BRANCH_형: string[][] = [
  ["인", "사", "신"], ["축", "진", "술"], ["자", "묘"],
];
function is형(a: string, b: string): boolean {
  for (const group of BRANCH_형) {
    if (group.includes(a) && group.includes(b) && a !== b) return true;
  }
  return false;
}

// 지지 파 (6쌍)
const BRANCH_파 = new Set<string>([
  "자유", "유자", "인해", "해인", "묘오", "오묘", "진축", "축진", "사술", "술사", "오미", "미오",
]);
function is파(a: string, b: string): boolean {
  return BRANCH_파.has(a + b) || BRANCH_파.has(b + a);
}

// 지지 해 (6쌍): 子未 丑午 寅巳 卯辰 申亥 酉戌
const BRANCH_해 = new Set<string>([
  "자미", "미자", "축오", "오축", "인사", "사인", "묘진", "진묘", "신해", "해신", "유술", "술유",
]);
function is해(a: string, b: string): boolean {
  return BRANCH_해.has(a + b) || BRANCH_해.has(b + a);
}

// ---------------------------------------------------------------------------
// 타입
// ---------------------------------------------------------------------------
interface PillarInput {
  stem: string;
  branch: string;
}
interface SajuInput {
  yearPillar: PillarInput;
  monthPillar: PillarInput;
  dayPillar: PillarInput;
  hourPillar?: PillarInput | null;
  fiveElements: Record<FiveElement, number>;
  dominantElement?: string | null;
}

// ---------------------------------------------------------------------------
// 오행 점수 (0~100): 상생 가점, 상극 감점(3쌍 이상 -8 상한)
// ---------------------------------------------------------------------------
function getStemElement(stem: string): FiveElement {
  return STEM_TO_ELEMENT[stem] ?? "wood";
}

function scoreFiveElements(my: SajuInput, partner: SajuInput): number {
  const myDom = (my.dominantElement && STEM_TO_ELEMENT[my.dominantElement]) || getStemElement(my.dayPillar.stem);
  const partnerDom = (partner.dominantElement && STEM_TO_ELEMENT[partner.dominantElement]) || getStemElement(partner.dayPillar.stem);
  let 상생 = 0;
  let 상극 = 0;
  if (GENERATING[myDom] === partnerDom) 상생 += 1;
  if (GENERATING[partnerDom] === myDom) 상생 += 1;
  if (OVERCOMING[myDom] === partnerDom) 상극 += 1;
  if (OVERCOMING[partnerDom] === myDom) 상극 += 1;
  // 보조: 전체 오행 분포에서 쌍 비교
  const myCounts = my.fiveElements;
  const partnerCounts = partner.fiveElements;
  const elements: FiveElement[] = ["wood", "fire", "earth", "metal", "water"];
  for (const a of elements) {
    for (const b of elements) {
      if (GENERATING[a] === b && myCounts[a] > 0 && partnerCounts[b] > 0) 상생 += 0.5;
      if (OVERCOMING[a] === b && myCounts[a] > 0 && partnerCounts[b] > 0) 상극 += 0.5;
    }
  }
  const 상극캡 = Math.min(상극, 3);
  const 상극감점 = 상극캡 <= 1 ? 상극캡 * 2 : 상극캡 <= 2 ? 5 : 8;
  const raw = 50 + 상생 * 8 - 상극감점;
  return Math.round(Math.max(0, Math.min(100, raw)));
}

// ---------------------------------------------------------------------------
// 일주 점수 (0~100): 천간합 +10, 육합 +8, 삼합 +6, 충 -5, 형 -3, 파/해 -2
// ---------------------------------------------------------------------------
function scoreDayPillar(my: SajuInput, partner: SajuInput): number {
  const myStem = my.dayPillar.stem;
  const myBranch = my.dayPillar.branch;
  const pStem = partner.dayPillar.stem;
  const pBranch = partner.dayPillar.branch;
  let 점 = 50;
  if (isStemPair(myStem, pStem)) 점 += 10;
  if (is육합(myBranch, pBranch)) 점 += 8;
  else if (is삼합(myBranch, pBranch)) 점 += 6;
  if (is충(myBranch, pBranch)) 점 -= 5;
  if (is형(myBranch, pBranch)) 점 -= 3;
  if (is파(myBranch, pBranch)) 점 -= 2;
  if (is해(myBranch, pBranch)) 점 -= 2;
  return Math.round(Math.max(0, Math.min(100, 점)));
}

// ---------------------------------------------------------------------------
// 년·월·시 기둥 (20점 만점 환산)
// ---------------------------------------------------------------------------
function scoreOtherPillars(my: SajuInput, partner: SajuInput): number {
  const pairs: [PillarInput, PillarInput][] = [
    [my.yearPillar, partner.yearPillar],
    [my.monthPillar, partner.monthPillar],
  ];
  if (my.hourPillar && partner.hourPillar) {
    pairs.push([my.hourPillar, partner.hourPillar]);
  }
  let 점 = 0;
  for (const [a, b] of pairs) {
    const aSe = getStemElement(a.stem);
    const bSe = getStemElement(b.stem);
    if (GENERATING[aSe] === bSe || GENERATING[bSe] === aSe) 점 += 2;
    if (OVERCOMING[aSe] === bSe || OVERCOMING[bSe] === aSe) 점 -= 2;
    if (is육합(a.branch, b.branch)) 점 += 2;
    if (is삼합(a.branch, b.branch)) 점 += 1;
    if (is충(a.branch, b.branch)) 점 -= 1;
  }
  const scaled = 10 + Math.max(-10, Math.min(10, 점));
  return Math.round(Math.max(0, Math.min(20, scaled)));
}

// ---------------------------------------------------------------------------
// 종합 점수: 일주 40 + 오행 35 + 년월시 20 + 보정 5
// ---------------------------------------------------------------------------
function totalScore(
  dayPillar100: number,
  fiveElement100: number,
  other20: number,
): number {
  const 일주 = (dayPillar100 / 100) * 40;
  const 오행 = (fiveElement100 / 100) * 35;
  const 년월시 = (other20 / 20) * 20;
  const 보정 = 5;
  return Math.round(Math.max(0, Math.min(100, 일주 + 오행 + 년월시 + 보정)));
}

// ---------------------------------------------------------------------------
// strengths / challenges 템플릿
// ---------------------------------------------------------------------------
function buildStrengthsAndChallenges(
  my: SajuInput,
  partner: SajuInput,
  fiveElementScore: number,
  dayPillarScore: number,
  score: number,
): { strengths: string[]; challenges: string[] } {
  const strengths: string[] = [];
  const challenges: string[] = [];
  const myStem = my.dayPillar.stem;
  const pStem = partner.dayPillar.stem;
  const myBranch = my.dayPillar.branch;
  const pBranch = partner.dayPillar.branch;

  if (fiveElementScore >= 65) {
    strengths.push("오행이 잘 맞아요. 서로를 살려 주는 조합이에요.");
  }
  if (fiveElementScore <= 45 && fiveElementScore >= 30) {
    challenges.push("기운이 맞지 않는 부분이 있어요. 서로 보완이 필요해요.");
  }
  if (isStemPair(myStem, pStem)) {
    strengths.push("일간이 잘 맞아요. 깊은 정서적 교감이 가능해요.");
  }
  if (is육합(myBranch, pBranch)) {
    strengths.push("일지가 조화로워요. 안정적인 관계를 만들 수 있어요.");
  }
  if (is삼합(myBranch, pBranch)) {
    strengths.push("일지가 잘 어울려요. 함께 성장하기 좋은 조합이에요.");
  }
  if (is충(myBranch, pBranch)) {
    challenges.push("서로 다른 성향이 있어요. 의견이 엇갈릴 때 대화로 풀어보세요.");
  }
  if (is형(myBranch, pBranch) || is파(myBranch, pBranch) || is해(myBranch, pBranch)) {
    challenges.push("가끔 마음이 엇갈릴 수 있어요. 배려와 소통이 중요해요.");
  }
  if (fiveElementScore >= 55 && fiveElementScore <= 70) {
    strengths.push("두 분의 오행이 균형 있게 어울려요.");
  }
  if (score >= 70) {
    strengths.push("여러 면에서 잘 맞는 조합이에요. 함께 성장할 수 있어요.");
  }

  // 2~4개씩 유지
  const s = strengths.slice(0, 4);
  const c = challenges.slice(0, 4);
  if (s.length === 0) s.push("서로 다른 매력이 있는 관계예요.");
  if (c.length === 0) c.push("서로의 차이를 존중하면 좋은 관계가 될 수 있어요.");
  return { strengths: s, challenges: c };
}

function overallAnalysis(score: number): string {
  if (score >= 75) return "오행과 일주가 잘 맞는 조합이에요. 서로를 보완하며 좋은 관계를 이어갈 수 있어요.";
  if (score >= 55) return "전반적으로 균형 있는 궁합이에요. 소통과 배려가 있으면 더 좋은 인연이 될 수 있어요.";
  if (score >= 40) return "서로 다른 부분이 있어 보완이 필요해요. 대화로 풀어가면 좋은 관계가 될 수 있어요.";
  return "서로 다른 성향이 있어 갈등이 있을 수 있어요. 차이를 인정하고 대화로 풀어보세요.";
}

// ---------------------------------------------------------------------------
// DB pillar JSONB → SajuInput 변환
// ---------------------------------------------------------------------------
// DB에는 snake_case 키(year_pillar 등)로 저장되며, pillar JSONB는 {"stem":"갑","branch":"자"} 형태.
// heavenlyStem/earthlyBranch 형태도 허용하여 안전하게 처리.
// ---------------------------------------------------------------------------
function parsePillar(p: Record<string, unknown> | null | undefined): PillarInput | null {
  if (!p) return null;
  const stem = String(p.stem ?? p.heavenlyStem ?? "");
  const branch = String(p.branch ?? p.earthlyBranch ?? "");
  if (!stem || !branch) return null;
  return { stem, branch };
}

function dbRowToSajuInput(row: Record<string, unknown>): SajuInput | null {
  const yearPillar = parsePillar(row.year_pillar as Record<string, unknown> | null);
  const monthPillar = parsePillar(row.month_pillar as Record<string, unknown> | null);
  const dayPillar = parsePillar(row.day_pillar as Record<string, unknown> | null);
  const hourPillar = parsePillar(row.hour_pillar as Record<string, unknown> | null);

  if (!yearPillar || !monthPillar || !dayPillar) return null;

  const fe = row.five_elements as Record<string, unknown> | null;
  const fiveElements: Record<FiveElement, number> = {
    wood: Number(fe?.wood ?? 0),
    fire: Number(fe?.fire ?? 0),
    earth: Number(fe?.earth ?? 0),
    metal: Number(fe?.metal ?? 0),
    water: Number(fe?.water ?? 0),
  };

  return {
    yearPillar,
    monthPillar,
    dayPillar,
    hourPillar,
    fiveElements,
    dominantElement: row.dominant_element ? String(row.dominant_element) : null,
  };
}

// ---------------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------------
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------
Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    const body = await req.json();
    const userId = body.userId as string | undefined;
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "userId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ----- Supabase 서비스 역할 클라이언트 (RLS 바이패스) -----
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // ----- 1. 유저의 사주 프로필 조회 -----
    const { data: mySajuRow, error: mySajuErr } = await supabase
      .from("saju_profiles")
      .select("*")
      .eq("user_id", userId)
      .maybeSingle();

    if (mySajuErr) {
      console.error("[batch-compat] 내 사주 조회 실패:", mySajuErr.message);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user saju profile" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!mySajuRow) {
      // 사주 프로필이 없으면 조기 반환
      return new Response(
        JSON.stringify({ calculated: 0, total: 0, alreadyExisted: 0, message: "No saju profile found for user" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const mySaju = dbRowToSajuInput(mySajuRow);
    if (!mySaju) {
      return new Response(
        JSON.stringify({ error: "Invalid saju profile data for user" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ----- 2. 유저의 성별 조회 -----
    const { data: myProfile, error: profileErr } = await supabase
      .from("profiles")
      .select("gender")
      .eq("id", userId)
      .maybeSingle();

    if (profileErr || !myProfile) {
      console.error("[batch-compat] 프로필 조회 실패:", profileErr?.message);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user profile" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const myGender = myProfile.gender as string;
    const oppositeGender = myGender === "male" ? "female" : "male";

    // ----- 3. 이성 중 사주 완료된 유저 전체 조회 -----
    // profiles JOIN saju_profiles: 이성 + 활성(deleted_at IS NULL) + 사주 완료
    const { data: candidates, error: candErr } = await supabase
      .from("saju_profiles")
      .select(`
        user_id,
        year_pillar,
        month_pillar,
        day_pillar,
        hour_pillar,
        five_elements,
        dominant_element,
        profiles!inner (
          id,
          gender,
          deleted_at
        )
      `)
      .eq("profiles.gender", oppositeGender)
      .is("profiles.deleted_at", null)
      .neq("user_id", userId);

    if (candErr) {
      console.error("[batch-compat] 후보 조회 실패:", candErr.message);
      return new Response(
        JSON.stringify({ error: "Failed to fetch candidate profiles" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!candidates || candidates.length === 0) {
      return new Response(
        JSON.stringify({ calculated: 0, total: 0, alreadyExisted: 0, message: "No opposite-gender candidates found" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ----- 4. 이미 계산된 쌍 제외 -----
    const { data: existingPairs, error: existErr } = await supabase
      .from("saju_compatibility")
      .select("partner_id")
      .eq("user_id", userId);

    if (existErr) {
      console.error("[batch-compat] 기존 궁합 조회 실패:", existErr.message);
      // 에러여도 계속 진행 (중복 시 upsert로 처리됨)
    }

    const existingPartnerIds = new Set<string>(
      (existingPairs ?? []).map((r: Record<string, unknown>) => r.partner_id as string),
    );
    const alreadyExisted = existingPartnerIds.size;

    // 새로 계산할 후보 필터링
    const newCandidates = candidates.filter(
      (c: Record<string, unknown>) => !existingPartnerIds.has(c.user_id as string),
    );

    // ----- 5. 궁합 계산 + 배치 upsert -----
    const BATCH_SIZE = 100;
    let calculated = 0;
    const rows: Record<string, unknown>[] = [];

    for (const candidate of newCandidates) {
      const partnerSaju = dbRowToSajuInput(candidate);
      if (!partnerSaju) continue; // 파싱 실패 시 스킵

      const fiveElementScore = scoreFiveElements(mySaju, partnerSaju);
      const dayPillarScore = scoreDayPillar(mySaju, partnerSaju);
      const otherScore = scoreOtherPillars(mySaju, partnerSaju);
      const score = totalScore(dayPillarScore, fiveElementScore, otherScore);

      const { strengths, challenges } = buildStrengthsAndChallenges(
        mySaju,
        partnerSaju,
        fiveElementScore,
        dayPillarScore,
        score,
      );

      rows.push({
        user_id: userId,
        partner_id: candidate.user_id,
        total_score: score,
        five_element_score: fiveElementScore,
        day_pillar_score: dayPillarScore,
        overall_analysis: overallAnalysis(score),
        strengths,
        challenges,
        advice: "서로의 차이를 인정하고, 말로 풀어보세요. 배려와 소통이 좋은 관계의 시작이에요.",
        ai_story: null,
        is_detailed: false,
        calculated_at: new Date().toISOString(),
      });

      // 배치 크기에 도달하면 upsert
      if (rows.length >= BATCH_SIZE) {
        const { error: upsertErr } = await supabase
          .from("saju_compatibility")
          .upsert(rows, { onConflict: "user_id,partner_id" });
        if (upsertErr) {
          console.error(`[batch-compat] upsert 실패 (배치 ${calculated}~${calculated + rows.length}):`, upsertErr.message);
        } else {
          calculated += rows.length;
        }
        rows.length = 0; // 배열 비우기
      }
    }

    // 남은 행 upsert
    if (rows.length > 0) {
      const { error: upsertErr } = await supabase
        .from("saju_compatibility")
        .upsert(rows, { onConflict: "user_id,partner_id" });
      if (upsertErr) {
        console.error("[batch-compat] 최종 upsert 실패:", upsertErr.message);
      } else {
        calculated += rows.length;
      }
    }

    console.log(`[batch-compat] userId=${userId} | calculated=${calculated} | total=${candidates.length} | alreadyExisted=${alreadyExisted}`);

    return new Response(
      JSON.stringify({
        calculated,
        total: candidates.length,
        alreadyExisted,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal server error";
    console.error("[batch-compat] 예외:", message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
