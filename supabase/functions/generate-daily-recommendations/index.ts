// =============================================================================
// 섹션별 일일 추천 생성 Edge Function
// =============================================================================
// saju_compatibility 테이블의 사전 계산된 궁합 점수를 기반으로
// 섹션별(destiny/compatibility/gwansang/new) 일일 추천을 생성합니다.
//
// - isInitial=true: 사주 분석 직후 첫 추천 (상위 5명 → destiny 섹션)
// - isInitial=false: 일반 일일 추천 (4개 섹션으로 분배)
//
// SERVICE_ROLE_KEY로 RLS를 바이패스합니다.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------------
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---------------------------------------------------------------------------
// 타입
// ---------------------------------------------------------------------------
type Section = "destiny" | "compatibility" | "gwansang" | "new";

interface RequestBody {
  userId: string;
  isInitial?: boolean;
}

interface SectionCounts {
  destiny: number;
  compatibility: number;
  gwansang: number;
  new: number;
}

// ---------------------------------------------------------------------------
// 입력 검증
// ---------------------------------------------------------------------------
function validateRequest(body: unknown): RequestBody {
  if (!body || typeof body !== "object") {
    throw new Error("Request body must be a JSON object");
  }
  const o = body as Record<string, unknown>;
  if (!o.userId || typeof o.userId !== "string") {
    throw new Error("userId is required and must be a string (UUID)");
  }
  // UUID 형식 검증 (느슨하게)
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(o.userId)) {
    throw new Error("userId must be a valid UUID");
  }
  return {
    userId: o.userId,
    isInitial: typeof o.isInitial === "boolean" ? o.isInitial : false,
  };
}

// ---------------------------------------------------------------------------
// Supabase 클라이언트 (service role — RLS 바이패스)
// ---------------------------------------------------------------------------
function getSupabaseAdmin() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
  });
}

// ---------------------------------------------------------------------------
// 오늘 날짜 (KST 기준)
// ---------------------------------------------------------------------------
function getTodayKST(): string {
  const now = new Date();
  // KST = UTC+9
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return kst.toISOString().slice(0, 10); // YYYY-MM-DD
}

// ---------------------------------------------------------------------------
// 제외 대상 집합 구축
// ---------------------------------------------------------------------------
async function buildExclusionSet(
  supabase: ReturnType<typeof getSupabaseAdmin>,
  userId: string,
): Promise<Set<string>> {
  const excluded = new Set<string>();
  excluded.add(userId); // 자기 자신

  // 1. 이미 좋아요 보낸 상대
  const { data: likes } = await supabase
    .from("likes")
    .select("receiver_id")
    .eq("sender_id", userId);
  if (likes) {
    for (const l of likes) excluded.add(l.receiver_id);
  }

  // 2. 차단한/차단당한 상대
  const { data: blocksOut } = await supabase
    .from("blocks")
    .select("blocked_id")
    .eq("blocker_id", userId);
  if (blocksOut) {
    for (const b of blocksOut) excluded.add(b.blocked_id);
  }
  const { data: blocksIn } = await supabase
    .from("blocks")
    .select("blocker_id")
    .eq("blocked_id", userId);
  if (blocksIn) {
    for (const b of blocksIn) excluded.add(b.blocker_id);
  }

  // 3. 이미 매칭된 상대 (unmatched_at이 NULL인 활성 매칭)
  const { data: matches1 } = await supabase
    .from("matches")
    .select("user2_id")
    .eq("user1_id", userId)
    .is("unmatched_at", null);
  if (matches1) {
    for (const m of matches1) excluded.add(m.user2_id);
  }
  const { data: matches2 } = await supabase
    .from("matches")
    .select("user1_id")
    .eq("user2_id", userId)
    .is("unmatched_at", null);
  if (matches2) {
    for (const m of matches2) excluded.add(m.user1_id);
  }

  return excluded;
}

// ---------------------------------------------------------------------------
// 궁합 점수 후보 가져오기
// ---------------------------------------------------------------------------
interface CompatCandidate {
  partnerId: string;
  totalScore: number;
  compatibilityId: string;
}

async function fetchCompatibilityCandidates(
  supabase: ReturnType<typeof getSupabaseAdmin>,
  userId: string,
  excluded: Set<string>,
): Promise<CompatCandidate[]> {
  // 궁합 점수 내림차순으로 가져오기 (넉넉히 가져와서 필터링)
  const { data, error } = await supabase
    .from("saju_compatibility")
    .select("id, partner_id, total_score")
    .eq("user_id", userId)
    .order("total_score", { ascending: false })
    .limit(200);

  if (error) {
    console.error("Error fetching compatibility:", error.message);
    return [];
  }
  if (!data || data.length === 0) return [];

  // 제외 대상 필터링 + 삭제된 프로필 제외는 아래에서 별도 처리
  return data
    .filter((row: { partner_id: string }) => !excluded.has(row.partner_id))
    .map(
      (row: {
        id: string;
        partner_id: string;
        total_score: number;
      }): CompatCandidate => ({
        partnerId: row.partner_id,
        totalScore: row.total_score,
        compatibilityId: row.id,
      }),
    );
}

