// =============================================================================
// 사주팔자 (Four Pillars of Destiny) Calculator — Supabase Edge Function
// =============================================================================
// Pure TypeScript, Deno-compatible. No external dependencies.
// Calculates year/month/day/hour pillars based on traditional Korean 명리학.
// =============================================================================

// ---------------------------------------------------------------------------
// Constants: 천간 (Heavenly Stems) & 지지 (Earthly Branches)
// ---------------------------------------------------------------------------

const HEAVENLY_STEMS_KR = [
  "갑", "을", "병", "정", "무", "기", "경", "신", "임", "계",
] as const;

const HEAVENLY_STEMS_HANJA = [
  "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸",
] as const;

const EARTHLY_BRANCHES_KR = [
  "자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해",
] as const;

const EARTHLY_BRANCHES_HANJA = [
  "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥",
] as const;

const ZODIAC_ANIMALS = [
  "쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지",
] as const;

// ---------------------------------------------------------------------------
// Element mappings
// ---------------------------------------------------------------------------

type FiveElement = "wood" | "fire" | "earth" | "metal" | "water";

const STEM_TO_ELEMENT: Record<string, FiveElement> = {
  "갑": "wood", "을": "wood",
  "병": "fire", "정": "fire",
  "무": "earth", "기": "earth",
  "경": "metal", "신": "metal",
  "임": "water", "계": "water",
};

const BRANCH_TO_ELEMENT: Record<string, FiveElement> = {
  "인": "wood", "묘": "wood",
  "사": "fire", "오": "fire",
  "축": "earth", "진": "earth", "미": "earth", "술": "earth",
  "신": "metal", "유": "metal",
  "자": "water", "해": "water",
};

// ---------------------------------------------------------------------------
// 절기 (Solar Terms) boundaries — approximate day-of-year for month boundaries
// ---------------------------------------------------------------------------
// In 사주, months are determined by 절기 (solar terms), not calendar months.
// Each 절(節) marks the start of a new saju month.
// The boundaries below are approximate midpoints (Gregorian) for each 절기.
// Month 1 (인월/寅月) starts at 입춘 (~Feb 4).
//
// Index 0 = 입춘 (start of month 1 / 인월)
// Index 1 = 경칩 (start of month 2 / 묘월)
// ... through ...
// Index 11 = 소한 (start of month 12 / 축월)
// ---------------------------------------------------------------------------

interface SolarTermBoundary {
  month: number; // 1-12 (Gregorian month)
  day: number;   // day of that month
  sajuMonth: number; // 1-12 in saju system (1=인월, 2=묘월, ...)
}

const SOLAR_TERM_BOUNDARIES: SolarTermBoundary[] = [
  { month: 2,  day: 4,  sajuMonth: 1  }, // 입춘 — 인월(寅月) start
  { month: 3,  day: 6,  sajuMonth: 2  }, // 경칩 — 묘월(卯月)
  { month: 4,  day: 5,  sajuMonth: 3  }, // 청명 — 진월(辰月)
  { month: 5,  day: 6,  sajuMonth: 4  }, // 입하 — 사월(巳月)
  { month: 6,  day: 6,  sajuMonth: 5  }, // 망종 — 오월(午月)
  { month: 7,  day: 7,  sajuMonth: 6  }, // 소서 — 미월(未月)
  { month: 8,  day: 7,  sajuMonth: 7  }, // 입추 — 신월(申月)
  { month: 9,  day: 8,  sajuMonth: 8  }, // 백로 — 유월(酉月)
  { month: 10, day: 8,  sajuMonth: 9  }, // 한로 — 술월(戌月)
  { month: 11, day: 7,  sajuMonth: 10 }, // 입동 — 해월(亥月)
  { month: 12, day: 7,  sajuMonth: 11 }, // 대설 — 자월(子月)
  { month: 1,  day: 6,  sajuMonth: 12 }, // 소한 — 축월(丑月)
];

