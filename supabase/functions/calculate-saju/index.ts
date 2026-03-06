// =============================================================================
// 사주팔자 (Four Pillars) Calculator — Supabase Edge Function
// =============================================================================
// 만세력 기준 정확한 사주 계산. 한국천문연구원(KASI) 데이터 기반
// @fullstackfamily/manseryeok 라이브러리 사용 (절기·음력 보정 포함).
//
// [2026-03-06] 진태양시(真太陽時) 보정 추가
// - 경도보정: (KST 기선 135°E - 출생지 경도) × 4분
// - 균시차(Equation of Time): Spencer(1971) 공식
// - 서머타임 보정: 한국 1948-1988년 DST 기간
// - 기본 경도: 서울 126.978°E (한국 사용자 기본값)
// =============================================================================

import { calculateSaju, lunarToSolar } from "npm:@fullstackfamily/manseryeok@1.0.7";

// ---------------------------------------------------------------------------
// 오행 매핑 (천간·지지 → wood/fire/earth/metal/water)
// ---------------------------------------------------------------------------
type FiveElement = "wood" | "fire" | "earth" | "metal" | "water";

const STEM_TO_ELEMENT: Record<string, FiveElement> = {
  갑: "wood", 을: "wood",
  병: "fire", 정: "fire",
  무: "earth", 기: "earth",
  경: "metal", 신: "metal",
  임: "water", 계: "water",
};

const BRANCH_TO_ELEMENT: Record<string, FiveElement> = {
  인: "wood", 묘: "wood",
  사: "fire", 오: "fire",
  축: "earth", 진: "earth", 미: "earth", 술: "earth",
  신: "metal", 유: "metal",
  자: "water", 해: "water",
};

// ---------------------------------------------------------------------------
// 진태양시(真太陽時) 보정
// ---------------------------------------------------------------------------

/** 한국 표준시 기선 경도 (135°E, 일본 아카시 자오선) */
const KST_STANDARD_MERIDIAN = 135;

/** 서울 경도 (기본값) */
const DEFAULT_LONGITUDE = 126.978;

/** 12지지 (시주용) */
const HOUR_BRANCHES = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"];

/** 10천간 */
const TEN_STEMS = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"];

/**
 * 균시차(Equation of Time) 계산 — Spencer(1971) 공식
 * 지구 공전궤도 이심률 + 자전축 기울기로 인한 시태양시와 평균태양시의 차이.
 * 정확도 ±0.5분.
 * @returns 균시차 (분 단위, 양수 = 태양이 평균보다 빠름)
 */
function equationOfTime(year: number, month: number, day: number): number {
  const date = new Date(year, month - 1, day);
  const startOfYear = new Date(year, 0, 1);
  const dayOfYear = Math.floor((date.getTime() - startOfYear.getTime()) / 86400000) + 1;

  const B = (2 * Math.PI * (dayOfYear - 1)) / 365;
  return 229.18 * (
    0.000075 +
    0.001868 * Math.cos(B) -
    0.032077 * Math.sin(B) -
    0.014615 * Math.cos(2 * B) -
    0.04089 * Math.sin(2 * B)
  );
}

/**
 * 한국 서머타임(일광절약시간) 적용 여부
 * 1948-1960, 1987-1988년 총 12회 시행
 */
