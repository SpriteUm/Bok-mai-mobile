import 'package:firebase_ai/firebase_ai.dart';
// firebase_ai 2.3.0 ยังไม่ export ThinkingConfig (รุ่นใหม่กว่าต้องอัปเกรด firebase_core ทั้งชุด)
// ignore: implementation_imports
import 'package:firebase_ai/src/api.dart' show ThinkingConfig;

/// เรียก Gemini ผ่าน Firebase AI Logic (Gemini Developer API) ใช้ได้บนแผน Spark ฟรี
/// ไม่ต้องมี Cloud Functions และไม่มี API key ในแอป (Firebase ถือ key ให้)
/// ต้องเปิดก่อนครั้งเดียวที่ Firebase Console > AI Logic > Get started > Gemini Developer API
class AiConfig {
  static const model = 'gemini-3.5-flash';

  /// โควตาฟรีของ [model] มีแค่ ~20 ครั้ง/วัน เมื่อหมดหรือคนใช้เยอะ สลับไปรุ่น lite (โควตาแยกกัน)
  static const fallbackModel = 'gemini-3.5-flash-lite';

  /// ปิดโหมด "คิดก่อนตอบ" ของ [model] งานของแอปไม่ต้องใช้เหตุผลซับซ้อน
  /// เปิดไว้จะคิด ~1,200 token ก่อนตอบ ทำให้รอ ~40 วินาที (ปิดแล้วเหลือ ~7 วินาที)
  /// รุ่น lite ไม่คิดอยู่แล้ว และไม่รับค่านี้ (ตอบ 400)
  static final _noThinking = ThinkingConfig(thinkingBudget: 0);

  static GenerativeModel generativeModel({
    String? responseMimeType,
    Schema? responseSchema,
    Content? systemInstruction,
    bool fallback = false,
  }) =>
      FirebaseAI.googleAI().generativeModel(
        model: fallback ? fallbackModel : model,
        generationConfig: GenerationConfig(
          responseMimeType: responseMimeType,
          responseSchema: responseSchema,
          thinkingConfig: fallback ? null : _noThinking,
        ),
        systemInstruction: systemInstruction,
      );

  /// error ที่ควรลองรุ่นสำรอง: โควตาหมด (429) หรือเซิร์ฟเวอร์คนใช้เยอะ (503)
  static bool shouldFallback(Object e) {
    final msg = e.toString();
    return msg.contains('quota') ||
        msg.contains('RESOURCE_EXHAUSTED') ||
        msg.contains('429') ||
        msg.contains('503') ||
        msg.contains('UNAVAILABLE') ||
        msg.contains('overloaded');
  }
}
