// อ่านค่าจาก functions/.env (local/emulator) — โปรดักชันแนะนำใช้ `firebase functions:secrets:set GEMINI_API_KEY`
export function geminiConfig(): { apiKey: string; model: string } {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('ยังไม่ได้ตั้ง GEMINI_API_KEY ใน functions/.env');
  }
  return { apiKey, model: process.env.GEMINI_MODEL || 'gemini-flash-latest' };
}