// ---------------------------------------------------------------------------
// Julian Day Number calculation
// ---------------------------------------------------------------------------
// Converts a Gregorian date to Julian Day Number using the standard algorithm.
// This is the astronomical Julian Day Number (integer part).
// ---------------------------------------------------------------------------

function toJulianDayNumber(year: number, month: number, day: number): number {
  // Adjust year and month for the algorithm (Jan/Feb are months 13/14 of previous year)
  let y = year;
  let m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }

  const A = Math.floor(y / 100);
  const B = 2 - A + Math.floor(A / 4);

  return Math.floor(365.25 * (y + 4716)) +
         Math.floor(30.6001 * (m + 1)) +
         day + B - 1524.5;
}

// ---------------------------------------------------------------------------
// Year Pillar (연주/年柱)
// ---------------------------------------------------------------------------
// The saju year starts at 입춘 (approximately Feb 4th).
// If the birth date is before 입춘, the previous year is used.
// Year stem = (year - 4) % 10, Year branch = (year - 4) % 12
// (Because 갑자년 = 4 AD, so offset by 4)
// ---------------------------------------------------------------------------

function getSajuYear(year: number, month: number, day: number): number {
  // 입춘 is approximately February 4th each year
  const ipchunMonth = 2;
  const ipchunDay = 4;

  if (month < ipchunMonth || (month === ipchunMonth && day < ipchunDay)) {
    return year - 1;
  }
  return year;
}

interface Pillar {
  heavenlyStem: string;
  earthlyBranch: string;
  hanja: string;
  animal?: string;
}

function calculateYearPillar(year: number, month: number, day: number): Pillar {
  const sajuYear = getSajuYear(year, month, day);

  const stemIndex = ((sajuYear - 4) % 10 + 10) % 10;
  const branchIndex = ((sajuYear - 4) % 12 + 12) % 12;

  return {
    heavenlyStem: HEAVENLY_STEMS_KR[stemIndex],
    earthlyBranch: EARTHLY_BRANCHES_KR[branchIndex],
    hanja: `${HEAVENLY_STEMS_HANJA[stemIndex]}${EARTHLY_BRANCHES_HANJA[branchIndex]}`,
    animal: ZODIAC_ANIMALS[branchIndex],
  };
}

// ---------------------------------------------------------------------------
// Month Pillar (월주/月柱)
// ---------------------------------------------------------------------------
// The saju month is determined by 절기 boundaries.
// The month stem is derived from the year stem using the 연간 기반 월간 공식:
//   monthStemBase = (yearStemIndex % 5) * 2
//   monthStem = (monthStemBase + sajuMonth - 1) % 10
// The month branch cycles: 인(2) for month 1, 묘(3) for month 2, etc.
// ---------------------------------------------------------------------------

function getSajuMonth(_year: number, month: number, day: number): number {
  // Determine which saju month based on 절기 (solar term) boundaries.
  // The saju month cycle:
  //   sajuMonth 1 (인월) starts at 입춘 ~Feb 4
  //   sajuMonth 2 (묘월) starts at 경칩 ~Mar 6
  //   ... through ...
  //   sajuMonth 11 (자월) starts at 대설 ~Dec 7
  //   sajuMonth 12 (축월) starts at 소한 ~Jan 6
  //
  // January dates need special handling since 소한 (Jan 6) falls in the middle.

  // Handle January: before 소한 = 자월(11), after 소한 = 축월(12)
  if (month === 1) {
    return day < 6 ? 11 : 12;
  }

  // Handle February before 입춘: still 축월(12)
  if (month === 2 && day < 4) {
    return 12;
  }

  // For Feb 4 through Dec 31, walk backwards through boundaries to find the match
  const dateVal = month * 100 + day;
  for (let i = SOLAR_TERM_BOUNDARIES.length - 2; i >= 0; i--) {
    const boundary = SOLAR_TERM_BOUNDARIES[i];
    if (boundary.month === 1) continue; // skip 소한 (handled above)

    const boundaryVal = boundary.month * 100 + boundary.day;
    if (dateVal >= boundaryVal) {
      return boundary.sajuMonth;
    }
  }

  // Fallback (should not reach here for valid dates)
  return 1;
}

