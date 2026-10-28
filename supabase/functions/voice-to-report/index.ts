// TODO: รับไฟล์เสียง → Gemini ถอดเสียง + สรุป { title, description, urgency }
Deno.serve((_req) =>
  new Response(JSON.stringify({ error: "not implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  })
);