function isKoreanDST(year: number, month: number, day: number): boolean {
  const DST_PERIODS: Array<{ year: number; start: [number, number]; end: [number, number] }> = [
    { year: 1948, start: [6, 1], end: [9, 12] },
    { year: 1949, start: [4, 3], end: [9, 10] },
    { year: 1950, start: [4, 1], end: [9, 9] },
    { year: 1951, start: [5, 6], end: [9, 8] },
    { year: 1955, start: [5, 5], end: [9, 8] },
    { year: 1956, start: [5, 20], end: [9, 29] },
    { year: 1957, start: [5, 5], end: [9, 21] },
    { year: 1958, start: [5, 4], end: [9, 20] },
    { year: 1959, start: [5, 3], end: [9, 19] },
    { year: 1960, start: [5, 1], end: [9, 17] },
    { year: 1987, start: [5, 10], end: [10, 10] },
    { year: 1988, start: [5, 8], end: [10, 8] },
  ];

  const period = DST_PERIODS.find((p) => p.year === year);
  if (!period) return false;

  const d = new Date(year, month - 1, day);
  const start = new Date(year, period.start[0] - 1, period.start[1]);
  const end = new Date(year, period.end[0] - 1, period.end[1]);
  return d >= start && d <= end;
}

/**
 * 진태양시 보정 적용
 *
 * 공식: 진태양시 = 표준시 + 4×(출생지경도 - 기선경도) + 균시차 - 서머타임
 *   - 경도보정: 서울(127°)은 기선(135°)보다 서쪽이므로 시간이 -32분
 *   - 균시차: 날짜에 따라 -14.5분 ~ +16.5분
 *   - 서머타임: 해당 기간이면 -60분
 *
 * @returns 보정된 시간 (시주 결정용)과 보정 상세값
 */
function applyTrueSolarTime(
  year: number, month: number, day: number,
  hour: number, minute: number,
  longitude: number = DEFAULT_LONGITUDE,
): {
  correctedHour: number;
  correctedMinute: number;
  longitudeCorrection: number;
  eotCorrection: number;
  dstCorrection: number;
  totalCorrection: number;
} {
  let totalMinutes = hour * 60 + minute;

  // 1. 서머타임 보정 (해당 기간이면 1시간 빼기)
  const dstCorrection = isKoreanDST(year, month, day) ? -60 : 0;
  totalMinutes += dstCorrection;

  // 2. 경도 보정: 4 × (출생지경도 - 기선경도)
  const longitudeCorrection = (longitude - KST_STANDARD_MERIDIAN) * 4;
  totalMinutes += longitudeCorrection;

  // 3. 균시차 보정
  const eotCorrection = equationOfTime(year, month, day);
  totalMinutes += eotCorrection;

  // 4. 0-1439 범위로 정규화 (날짜 경계 처리)
  totalMinutes = ((totalMinutes % 1440) + 1440) % 1440;

  const correctedHour = Math.floor(totalMinutes / 60);
  const correctedMinute = Math.round(totalMinutes % 60);

  return {
    correctedHour,
    correctedMinute,
    longitudeCorrection: Math.round(longitudeCorrection * 100) / 100,
    eotCorrection: Math.round(eotCorrection * 100) / 100,
    dstCorrection,
    totalCorrection: Math.round((longitudeCorrection + eotCorrection + dstCorrection) * 100) / 100,
  };
}

/**
 * 시간 → 12지지 인덱스 변환
 *
 * 子시(23-01) 丑시(01-03) 寅시(03-05) 卯시(05-07) 辰시(07-09) 巳시(09-11)
 * 午시(11-13) 未시(13-15) 申시(15-17) 酉시(17-19) 戌시(19-21) 亥시(21-23)
 */
function hourToBranchIndex(hour: number): number {
  if (hour === 23) return 0; // 子시 시작
  return Math.floor((hour + 1) / 2);
}

/**
 * 오서둔일(五鼠遁日) — 일간(日干)으로부터 시간(時干) 결정
 *
 * 甲/己일 → 子시=甲 (offset 0)
 * 乙/庚일 → 子시=丙 (offset 2)
 * 丙/辛일 → 子시=戊 (offset 4)
 * 丁/壬일 → 子시=庚 (offset 6)
 * 戊/癸일 → 子시=壬 (offset 8)
 */
function calculateHourStem(dayStem: string, branchIndex: number): string {
  const stemIndex = TEN_STEMS.indexOf(dayStem);
  if (stemIndex === -1) return "갑"; // fallback
  const startOffset = (stemIndex % 5) * 2;
  return TEN_STEMS[(startOffset + branchIndex) % 10];
}

