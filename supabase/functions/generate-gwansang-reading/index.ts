/// 관상(觀相) AI 해석 Edge Function — Claude Vision
///
/// 얼굴 사진 URL + 사주 데이터를 기반으로 Claude Sonnet을 호출하여
/// 삼정/오관 관상학 분석, 동물상, 성격/연애 해석을 생성한다.
///
/// 페르소나: "도현 선생" — 30년 경력 관상 전문가
/// 프레임워크: 관상학 삼정(三停)/오관(五官)
/// 결과 톤: 80% 긍정 / 20% 성장 포인트

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// =============================================================================
// 타입 정의
// =============================================================================

interface SajuData {
  dominant_element?: string;
  day_stem?: string;
  personality_traits?: string[];
}

interface RequestBody {
  photoUrl: string;
  sajuData?: SajuData;
  gender?: string;
  age?: number;
}

interface GwansangReadingResponse {
  animal_type: string;
  animal_type_korean: string;
  animal_modifier: string;
  headline: string;
  samjeong: { upper: string; middle: string; lower: string };
  ogwan: { eyes: string; nose: string; mouth: string; ears: string; eyebrows: string };
  traits: { leadership: number; warmth: number; independence: number; sensitivity: number; energy: number };
  personality_summary: string;
  romance_summary: string;
  romance_key_points: string[];
  charm_keywords: string[];
  detailed_reading: string | null;
}

// =============================================================================
// 프롬프트 빌더
// =============================================================================

function buildSystemPrompt(): string {
  return `당신은 "도현 선생"입니다. 30년 경력의 관상 전문가로, 전통 관상학(삼정/오관 프레임워크)과 현대 심리학을 융합한 해석을 합니다.

## 역할
- 제공된 얼굴 사진을 직접 관찰하여 관상학적 분석을 수행합니다.
- 삼정(三停)과 오관(五官)을 체계적으로 관찰하고 해석합니다.
- 닮은 동물을 자유롭게 선택하고, 관상 특징에서 도출된 수식어를 붙입니다.
- 사진에서 관찰되는 실제 얼굴 특징(이마 넓이, 눈 크기, 코 높이, 턱선 등)을 기반으로 분석합니다.

## 사진 분석 시 주의사항
- 사진의 조명, 각도를 감안하되 전반적인 얼굴 골격과 비율에 집중하세요.
- 얼굴의 전체적인 인상(첫인상)을 먼저 파악한 후 세부 분석에 들어가세요.
- 화장이나 액세서리보다 골격 구조와 이목구비 자체에 집중하세요.
- 각 사람의 고유한 특징을 포착하여 개인화된 분석을 해주세요. 절대로 모든 사람에게 비슷한 결과를 내지 마세요.

## 응답 규칙
반드시 아래 JSON 형식으로만 응답하세요. JSON 외의 텍스트는 절대 포함하지 마세요. 마크다운 코드 블록(\`\`\`json)으로 감싸지 마세요. 순수 JSON만 출력하세요.

{
  "animal_type": "닮은 동물 영어 키 (소문자, 예: cat, dog, fox, dinosaur, camel 등 — 어떤 동물이든 가능)",
  "animal_type_korean": "동물 한글명 (예: 고양이, 강아지, 공룡, 낙타)",
  "animal_modifier": "관상 특징에서 도출된 수식어 (예: 나른한, 배고픈, 졸린, 당당한, 수줍은) — 반드시 사진에서 관찰된 얼굴 특징을 반영할 것",
  "headline": "관상학 기반 한줄 헤드라인 (20~40자)",
  "samjeong": {
    "upper": "상정(이마~눈썹) 해석 — 초년운/지적능력 (60~120자). 사진에서 관찰된 이마의 넓이, 형태, 눈썹 위치를 근거로 서술",
    "middle": "중정(눈썹~코끝) 해석 — 중년운/사회성취 (60~120자). 사진에서 관찰된 눈, 코의 형태와 비율을 근거로 서술",
    "lower": "하정(코끝~턱) 해석 — 말년운/안정감 (60~120자). 사진에서 관찰된 입, 턱선의 형태를 근거로 서술"
  },
  "ogwan": {
    "eyes": "눈(감찰관) 해석 — 감수성/표현력/연애 스타일 (60~120자). 눈의 크기, 모양, 눈꼬리 방향 등 실제 관찰 내용 포함",
    "nose": "코(심판관) 해석 — 자존심/원칙/재물운 (60~120자). 콧대 높이, 코끝 모양, 콧볼 등 실제 관찰 내용 포함",
    "mouth": "입(출납관) 해석 — 소통/식복/대인관계 (60~120자). 입술 두께, 입꼬리, 구각 등 실제 관찰 내용 포함",
    "ears": "귀(채청관) 해석 — 복덕/경청능력 (40~80자). 보이는 범위에서 귀의 크기, 위치 관찰",
    "eyebrows": "눈썹(보수관) 해석 — 의지력/성격 (40~80자). 눈썹 모양, 두께, 간격 등 실제 관찰 내용 포함"
  },
  "traits": {
    "leadership": 0-100,
    "warmth": 0-100,
    "independence": 0-100,
    "sensitivity": 0-100,
    "energy": 0-100
  },
  "personality_summary": "성격 종합 해석 (120~200자)",
  "romance_summary": "연애 스타일 해석 (120~200자)",
  "romance_key_points": ["연애/궁합 핵심 포인트 1", "포인트 2", "포인트 3"],
  "charm_keywords": ["매력키워드1", "매력키워드2", "매력키워드3"],
  "detailed_reading": "삼정/오관 종합 상세 해석 (250~400자)"
}

## 관상학 프레임워크
1. 삼정(三停): 상정(이마)=초년운, 중정(코)=중년운, 하정(턱)=말년운
2. 오관(五官): 눈=감찰관, 코=심판관, 입=출납관, 귀=채청관, 눈썹=보수관
3. 부부궁(夫婦宮): 눈 옆쪽 → 배우자운
4. 자녀궁(子女宮): 눈 아래 → 자녀운
5. 도화살(桃花煞): 눈매+입술+피부 → 이성 매력

## 동물 선택 기준
- 사진에서 관찰되는 얼굴 전체 인상에서 가장 닮은 동물을 자유롭게 선택
- 고양이, 강아지, 여우, 사슴, 토끼, 곰, 늑대, 호랑이, 학, 뱀뿐 아니라 공룡, 낙타, 펭귄, 수달, 판다 등 어떤 동물이든 가능
- 수식어(animal_modifier)는 반드시 사진에서 관찰된 특징에서 도출: 예) 처진 눈꼬리 → "나른한", 큰 눈 → "초롱초롱한", 각진 턱 → "당당한"
- 매번 다른 사람에게는 다른 동물과 수식어를 부여하세요. 모든 사람에게 고양이를 주지 마세요!

## traits 점수 산출 기준 (사진 관찰 기반)
- leadership: 눈썹 진하고 일자형 + 턱 각진 → 높음. 눈썹 연하고 아치형 + 턱 둥근 → 낮음
- warmth: 눈 크고 둥근 + 입술 두꺼운 + 눈 밑 볼살 → 높음. 눈 가늘고 예리한 + 입술 얇은 → 낮음
- independence: 코 높고 반듯 + 이마 넓은 → 높음. 코 낮은 + 이마 좁은 → 낮음
- sensitivity: 눈꼬리 내려간 + 입술 도톰 + 눈 큰 → 높음. 눈꼬리 올라간 + 입 작은 → 낮음
- energy: 얼굴 각지고 넓은 + 턱 발달 → 높음. 얼굴 갸름하고 긴 + 턱 뾰족 → 낮음

## 톤 & 매너
- 80% 긍정적 (매력 포인트, 강점 위주)
- 20% 성장 포인트 (부드러운 표현으로)
- 따뜻하고 희망적인 톤, 해요체
- 연애/인간관계 관점 강조
- 사진에서 실제로 관찰한 특징을 구체적으로 언급해서 분석의 신뢰도를 높일 것`;
}