// ---------------------------------------------------------------------------
// 활성 프로필 필터 (deleted_at IS NULL)
// ---------------------------------------------------------------------------
async function filterActiveProfiles(
  supabase: ReturnType<typeof getSupabaseAdmin>,
  userIds: string[],
): Promise<Set<string>> {
  if (userIds.length === 0) return new Set();

  // Supabase .in()은 최대 수백 개까지 OK
  const { data } = await supabase
    .from("profiles")
    .select("id")
    .in("id", userIds)
    .is("deleted_at", null);

  return new Set((data || []).map((p: { id: string }) => p.id));
}

// ---------------------------------------------------------------------------
// 관상 프로필 있는 유저 ID 목록
// ---------------------------------------------------------------------------
async function fetchGwansangUserIds(
  supabase: ReturnType<typeof getSupabaseAdmin>,
  candidateIds: string[],
): Promise<Set<string>> {
  if (candidateIds.length === 0) return new Set();

  const { data } = await supabase
    .from("gwansang_profiles")
    .select("user_id")
    .in("user_id", candidateIds);

  return new Set((data || []).map((g: { user_id: string }) => g.user_id));
}

// ---------------------------------------------------------------------------
// 신규 유저 ID (7일 이내 가입)
// ---------------------------------------------------------------------------
async function fetchNewUserIds(
  supabase: ReturnType<typeof getSupabaseAdmin>,
  candidateIds: string[],
): Promise<Set<string>> {
  if (candidateIds.length === 0) return new Set();

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const cutoff = sevenDaysAgo.toISOString();

  const { data } = await supabase
    .from("profiles")
    .select("id")
    .in("id", candidateIds)
    .gte("created_at", cutoff)
    .is("deleted_at", null);

  return new Set((data || []).map((p: { id: string }) => p.id));
}

// ---------------------------------------------------------------------------
// 섹션 분배 (isInitial=true / false)
// ---------------------------------------------------------------------------
interface RecommendationRow {
  userId: string;
  recommendedId: string;
  compatibilityId: string | null;
  section: Section;
}

function assignSections(
  candidates: CompatCandidate[],
  isInitial: boolean,
  gwansangUserIds: Set<string>,
  newUserIds: Set<string>,
): RecommendationRow[] {
  const rows: RecommendationRow[] = [];
  const assigned = new Set<string>();

  if (isInitial) {
    // 첫 추천: 상위 5명 → destiny 섹션
    const top5 = candidates.slice(0, 5);
    for (const c of top5) {
      rows.push({
        userId: "", // 아래에서 채움
        recommendedId: c.partnerId,
        compatibilityId: c.compatibilityId,
        section: "destiny",
      });
      assigned.add(c.partnerId);
    }
    return rows;
  }

  // 일반 일일 추천: 4개 섹션 분배
  // 각 유저는 1개 섹션에만 등장 (중복 없음)

  // 1. destiny: score >= 85, max 5
  for (const c of candidates) {
    if (assigned.size >= 38) break; // 전체 상한 (5+15+8+10)
    if (c.totalScore >= 85 && !assigned.has(c.partnerId) && rows.filter((r) => r.section === "destiny").length < 5) {
      rows.push({
        userId: "",
        recommendedId: c.partnerId,
        compatibilityId: c.compatibilityId,
        section: "destiny",
      });
      assigned.add(c.partnerId);
    }
  }

  // 2. compatibility: 나머지 상위 점수, max 15
  for (const c of candidates) {
    if (assigned.has(c.partnerId)) continue;
    if (rows.filter((r) => r.section === "compatibility").length >= 15) break;
    rows.push({
      userId: "",
      recommendedId: c.partnerId,
      compatibilityId: c.compatibilityId,
      section: "compatibility",
    });
    assigned.add(c.partnerId);
  }

  // 3. gwansang: 관상 프로필이 있는 유저, max 8
  // 이미 위 섹션에 배정된 유저는 제외
  for (const c of candidates) {
    if (assigned.has(c.partnerId)) continue;
    if (!gwansangUserIds.has(c.partnerId)) continue;
    if (rows.filter((r) => r.section === "gwansang").length >= 8) break;
    rows.push({
      userId: "",
      recommendedId: c.partnerId,
      compatibilityId: c.compatibilityId,
      section: "gwansang",
    });
    assigned.add(c.partnerId);
  }

  // 4. new: 7일 이내 가입한 유저, max 10
  for (const c of candidates) {
    if (assigned.has(c.partnerId)) continue;
    if (!newUserIds.has(c.partnerId)) continue;
    if (rows.filter((r) => r.section === "new").length >= 10) break;
    rows.push({
      userId: "",
      recommendedId: c.partnerId,
      compatibilityId: c.compatibilityId,
      section: "new",
    });
    assigned.add(c.partnerId);
  }

  return rows;
}

