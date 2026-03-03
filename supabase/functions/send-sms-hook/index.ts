// =============================================================================
// Send SMS Hook — Supabase Auth → CoolSMS (한국 010 발신)
// =============================================================================
// Supabase Phone Auth의 Send SMS Hook으로 등록.
// Supabase가 OTP를 생성하면 이 함수가 호출되어 CoolSMS로 실제 SMS를 발송한다.
//
// 설정:
//   - Supabase Dashboard → Auth → Hooks → Send SMS → HTTP → 이 함수 URL
//   - Supabase Secrets: COOLSMS_API_KEY, COOLSMS_API_SECRET, COOLSMS_SENDER
//
// 참고: https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook
// =============================================================================

import { createHmac } from "node:crypto";

// ---------------------------------------------------------------------------
// 환경 변수
// ---------------------------------------------------------------------------
const COOLSMS_API_KEY = Deno.env.get("COOLSMS_API_KEY")!;
const COOLSMS_API_SECRET = Deno.env.get("COOLSMS_API_SECRET")!;
const COOLSMS_SENDER = Deno.env.get("COOLSMS_SENDER")!; // 010-XXXX-XXXX

// ---------------------------------------------------------------------------
// CoolSMS API v4 — 단건 문자 발송
// ---------------------------------------------------------------------------
async function sendViaCoolSMS(to: string, message: string): Promise<void> {
  // CoolSMS API는 국내 형식(0로 시작)을 사용
  const localPhone = to.startsWith("+82")
    ? "0" + to.slice(3)
    : to;

  const now = new Date().toISOString();
  const salt = crypto.randomUUID();
  const signature = createHmac("sha256", COOLSMS_API_SECRET)
    .update(now + salt)
    .digest("hex");

  const res = await fetch("https://api.coolsms.co.kr/messages/v4/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `HMAC-SHA256 apiKey=${COOLSMS_API_KEY}, date=${now}, salt=${salt}, signature=${signature}`,
    },
    body: JSON.stringify({
      message: {
        to: localPhone,
        from: COOLSMS_SENDER.replace(/-/g, ""),
        text: message,
      },
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`CoolSMS 발송 실패: ${res.status} ${body}`);
  }
}

// ---------------------------------------------------------------------------
// Webhook Handler
// ---------------------------------------------------------------------------
Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // Supabase Send SMS Hook payload:
    // { user: { id, phone, ... }, sms: { otp: "123456" } }
    const payload = await req.json();
    const phone: string = payload.user?.phone;
    const otp: string = payload.sms?.otp;

    if (!phone || !otp) {
      return new Response(
        JSON.stringify({ error: "Missing phone or otp" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const message = `[momo] 인증번호: ${otp}\n5분 안에 입력해주세요.`;

    await sendViaCoolSMS(phone, message);

    // Send SMS Hook은 200 + 빈 응답이면 성공
    return new Response("{}", {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("send-sms-hook error:", message);

    // Hook 실패 시 Supabase는 SMS 미발송으로 처리
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