function calculateMonthPillar(
  yearStemIndex: number,
  year: number,
  month: number,
  day: number,
): Pillar {
  const sajuMonth = getSajuMonth(year, month, day);

  // Month branch: 인월(寅) = index 2 for sajuMonth 1, 묘월(卯) = index 3 for sajuMonth 2, etc.
  const branchIndex = (sajuMonth + 1) % 12;

  // Month stem formula (연간 기반 월간 공식 / 년상기월법):
  // The first month (인월) of a 갑(0)/기(5) year starts with 병(2).
  // The first month of a 을(1)/경(6) year starts with 무(4).
  // The first month of a 병(2)/신(7) year starts with 경(6).
  // The first month of a 정(3)/임(8) year starts with 임(8).
  // The first month of a 무(4)/계(9) year starts with 갑(0).
  // Formula: monthStemBase = (yearStemIndex % 5) * 2 + 2, then offset by sajuMonth - 1
  const monthStemBase = ((yearStemIndex % 5) * 2 + 2) % 10;
  const stemIndex = (monthStemBase + sajuMonth - 1) % 10;

  return {
    heavenlyStem: HEAVENLY_STEMS_KR[stemIndex],
    earthlyBranch: EARTHLY_BRANCHES_KR[branchIndex],
    hanja: `${HEAVENLY_STEMS_HANJA[stemIndex]}${EARTHLY_BRANCHES_HANJA[branchIndex]}`,
  };
}

// ---------------------------------------------------------------------------
// Day Pillar (일주/日柱)
// ---------------------------------------------------------------------------
// Uses Julian Day Number to determine the day's 간지 (stem-branch pair).
// The 60-day 갑자 cycle is a continuous, unbroken cycle.
// stem = (floor(JDN) + 17) % 10, branch = (floor(JDN) + 17) % 12
// ---------------------------------------------------------------------------

function calculateDayPillar(year: number, month: number, day: number): Pillar {
  const jdn = toJulianDayNumber(year, month, day);

  // Offset aligns JDN with the traditional 60-day 갑자 cycle.
  // Reference: 2000-01-01 → JDN formula returns 2451544.5, floor = 2451544.
  // Known: 2000-01-01 = 乙酉 (을유, stem=1, branch=9).
  // (2451544 + 17) % 10 = 1 (을), (2451544 + 17) % 12 = 9 (유). Verified.
  const offset = 17;
  const adjustedJdn = Math.floor(jdn) + offset;
  const stemIndex = ((adjustedJdn % 10) + 10) % 10;
  const branchIndex = ((adjustedJdn % 12) + 12) % 12;

  return {
    heavenlyStem: HEAVENLY_STEMS_KR[stemIndex],
    earthlyBranch: EARTHLY_BRANCHES_KR[branchIndex],
    hanja: `${HEAVENLY_STEMS_HANJA[stemIndex]}${EARTHLY_BRANCHES_HANJA[branchIndex]}`,
  };
}

// ---------------------------------------------------------------------------
// Hour Pillar (시주/時柱)
// ---------------------------------------------------------------------------
// The hour branch is determined by the birth hour (24h format).
// The hour stem is derived from the day stem using 일간 기반 시간 공식 (일상기시법):
//   If dayStem is 갑(0)/기(5), 자시 starts with 갑(0).
//   If dayStem is 을(1)/경(6), 자시 starts with 병(2).
//   If dayStem is 병(2)/신(7), 자시 starts with 무(4).
//   If dayStem is 정(3)/임(8), 자시 starts with 경(6).
//   If dayStem is 무(4)/계(9), 자시 starts with 임(8).
// Formula: hourStemBase = (dayStemIndex % 5) * 2
//          hourStem = (hourStemBase + hourBranchIndex) % 10
// ---------------------------------------------------------------------------