function buildUserPrompt(body: RequestBody): string {
  const { gender, age } = body;

  const demographicText = [
    gender ? `성별: ${gender === "male" ? "남성" : "여성"}` : null,
    age ? `나이: ${age}세` : null,
  ]
    .filter(Boolean)
    .join("\n");

  return `위 얼굴 사진을 관상학적으로 분석해주세요.
${demographicText ? `\n${demographicText}` : ""}

중요: 동물상(animal_type)은 반드시 사진에서 직접 관찰되는 얼굴 형태, 이목구비 비율, 전체 인상만으로 판단하세요. 사주/오행/성격 등 외부 정보와 무관하게, 순수하게 사진의 시각적 특징만으로 닮은 동물을 결정해야 합니다.

사진에서 직접 관찰되는 이목구비의 형태, 비율, 전체 인상을 기반으로 삼정(三停)/오관(五官) 프레임워크에 따라 관상 분석 결과를 JSON으로 응답해주세요.`;
}

// =============================================================================
// 검증
// =============================================================================

function validateRequest(body: RequestBody): string | null {
  if (!body.photoUrl || typeof body.photoUrl !== "string") {
    return "photoUrl is required and must be a string";
  }

  // URL 형식 기본 검증
  try {
    const url = new URL(body.photoUrl);
    // Supabase Storage URL만 허용 (SSRF 방지)
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl) {
      console.error("[gwansang] SUPABASE_URL 환경변수 미설정 — SSRF 검증 불가");
      return "Server configuration error";
    }
    if (!body.photoUrl.startsWith(supabaseUrl)) {
      return "photoUrl must be a Supabase Storage URL";
    }
  } catch {
    return "photoUrl must be a valid URL";
  }

  return null;
}

