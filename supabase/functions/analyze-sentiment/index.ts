// TODO: Gemini ตอบ JSON { sentiment, is_urgent, reason } แล้วอัปเดตตาราง feedback
// และแจ้งเตือนผู้บริหารเมื่อ is_urgent = true
Deno.serve((_req) =>
  new Response(JSON.stringify({ error: "not implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  })
);
