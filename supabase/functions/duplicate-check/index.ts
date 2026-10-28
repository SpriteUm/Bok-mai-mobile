// TODO: กรองด้วย ST_DWithin(location, point, 50) + หมวดเดียวกัน + ยังไม่ resolved
// แล้วส่งรูปคู่ใกล้เคียงให้ Gemini เทียบ (GEMINI_API_KEY ตั้งด้วย `supabase secrets set`)
Deno.serve((_req) =>
  new Response(JSON.stringify({ error: "not implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  })
);
