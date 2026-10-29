import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:bok_mai_mobile/core/constants/ai_config.dart';
import 'package:bok_mai_mobile/data/services/voice_report_drafter.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// ร่างฟอร์มด้วย Gemini ผ่าน Firebase AI Logic (ฟรีบนแผน Spark)
/// ถ้าเรียกไม่สำเร็จ (ออฟไลน์/ยังไม่เปิด AI Logic/โควตาเต็ม) ใช้ [fallback] แทน
class GeminiReportDrafter implements VoiceReportDrafter {
  const GeminiReportDrafter({this.fallback = const KeywordReportDrafter()});

  final VoiceReportDrafter fallback;

  static final _categories = IncidentCategory.values.map((c) => c.code).toList();
  static final _urgencies = IncidentUrgency.values.map((u) => u.code).toList();

  static final _schema = Schema.object(
    properties: {
      'title': Schema.string(),
      'description': Schema.string(),
      'category': Schema.enumString(enumValues: _categories),
      'categoryNote': Schema.string(),
      'urgency': Schema.enumString(enumValues: _urgencies),
    },
    optionalProperties: ['categoryNote'],
  );

  /// ลองรุ่นหลักก่อน ถ้าโควตาหมด (429) หรือคนใช้เยอะ (503) สลับไปรุ่นสำรอง ก่อนถอยไปใช้คำสำคัญ
  static Future<GenerateContentResponse> _generate(String prompt) async {
    for (final fallback in [false, true]) {
      try {
        return await AiConfig.generativeModel(
          responseMimeType: 'application/json',
          responseSchema: _schema,
          fallback: fallback,
        ).generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
      } catch (e) {
        if (fallback || !AiConfig.shouldFallback(e)) rethrow;
        debugPrint('Gemini รุ่นหลักใช้ไม่ได้ (${AiConfig.model}) สลับไปรุ่นสำรอง: $e');
      }
    }
    throw StateError('unreachable');
  }

  @override
  Future<ReportDraft> draft(String transcript) async {
    final text = transcript.trim();
    final input = text.length > 2000 ? text.substring(0, 2000) : text;
    try {
      final prompt = 'คุณคือผู้ช่วยร่างแบบฟอร์มแจ้งปัญหาสาธารณะของเมืองในประเทศไทย '
          'จากคำพูดของผู้ใช้ต่อไปนี้ ให้ร่างแบบฟอร์มเป็นภาษาไทย '
          'title คือหัวข้อสั้นไม่เกิน 60 ตัวอักษร, '
          'description คือรายละเอียดที่เรียบเรียงใหม่ให้อ่านง่าย โดยไม่เพิ่มข้อเท็จจริงที่ผู้ใช้ไม่ได้พูด, '
          'category เลือกจาก ${_categories.join('|')} '
          '(electric=ไฟฟ้า, water=ประปา/น้ำท่วม, road=ถนน/ทางเท้า, waste=ขยะ, drainage=ท่อระบายน้ำ, other=อื่นๆ), '
          'ถ้า category เป็น other ให้ใส่ categoryNote เป็นชื่อหมวดสั้นๆ เช่น ต้นไม้ล้ม, '
          'urgency เลือก high เมื่อมีอันตรายต่อชีวิตหรือกระทบการสัญจรรุนแรง, low เมื่อไม่กระทบใคร, นอกนั้น medium\n\n'
          'คำพูดผู้ใช้: """$input"""';

      final response = await _generate(prompt);
      final out = jsonDecode(response.text ?? '') as Map<String, dynamic>;
      final title = (out['title'] as String? ?? '').trim();
      return ReportDraft(
        title: title.length > 80 ? title.substring(0, 80) : title,
        description: (out['description'] as String?)?.trim().isNotEmpty == true
            ? (out['description'] as String).trim()
            : text,
        category: IncidentCategory.fromCode(out['category'] as String?),
        categoryNote: out['categoryNote'] as String? ?? '',
        urgency: IncidentUrgency.fromCode(out['urgency'] as String?),
        aiDrafted: true,
      );
    } catch (e) {
      debugPrint('Gemini ร่างฟอร์มไม่สำเร็จ ใช้คำสำคัญแทน: $e');
      return fallback.draft(transcript);
    }
  }
}
