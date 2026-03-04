/// 관상(觀相) AI 해석 Edge Function
///
/// 얼굴 측정값 + 사주 데이터를 기반으로 Claude Haiku 4.5를 호출하여
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

interface FaceMeasurements {
  face_shape: string;
  upper_third: number;
  middle_third: number;
  lower_third: number;
  eye_spacing: number;
  eye_slant: number;
  eye_size: number;
  nose_bridge_height: number;
  nose_width: number;
  mouth_width: number;
  lip_thickness: number;
  eyebrow_arch: number;
  eyebrow_thickness: number;
  forehead_height: number;
  jawline_angle: number;
  face_symmetry: number;
  face_length_ratio: number;
}

interface SajuData {
  dominant_element?: string;
  day_stem?: string;
  personality_traits?: string[];
}

interface RequestBody {
  faceMeasurements: FaceMeasurements;
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
- 얼굴 측정값을 기반으로 관상학적 분석을 수행합니다.
- 삼정(三停)과 오관(五官)을 체계적으로 해석합니다.
- 닮은 동물을 자유롭게 선택하고, 관상 특징에서 도출된 수식어를 붙입니다.

## 응답 규칙
반드시 아래 JSON 형식으로만 응답하세요. JSON 외의 텍스트는 절대 포함하지 마세요. 마크다운 코드 블록(\`\`\`json)으로 감싸지 마세요. 순수 JSON만 출력하세요.

{
  "animal_type": "닮은 동물 영어 키 (소문자, 예: cat, dog, fox, dinosaur, camel 등 — 어떤 동물이든 가능)",
  "animal_type_korean": "동물 한글명 (예: 고양이, 강아지, 공룡, 낙타)",
  "animal_modifier": "관상 특징에서 도출된 수식어 (예: 나른한, 배고픈, 졸린, 당당한, 수줍은) — 반드시 얼굴 특징을 반영할 것",
  "headline": "관상학 기반 한줄 헤드라인 (20~40자)",
  "samjeong": {
    "upper": "상정(이마~눈썹) 해석 — 초년운/지적능력 (60~120자)",
    "middle": "중정(눈썹~코끝) 해석 — 중년운/사회성취 (60~120자)",
    "lower": "하정(코끝~턱) 해석 — 말년운/안정감 (60~120자)"
  },
  "ogwan": {
    "eyes": "눈(감찰관) 해석 — 감수성/표현력/연애 스타일 (60~120자)",
    "nose": "코(심판관) 해석 — 자존심/원칙/재물운 (60~120자)",
    "mouth": "입(출납관) 해석 — 소통/식복/대인관계 (60~120자)",
    "ears": "귀(채청관) 해석 — 복덕/경청능력 (40~80자)",
    "eyebrows": "눈썹(보수관) 해석 — 의지력/성격 (40~80자)"
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
- 얼굴 전체 인상에서 가장 닮은 동물을 자유롭게 선택
- 고양이, 강아지, 여우, 사슴, 토끼, 곰, 늑대, 호랑이, 학, 뱀뿐 아니라 공룡, 낙타, 펭귄, 수달, 판다 등 어떤 동물이든 가능
- 수식어(animal_modifier)는 반드시 관상 특징에서 도출: 예) 처진 눈꼬리 → "나른한", 큰 눈 → "초롱초롱한", 각진 턱 → "당당한"

## traits 점수 산출 기준
- leadership: 눈썹 진한/일자 + 턱 각진 → 높음. 눈썹 연한/아치 + 턱 둥근 → 낮음
- warmth: 눈 크고 둥근 + 입술 두꺼운 + 애교살 → 높음. 눈 가늘고 예리한 + 입술 얇은 → 낮음
- independence: 코 높고 반듯 + 이마 넓은 → 높음. 코 낮은 + 이마 좁은 → 낮음
- sensitivity: 눈꼬리 내려간 + 입술 도톰 + 눈 큰 → 높음. 눈꼬리 올라간 + 입 작은 → 낮음
- energy: 얼굴 각진/넓은 + 턱 발달 → 높음. 얼굴 갸름/긴 + 턱 뾰족 → 낮음

## 톤 & 매너
- 80% 긍정적 (매력 포인트, 강점 위주)
- 20% 성장 포인트 (부드러운 표현으로)
- 따뜻하고 희망적인 톤, 해요체
- 연애/인간관계 관점 강조`;
}

function buildUserPrompt(body: RequestBody): string {
  const { faceMeasurements: fm, sajuData, gender, age } = body;

  const measurementsText = `
얼굴 측정값:
- 얼굴형: ${fm.face_shape}
- 삼정 비율 (상/중/하): ${fm.upper_third.toFixed(3)} / ${fm.middle_third.toFixed(3)} / ${fm.lower_third.toFixed(3)}
- 눈 간격: ${fm.eye_spacing.toFixed(3)}
- 눈꼬리 기울기: ${fm.eye_slant.toFixed(3)}
- 눈 크기: ${fm.eye_size.toFixed(3)}
- 코 높이(콧대): ${fm.nose_bridge_height.toFixed(3)}
- 코 너비: ${fm.nose_width.toFixed(3)}
- 입 너비: ${fm.mouth_width.toFixed(3)}
- 입술 두께: ${fm.lip_thickness.toFixed(3)}
- 눈썹 아치: ${fm.eyebrow_arch.toFixed(3)}
- 눈썹 두께: ${fm.eyebrow_thickness.toFixed(3)}
- 이마 높이(상정): ${fm.forehead_height.toFixed(3)}
- 턱 각도: ${fm.jawline_angle.toFixed(3)}
- 좌우 대칭도: ${fm.face_symmetry.toFixed(3)}
- 얼굴 길이 비율: ${fm.face_length_ratio.toFixed(3)}`;

  let sajuText = "사주 데이터: 미제공 (관상 단독 분석)";
  if (sajuData) {
    const parts: string[] = [];
    if (sajuData.dominant_element) parts.push(`주도 오행: ${sajuData.dominant_element}`);
    if (sajuData.day_stem) parts.push(`일간(日干): ${sajuData.day_stem}`);
    if (sajuData.personality_traits?.length) {
      parts.push(`성격 특성: ${sajuData.personality_traits.join(", ")}`);
    }
    if (parts.length > 0) sajuText = `사주 데이터:\n${parts.join("\n")}`;
  }

  const demographicText = [
    gender ? `성별: ${gender === "male" ? "남성" : "여성"}` : null,
    age ? `나이: ${age}세` : null,
  ]
    .filter(Boolean)
    .join("\n");

  return `${measurementsText}

${sajuText}
${demographicText ? `\n${demographicText}` : ""}

위 얼굴 측정값과 사주 데이터를 기반으로 관상 분석 결과를 JSON으로 응답해주세요.`;
}

// =============================================================================
// 검증
// =============================================================================

function validateRequest(body: RequestBody): string | null {
  if (!body.faceMeasurements) {
    return "faceMeasurements is required";
  }

  const fm = body.faceMeasurements;
  const requiredNumericFields: (keyof FaceMeasurements)[] = [
    "upper_third",
    "middle_third",
    "lower_third",
    "eye_spacing",
    "eye_size",
    "nose_width",
    "mouth_width",
    "face_symmetry",
    "face_length_ratio",
  ];

  for (const field of requiredNumericFields) {
    const val = fm[field];
    if (typeof val !== "number" || isNaN(val as number)) {
      return `faceMeasurements.${field} must be a valid number`;
    }
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
    if (typeof parsed[field] !== "string" || parsed[field].length < 2) {
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

  // Claude API 호출
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
        model: "claude-haiku-4-5-20251001",
        max_tokens: 4096,
        system: buildSystemPrompt(),
        messages: [
          {
            role: "user",
            content: buildUserPrompt(body),
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
    let detail = "";
    try {
      const errorBody = await claudeResponse.text();
      detail = errorBody;
    } catch {
      detail = `HTTP ${claudeResponse.status}`;
    }
    return new Response(
      JSON.stringify({
        error: "Claude API returned an error",
        status: claudeResponse.status,
        detail,
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
    return new Response(
      JSON.stringify({
        error: "Failed to parse AI gwansang reading result",
        detail: err instanceof Error ? err.message : "Unknown parse error",
        rawResponse: textBlock.text,
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