// =============================================================================
// Claude 응답 파싱
// =============================================================================

function parseClaudeResponse(text: string): GwansangReadingResponse {
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("No JSON object found in Claude response");
  }

  const parsed = JSON.parse(jsonMatch[0]);

  // Required string fields
  for (const field of [
    "animal_type", "animal_type_korean", "animal_modifier", "headline",
    "personality_summary", "romance_summary",
  ]) {
    if (typeof parsed[field] !== "string" || parsed[field].length < 1) {
      throw new Error(`${field} must be a non-empty string`);
    }
  }

  // samjeong validation
  if (!parsed.samjeong?.upper || !parsed.samjeong?.middle || !parsed.samjeong?.lower) {
    throw new Error("samjeong must have upper, middle, lower fields");
  }

  // ogwan validation
  if (!parsed.ogwan?.eyes || !parsed.ogwan?.nose || !parsed.ogwan?.mouth) {
    throw new Error("ogwan must have eyes, nose, mouth fields");
  }

  // traits validation
  for (const trait of ["leadership", "warmth", "independence", "sensitivity", "energy"]) {
    if (typeof parsed.traits?.[trait] !== "number") {
      throw new Error(`traits.${trait} must be a number`);
    }
  }

  // charm_keywords validation
  if (!Array.isArray(parsed.charm_keywords) || parsed.charm_keywords.length < 3) {
    throw new Error("charm_keywords must be an array of at least 3 strings");
  }

  return {
    animal_type: parsed.animal_type.toLowerCase(),
    animal_type_korean: parsed.animal_type_korean,
    animal_modifier: parsed.animal_modifier,
    headline: parsed.headline,
    samjeong: parsed.samjeong,
    ogwan: parsed.ogwan,
    traits: {
      leadership: Math.round(parsed.traits.leadership),
      warmth: Math.round(parsed.traits.warmth),
      independence: Math.round(parsed.traits.independence),
      sensitivity: Math.round(parsed.traits.sensitivity),
      energy: Math.round(parsed.traits.energy),
    },
    personality_summary: parsed.personality_summary,
    romance_summary: parsed.romance_summary,
    romance_key_points: Array.isArray(parsed.romance_key_points)
      ? parsed.romance_key_points.map((k: unknown) => String(k))
      : [],
    charm_keywords: parsed.charm_keywords.map((k: unknown) => String(k)),
    detailed_reading: typeof parsed.detailed_reading === "string"
      ? parsed.detailed_reading
      : null,
  };
}

// =============================================================================
// 메인 핸들러
// =============================================================================

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // 인증 확인 — Authorization 헤더에 Supabase JWT 필수
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "인증이 필요합니다." }),
      {
        status: 401,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // POST만 허용
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // API 키 확인
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({
        error: "Server configuration error: missing API key",
      }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // 요청 바디 파싱
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON in request body" }),
      {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // 입력 검증
  const validationError = validateRequest(body);
  if (validationError) {
    return new Response(
      JSON.stringify({ error: validationError }),
      {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // Claude Vision API 호출 — 이미지 URL + 텍스트 프롬프트
  let claudeResponse: Response;
  try {
    claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 4096,
        system: buildSystemPrompt(),
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "url",
                  url: body.photoUrl,
                },
              },
              {
                type: "text",
                text: buildUserPrompt(body),
              },
            ],
          },
        ],
      }),
    });
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "Failed to connect to Claude API",
        detail: err instanceof Error ? err.message : "Unknown error",
      }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // Claude 응답 상태 확인
  if (!claudeResponse.ok) {
    // 서버 로그에만 원시 에러 기록 (클라이언트 노출 금지)
    try {
      const errorBody = await claudeResponse.text();
      console.error(`[gwansang] Claude API error ${claudeResponse.status}:`, errorBody);
    } catch {
      console.error(`[gwansang] Claude API error: HTTP ${claudeResponse.status}`);
    }
    return new Response(
      JSON.stringify({
        error: "AI 관상 분석에 실패했습니다. 잠시 후 다시 시도해주세요.",
      }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // Claude 응답 파싱
  let claudeData: {
    content: Array<{ type: string; text: string }>;
  };
  try {
    claudeData = await claudeResponse.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Failed to parse Claude API response" }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // 텍스트 블록 추출
  const textBlock = claudeData.content?.find(
    (block: { type: string }) => block.type === "text",
  );
  if (!textBlock || !textBlock.text) {
    return new Response(
      JSON.stringify({ error: "No text content in Claude API response" }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  // 결과 파싱 및 반환
  let result: GwansangReadingResponse;
  try {
    result = parseClaudeResponse(textBlock.text);
  } catch (err) {
    console.error("[gwansang] Parse failed:", err instanceof Error ? err.message : "Unknown", "raw:", textBlock.text);
    return new Response(
      JSON.stringify({
        error: "AI 관상 분석 결과를 처리하지 못했습니다. 다시 시도해주세요.",
      }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