/**
 * 진태양시 보정된 시주 계산
 *
 * 연주/월주/일주는 manseryeok 라이브러리의 결과를 그대로 사용하고,
 * 시주만 진태양시로 보정하여 재계산합니다.
 * (점신 등 정통 만세력 서비스와 동일한 방식)
 */
function calculateCorrectedHourPillar(
  year: number, month: number, day: number,
  hour: number, minute: number,
  dayStem: string,
  longitude: number = DEFAULT_LONGITUDE,
): {
  hourPillar: { stem: string; branch: string };
  trueSolarTime: {
    correctedHour: number;
    correctedMinute: number;
    longitudeCorrection: number;
    eotCorrection: number;
    dstCorrection: number;
    totalCorrection: number;
  };
} {
  const tst = applyTrueSolarTime(year, month, day, hour, minute, longitude);
  const branchIndex = hourToBranchIndex(tst.correctedHour);
  const branch = HOUR_BRANCHES[branchIndex];
  const stem = calculateHourStem(dayStem, branchIndex);

  return {
    hourPillar: { stem, branch },
    trueSolarTime: tst,
  };
}

// ---------------------------------------------------------------------------
// Pillar utilities
// ---------------------------------------------------------------------------

function pillarToStemBranch(pillarStr: string): { stem: string; branch: string } {
  if (!pillarStr || pillarStr.length < 2) {
    return { stem: "갑", branch: "자" };
  }
  return {
    stem: pillarStr[0]!,
    branch: pillarStr[1]!,
  };
}

function countFiveElements(pillars: Array<{ stem: string; branch: string }>): Record<FiveElement, number> {
  const counts: Record<FiveElement, number> = {
    wood: 0, fire: 0, earth: 0, metal: 0, water: 0,
  };
  for (const { stem, branch } of pillars) {
    const se = STEM_TO_ELEMENT[stem];
    const be = BRANCH_TO_ELEMENT[branch];
    if (se) counts[se]++;
    if (be) counts[be]++;
  }
  return counts;
}

function getDominantElement(dayStem: string): FiveElement {
  return STEM_TO_ELEMENT[dayStem] ?? "wood";
}

// ---------------------------------------------------------------------------
// Request validation
// ---------------------------------------------------------------------------
interface RequestBody {
  birthDate: string;
  birthTime: string | null;
  isLunar: boolean;
  isLeapMonth?: boolean;
  longitude?: number;
}

