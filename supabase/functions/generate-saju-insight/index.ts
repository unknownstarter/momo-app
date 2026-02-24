const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface Pillar {
  heavenlyStem: string;
  earthlyBranch: string;
  hanja: string;
}

interface FiveElements {
  wood: number;
  fire: number;
  earth: number;
  metal: number;
  water: number;
}

interface SajuResult {
  yearPillar: Pillar;
  monthPillar: Pillar;
  dayPillar: Pillar;
  hourPillar: Pillar | null;
  fiveElements: FiveElements;
  dominantElement: string;
}

interface RequestBody {
  sajuResult: SajuResult;
  userName: string;
}

interface SajuInsightResponse {
  personalityTraits: string[];
  interpretation: string;
  characterName: string;
  characterElement: string;
  characterGreeting: string;
}

const CHARACTER_MAP: Record<
  string,
  { name: string; animal: string; traits: string }
> = {
  wood: {
    name: "나무리",
    animal: "곰",
    traits: "따뜻하고 성장 지향적인",
  },
  fire: {
    name: "불꼬리",
    animal: "여우",
    traits: "열정적이고 에너지 넘치는",
  },
  earth: {
    name: "흙순이",
    animal: "두더지",
    traits: "믿음직하고 안정적인",
  },
  metal: {
    name: "쇠동이",
    animal: "토끼",
    traits: "날카롭고 결단력 있는",
  },
  water: {
    name: "물결이",
    animal: "물개",
    traits: "지혜롭고 유연한",
  },
};

function buildSystemPrompt(): string {
  return `당신은 한국 전통 사주팔자(四柱八字) 전문가이자, 따뜻하고 희망적인 운명 해석가입니다.
사용자의 사주 정보를 받아 성격 분석과 운명 해석을 제공합니다.

반드시 아래 JSON 형식으로만 응답하세요. JSON 외의 텍스트는 절대 포함하지 마세요.

{
  "personalityTraits": ["키워드1", "키워드2", "키워드3", "키워드4", "키워드5"],
  "interpretation": "해석 텍스트 (200~300자)",
  "characterGreeting": "캐릭터 인사말 (1문장)"
}

규칙:
1. personalityTraits: 정확히 5개의 한국어 성격 키워드. 긍정적이고 매력적인 표현으로. 예: "따뜻한", "성장형", "공감력 높은"
2. interpretation: 200자 이상 300자 이하. 따뜻하고 희망적인 톤. 연애/운명의 관점에서 해석. 사주의 오행 구성과 일주를 반영. 사용자 이름을 자연스럽게 포함.
3. characterGreeting: 배정된 오행 캐릭터가 사용자에게 하는 인사말 1문장. 반말로, 친근하고 귀엽게.`;
}

function buildUserPrompt(sajuResult: SajuResult, userName: string): string {
  const character = CHARACTER_MAP[sajuResult.dominantElement] ?? CHARACTER_MAP["earth"];

  const pillarsText = [
    `년주(年柱): ${sajuResult.yearPillar.heavenlyStem}${sajuResult.yearPillar.earthlyBranch} (${sajuResult.yearPillar.hanja})`,
    `월주(月柱): ${sajuResult.monthPillar.heavenlyStem}${sajuResult.monthPillar.earthlyBranch} (${sajuResult.monthPillar.hanja})`,
    `일주(日柱): ${sajuResult.dayPillar.heavenlyStem}${sajuResult.dayPillar.earthlyBranch} (${sajuResult.dayPillar.hanja})`,
    sajuResult.hourPillar
      ? `시주(時柱): ${sajuResult.hourPillar.heavenlyStem}${sajuResult.hourPillar.earthlyBranch} (${sajuResult.hourPillar.hanja})`
      : "시주(時柱): 미입력",
  ].join("\n");

  const elementsText = `목(木): ${sajuResult.fiveElements.wood}, 화(火): ${sajuResult.fiveElements.fire}, 토(土): ${sajuResult.fiveElements.earth}, 금(金): ${sajuResult.fiveElements.metal}, 수(水): ${sajuResult.fiveElements.water}`;

  return `사용자 이름: ${userName}

사주팔자:
${pillarsText}

오행 분포: ${elementsText}
주도 오행: ${sajuResult.dominantElement}

배정된 캐릭터: ${character.name} (${character.animal}, ${character.traits})

위 사주를 분석하여 JSON으로 응답해주세요.
characterGreeting은 "${character.name}"가 "${userName}"에게 하는 인사말입니다.`;
}

function validateRequest(body: RequestBody): string | null {
  if (!body.sajuResult) {
    return "sajuResult is required";
  }
  if (!body.userName || typeof body.userName !== "string") {
    return "userName is required and must be a string";
  }
  const { sajuResult } = body;
  if (!sajuResult.yearPillar || !sajuResult.monthPillar || !sajuResult.dayPillar) {
    return "yearPillar, monthPillar, and dayPillar are required";
  }
  if (!sajuResult.fiveElements) {
    return "fiveElements is required";
  }
  if (!sajuResult.dominantElement) {
    return "dominantElement is required";
  }
  return null;
}

function parseClaudeResponse(
  text: string,
  dominantElement: string,
  userName: string
): SajuInsightResponse {
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("No JSON object found in Claude response");
  }

  const parsed = JSON.parse(jsonMatch[0]);

  if (
    !Array.isArray(parsed.personalityTraits) ||
    parsed.personalityTraits.length !== 5
  ) {
    throw new Error("personalityTraits must be an array of exactly 5 strings");
  }
  if (
    typeof parsed.interpretation !== "string" ||
    parsed.interpretation.length < 100
  ) {
    throw new Error(
      "interpretation must be a string with at least 100 characters"
    );
  }
  if (typeof parsed.characterGreeting !== "string") {
    throw new Error("characterGreeting must be a string");
  }

  const character = CHARACTER_MAP[dominantElement] ?? CHARACTER_MAP["earth"];
  const element = dominantElement in CHARACTER_MAP ? dominantElement : "earth";

  return {
    personalityTraits: parsed.personalityTraits.map((t: unknown) => String(t)),
    interpretation: parsed.interpretation,
    characterName: character.name,
    characterElement: element,
    characterGreeting: parsed.characterGreeting,
  };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Server configuration error: missing API key" }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON in request body" }),
      {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  const validationError = validateRequest(body);
  if (validationError) {
    return new Response(
      JSON.stringify({ error: validationError }),
      {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  const { sajuResult, userName } = body;

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
        max_tokens: 1024,
        system: buildSystemPrompt(),
        messages: [
          {
            role: "user",
            content: buildUserPrompt(sajuResult, userName),
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
      }
    );
  }

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
      }
    );
  }

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
      }
    );
  }

  const textBlock = claudeData.content?.find(
    (block: { type: string }) => block.type === "text"
  );
  if (!textBlock || !textBlock.text) {
    return new Response(
      JSON.stringify({ error: "No text content in Claude API response" }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  let result: SajuInsightResponse;
  try {
    result = parseClaudeResponse(
      textBlock.text,
      sajuResult.dominantElement,
      userName
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "Failed to parse AI interpretation result",
        detail: err instanceof Error ? err.message : "Unknown parse error",
        rawResponse: textBlock.text,
      }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