function getHourBranchIndex(hour: number): number {
  // 자시: 23:00-00:59 → branchIndex 0
  if (hour === 23 || hour === 0) return 0;
  // 축시: 01:00-02:59 → branchIndex 1
  if (hour >= 1 && hour <= 2) return 1;
  // 인시: 03:00-04:59 → branchIndex 2
  if (hour >= 3 && hour <= 4) return 2;
  // 묘시: 05:00-06:59 → branchIndex 3
  if (hour >= 5 && hour <= 6) return 3;
  // 진시: 07:00-08:59 → branchIndex 4
  if (hour >= 7 && hour <= 8) return 4;
  // 사시: 09:00-10:59 → branchIndex 5
  if (hour >= 9 && hour <= 10) return 5;
  // 오시: 11:00-12:59 → branchIndex 6
  if (hour >= 11 && hour <= 12) return 6;
  // 미시: 13:00-14:59 → branchIndex 7
  if (hour >= 13 && hour <= 14) return 7;
  // 신시: 15:00-16:59 → branchIndex 8
  if (hour >= 15 && hour <= 16) return 8;
  // 유시: 17:00-18:59 → branchIndex 9
  if (hour >= 17 && hour <= 18) return 9;
  // 술시: 19:00-20:59 → branchIndex 10
  if (hour >= 19 && hour <= 20) return 10;
  // 해시: 21:00-22:59 → branchIndex 11
  return 11;
}

function calculateHourPillar(
  dayStemIndex: number,
  hour: number,
): Pillar {
  const branchIndex = getHourBranchIndex(hour);

  // 일상기시법 (Day-stem-based hour stem formula)
  const hourStemBase = (dayStemIndex % 5) * 2;
  const stemIndex = (hourStemBase + branchIndex) % 10;

  return {
    heavenlyStem: HEAVENLY_STEMS_KR[stemIndex],
    earthlyBranch: EARTHLY_BRANCHES_KR[branchIndex],
    hanja: `${HEAVENLY_STEMS_HANJA[stemIndex]}${EARTHLY_BRANCHES_HANJA[branchIndex]}`,
  };
}

// ---------------------------------------------------------------------------
// Five Elements distribution
// ---------------------------------------------------------------------------

interface FiveElements {
  wood: number;
  fire: number;
  earth: number;
  metal: number;
  water: number;
}

function countFiveElements(pillars: Pillar[]): FiveElements {
  const counts: FiveElements = { wood: 0, fire: 0, earth: 0, metal: 0, water: 0 };

  for (const pillar of pillars) {
    const stemElement = STEM_TO_ELEMENT[pillar.heavenlyStem];
    if (stemElement) counts[stemElement]++;

    const branchElement = BRANCH_TO_ELEMENT[pillar.earthlyBranch];
    if (branchElement) counts[branchElement]++;
  }

  return counts;
}

// ---------------------------------------------------------------------------
// Dominant element (from 일간 / Day Stem)
// ---------------------------------------------------------------------------

function getDominantElement(dayStem: string): FiveElement {
  return STEM_TO_ELEMENT[dayStem];
}

// ---------------------------------------------------------------------------
// Simple lunar-to-solar conversion (approximate)
// ---------------------------------------------------------------------------
// A production system should use a full lunar calendar lookup table.
// This is an approximation that shifts the date forward by ~30 days,
// which covers most cases for Korean lunar calendar dates.
// For accurate results, integrate a proper lunar calendar library or API.
// ---------------------------------------------------------------------------

function approximateLunarToSolar(year: number, month: number, day: number): {
  year: number;
  month: number;
  day: number;
} {
  // Korean lunar dates are typically 30-33 days behind solar dates.
  // This is a rough approximation. For production use, a full lookup table
  // from the Korean Astronomy and Space Science Institute (KASI) is recommended.
  const date = new Date(year, month - 1, day);
  // Add approximately 30 days to convert from lunar to solar (rough estimate)
  date.setDate(date.getDate() + 30);
  return {
    year: date.getFullYear(),
    month: date.getMonth() + 1,
    day: date.getDate(),
  };
}

// ---------------------------------------------------------------------------
// Input validation
// ---------------------------------------------------------------------------