function validateRequest(body: unknown): RequestBody {
  if (!body || typeof body !== "object") {
    throw new Error("Request body must be a JSON object");
  }

  const { birthDate, birthTime, isLunar, isLeapMonth, longitude } = body as Record<string, unknown>;

  if (!birthDate || typeof birthDate !== "string") {
    throw new Error("birthDate is required and must be a string in YYYY-MM-DD format");
  }

  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(birthDate)) {
    throw new Error("birthDate must be in YYYY-MM-DD format");
  }

  const [yearStr, monthStr, dayStr] = birthDate.split("-");
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const day = parseInt(dayStr, 10);

  if (year < 1900 || year > 2050) {
    throw new Error("birthDate year must be between 1900 and 2050 (KASI 지원 범위)");
  }
  if (month < 1 || month > 12) {
    throw new Error("birthDate month must be between 1 and 12");
  }
  if (day < 1 || day > 31) {
    throw new Error("birthDate day must be between 1 and 31");
  }

  if (birthTime !== null && birthTime !== undefined) {
    if (typeof birthTime !== "string") {
      throw new Error("birthTime must be a string in HH:mm format or null");
    }
    const timeRegex = /^\d{2}:\d{2}$/;
    if (!timeRegex.test(birthTime)) {
      throw new Error("birthTime must be in HH:mm format");
    }
    const [hourStr, minStr] = birthTime.split(":");
    const hour = parseInt(hourStr, 10);
    const min = parseInt(minStr, 10);
    if (hour < 0 || hour > 23 || min < 0 || min > 59) {
      throw new Error("birthTime hour must be 0-23 and minute must be 0-59");
    }
  }

  let lng: number | undefined;
  if (longitude !== null && longitude !== undefined) {
    lng = typeof longitude === "number" ? longitude : parseFloat(String(longitude));
    if (isNaN(lng) || lng < 60 || lng > 180) {
      lng = undefined; // 비정상 값은 무시 → 기본값 사용
    }
  }

  return {
    birthDate,
    birthTime: (birthTime as string | null) ?? null,
    isLunar: typeof isLunar === "boolean" ? isLunar : false,
    isLeapMonth: typeof isLeapMonth === "boolean" ? isLeapMonth : false,
    longitude: lng,
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
// Main handler
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
    const { birthDate, birthTime, isLunar, isLeapMonth, longitude } = validateRequest(body);

    const [yearStr, monthStr, dayStr] = birthDate.split("-");
    let year = parseInt(yearStr, 10);
    let month = parseInt(monthStr, 10);
    let day = parseInt(dayStr, 10);

    // 음력 → 양력 변환 (만세력 라이브러리 KASI 데이터 기반)
    if (isLunar) {
      const solar = lunarToSolar(year, month, day, isLeapMonth ?? false);
      year = solar.solar.year;
      month = solar.solar.month;
      day = solar.solar.day;
    }

    let hour = 0;
    let minute = 0;
    if (birthTime) {
      const [h, m] = birthTime.split(":").map((s) => parseInt(s, 10));
      hour = h ?? 0;
      minute = m ?? 0;
    }

    // 만세력 기반 사주 계산 (연주·월주·일주는 원시 시간 사용)
    const saju = calculateSaju(year, month, day, hour, minute);

    const yearSb = pillarToStemBranch(saju.yearPillar);
    const monthSb = pillarToStemBranch(saju.monthPillar);
    const daySb = pillarToStemBranch(saju.dayPillar);

    // -----------------------------------------------------------------------
    // 시주: 진태양시 보정 적용 (연주/월주/일주는 영향 없음)
    // -----------------------------------------------------------------------
    let hourSb: { stem: string; branch: string } | null = null;
    let trueSolarTimeInfo: Record<string, unknown> | null = null;

    if (birthTime != null) {
      const lng = longitude ?? DEFAULT_LONGITUDE;
      const result = calculateCorrectedHourPillar(
        year, month, day, hour, minute, daySb.stem, lng,
      );
      hourSb = result.hourPillar;
      trueSolarTimeInfo = {
        applied: true,
        longitude: lng,
        ...result.trueSolarTime,
      };
    }

    // -----------------------------------------------------------------------
    // 오행 분포 계산
    // -----------------------------------------------------------------------
    const allPillars = [yearSb, monthSb, daySb];
    if (hourSb) allPillars.push(hourSb);
    const fiveElements = countFiveElements(allPillars);
    const dominantElement = getDominantElement(daySb.stem);

    const response: Record<string, unknown> = {
      yearPillar: { stem: yearSb.stem, branch: yearSb.branch },
      monthPillar: { stem: monthSb.stem, branch: monthSb.branch },
      dayPillar: { stem: daySb.stem, branch: daySb.branch },
      hourPillar: hourSb
        ? { stem: hourSb.stem, branch: hourSb.branch }
        : null,
      fiveElements,
      dominantElement,
      birthDate: `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`,
      birthTime: birthTime ?? null,
      isLunar,
      trueSolarTime: trueSolarTimeInfo,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    const status =
      message.startsWith("birthDate") ||
      message.startsWith("birthTime") ||
      message.startsWith("Request body")
        ? 400
        : 500;

    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