// ---------------------------------------------------------------------------
// 메인 핸들러
// ---------------------------------------------------------------------------
Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

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
    const { userId, isInitial } = validateRequest(body);

    const supabase = getSupabaseAdmin();
    const today = getTodayKST();

    // -----------------------------------------------------------------------
    // 1. 이미 오늘 추천이 존재하는지 확인
    // -----------------------------------------------------------------------
    if (!isInitial) {
      const { data: existing, error: existErr } = await supabase
        .from("daily_matches")
        .select("id")
        .eq("user_id", userId)
        .eq("match_date", today)
        .limit(1);

      if (existErr) {
        console.error("Error checking existing matches:", existErr.message);
      }

      if (existing && existing.length > 0) {
        return new Response(
          JSON.stringify({ status: "already_generated" }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
    }

    // -----------------------------------------------------------------------
    // 2. 제외 대상 구축
    // -----------------------------------------------------------------------
    const excluded = await buildExclusionSet(supabase, userId);

    // -----------------------------------------------------------------------
    // 3. 궁합 후보 가져오기
    // -----------------------------------------------------------------------
    const candidates = await fetchCompatibilityCandidates(
      supabase,
      userId,
      excluded,
    );

    if (candidates.length === 0) {
      // 궁합 데이터가 아직 없는 경우 (batch-calculate가 아직 안 된 상태)
      return new Response(
        JSON.stringify({
          status: "no_candidates",
          total: 0,
          sections: { destiny: 0, compatibility: 0, gwansang: 0, new: 0 },
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // -----------------------------------------------------------------------
    // 4. 활성 프로필 필터링 (삭제된 유저 제외)
    // -----------------------------------------------------------------------
    const candidateIds = candidates.map((c) => c.partnerId);
    const activeIds = await filterActiveProfiles(supabase, candidateIds);
    const activeCandidates = candidates.filter((c) =>
      activeIds.has(c.partnerId)
    );

    if (activeCandidates.length === 0) {
      return new Response(
        JSON.stringify({
          status: "no_candidates",
          total: 0,
          sections: { destiny: 0, compatibility: 0, gwansang: 0, new: 0 },
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // -----------------------------------------------------------------------
    // 5. 관상/신규 유저 정보 병렬 조회
    // -----------------------------------------------------------------------
    const activeCandidateIds = activeCandidates.map((c) => c.partnerId);
    const [gwansangUserIds, newUserIds] = await Promise.all([
      fetchGwansangUserIds(supabase, activeCandidateIds),
      fetchNewUserIds(supabase, activeCandidateIds),
    ]);

    // -----------------------------------------------------------------------
    // 6. 섹션 분배
    // -----------------------------------------------------------------------
    const rows = assignSections(
      activeCandidates,
      isInitial ?? false,
      gwansangUserIds,
      newUserIds,
    );

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({
          status: "no_candidates",
          total: 0,
          sections: { destiny: 0, compatibility: 0, gwansang: 0, new: 0 },
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // userId 채우기
    for (const row of rows) {
      row.userId = userId;
    }

    // -----------------------------------------------------------------------
    // 7. 기존 오늘 추천 삭제 (isInitial일 때 재생성 대응)
    // -----------------------------------------------------------------------
    const { error: deleteErr } = await supabase
      .from("daily_matches")
      .delete()
      .eq("user_id", userId)
      .eq("match_date", today);

    if (deleteErr) {
      console.error("Error deleting existing matches:", deleteErr.message);
      // 삭제 실패해도 계속 진행 — unique 제약에 걸리면 upsert로 대응
    }

    // -----------------------------------------------------------------------
    // 8. 새 추천 INSERT
    // -----------------------------------------------------------------------
    const insertRows = rows.map((r) => ({
      user_id: r.userId,
      recommended_id: r.recommendedId,
      compatibility_id: r.compatibilityId,
      match_date: today,
      section: r.section,
      is_viewed: false,
      photo_revealed: false,
    }));

    const { error: insertErr } = await supabase
      .from("daily_matches")
      .insert(insertRows);

    if (insertErr) {
      console.error("Error inserting daily matches:", insertErr.message);
      throw new Error(`Failed to insert daily matches: ${insertErr.message}`);
    }

    // -----------------------------------------------------------------------
    // 9. 섹션별 카운트 집계
    // -----------------------------------------------------------------------
    const sections: SectionCounts = { destiny: 0, compatibility: 0, gwansang: 0, new: 0 };
    for (const r of rows) {
      sections[r.section]++;
    }

    return new Response(
      JSON.stringify({
        status: "generated",
        total: rows.length,
        sections,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal server error";
    const status =
      message.startsWith("userId") || message.startsWith("Request body")
        ? 400
        : 500;

    console.error("generate-daily-recommendations error:", message);

    return new Response(JSON.stringify({ error: message }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