interface RequestBody {
  birthDate: string;       // "YYYY-MM-DD"
  birthTime: string | null; // "HH:mm" or null
  isLunar: boolean;
}

function validateRequest(body: unknown): RequestBody {
  if (!body || typeof body !== "object") {
    throw new Error("Request body must be a JSON object");
  }

  const { birthDate, birthTime, isLunar } = body as Record<string, unknown>;

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

  if (year < 1900 || year > 2100) {
    throw new Error("birthDate year must be between 1900 and 2100");
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

  return {
    birthDate,
    birthTime: birthTime as string | null ?? null,
    isLunar: typeof isLunar === "boolean" ? isLunar : false,
  };
}

// ---------------------------------------------------------------------------
// CORS headers
// ---------------------------------------------------------------------------

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Only allow POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const body = await req.json();
    const { birthDate, birthTime, isLunar } = validateRequest(body);

    // Parse the birth date
    const [yearStr, monthStr, dayStr] = birthDate.split("-");
    let year = parseInt(yearStr, 10);
    let month = parseInt(monthStr, 10);
    let day = parseInt(dayStr, 10);

    // Convert lunar to solar if needed (approximate)
    if (isLunar) {
      const solar = approximateLunarToSolar(year, month, day);
      year = solar.year;
      month = solar.month;
      day = solar.day;
    }

    // Parse birth time
    let parsedHour: number | null = null;
    if (birthTime) {
      const [hourStr] = birthTime.split(":");
      parsedHour = parseInt(hourStr, 10);
    }

    // --- Calculate the Four Pillars ---

    // 1. Year Pillar (연주)
    const yearPillar = calculateYearPillar(year, month, day);
    const sajuYear = getSajuYear(year, month, day);
    const yearStemIndex = ((sajuYear - 4) % 10 + 10) % 10;

    // 2. Month Pillar (월주)
    const monthPillar = calculateMonthPillar(yearStemIndex, year, month, day);

    // 3. Day Pillar (일주)
    const dayPillar = calculateDayPillar(year, month, day);
    const dayStemIndex = HEAVENLY_STEMS_KR.indexOf(dayPillar.heavenlyStem);

    // 4. Hour Pillar (시주) — only if birthTime provided
    let hourPillar: Pillar | null = null;
    if (parsedHour !== null) {
      // If born at 23:00 or later (자시 of next day), the day pillar for
      // hour calculation advances to the next day's stem in some traditions.
      // We use the "야자시" (early 자시) convention: 23:00 still uses current day stem.
      hourPillar = calculateHourPillar(dayStemIndex, parsedHour);
    }

    // 5. Count Five Elements
    const pillarsForCount = [yearPillar, monthPillar, dayPillar];
    if (hourPillar) pillarsForCount.push(hourPillar);
    const fiveElements = countFiveElements(pillarsForCount);

    // 6. Dominant Element (from 일간)
    const dominantElement = getDominantElement(dayPillar.heavenlyStem);

    // --- Build response ---
    const response: Record<string, unknown> = {
      yearPillar: {
        heavenlyStem: yearPillar.heavenlyStem,
        earthlyBranch: yearPillar.earthlyBranch,
        hanja: yearPillar.hanja,
        animal: yearPillar.animal,
      },
      monthPillar: {
        heavenlyStem: monthPillar.heavenlyStem,
        earthlyBranch: monthPillar.earthlyBranch,
        hanja: monthPillar.hanja,
      },
      dayPillar: {
        heavenlyStem: dayPillar.heavenlyStem,
        earthlyBranch: dayPillar.earthlyBranch,
        hanja: dayPillar.hanja,
      },
      hourPillar: hourPillar
        ? {
            heavenlyStem: hourPillar.heavenlyStem,
            earthlyBranch: hourPillar.earthlyBranch,
            hanja: hourPillar.hanja,
          }
        : null,
      fiveElements,
      dominantElement,
      birthDate,
      birthTime: birthTime ?? null,
      isLunar,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    const status = message.startsWith("birthDate") || message.startsWith("birthTime") || message.startsWith("Request body")
      ? 400
      : 500;

    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
