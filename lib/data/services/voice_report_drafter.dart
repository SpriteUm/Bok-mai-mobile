import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/data/services/gemini_report_drafter.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// ฟอร์มรายงานที่ร่างจากเสียงพูด ผู้ใช้ตรวจแก้ได้ก่อนกดส่ง
class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentUrgency urgency;
}

/// ตัวร่างฟอร์มจากข้อความที่ถอดจากเสียง
///
/// ตอนนี้ใช้ [KeywordReportDrafter] เมื่อมี Gemini ให้เขียน class ใหม่ที่
/// implements อินเทอร์เฟซนี้ (เรียกผ่าน Cloud Function) แล้วสลับที่
/// [voiceReportDrafterProvider] จุดเดียว หน้าจอไม่ต้องแก้
abstract class VoiceReportDrafter {
  Future<ReportDraft> draft(String transcript);
}

final voiceReportDrafterProvider =
    Provider<VoiceReportDrafter>((ref) => const GeminiReportDrafter());

/// ร่างฟอร์มแบบไม่ใช้ AI: เดาหมวดและความเร่งด่วนจากคำสำคัญ
class KeywordReportDrafter implements VoiceReportDrafter {
  const KeywordReportDrafter();

  static const _categoryKeywords = <IncidentCategory, List<String>>{
    IncidentCategory.electricity: ['ไฟดับ', 'ไฟฟ้า', 'เสาไฟ', 'สายไฟ', 'หม้อแปลง', 'ไฟส่องสว่าง', 'ไฟถนน'],
    IncidentCategory.water: ['ประปา', 'น้ำท่วม', 'น้ำรั่ว', 'ท่อแตก', 'น้ำไม่ไหล', 'น้ำขัง'],
    IncidentCategory.road: ['ถนน', 'หลุม', 'ทางเท้า', 'สะพาน', 'ฟุตบาท', 'ผิวจราจร'],
    IncidentCategory.waste: ['ขยะ', 'สิ่งปฏิกูล', 'กองขยะ', 'ถังขยะ'],
    IncidentCategory.drainage: ['ท่อระบายน้ำ', 'ท่อตัน', 'ฝาท่อ', 'กลิ่นเหม็น', 'ร่องน้ำ', 'ท่อน้ำทิ้ง'],
  };

  static const _urgentKeywords = ['อันตราย', 'เร่งด่วน', 'ด่วน', 'ไฟช็อต', 'ไฟไหม้', 'ไฟรั่ว', 'บาดเจ็บ', 'ลื่นมาก'];

  @override
  Future<ReportDraft> draft(String transcript) async {
    final text = transcript.trim();
    var category = IncidentCategory.other;
    var best = 0;
    _categoryKeywords.forEach((cat, words) {
      final hits = words.where(text.contains).length;
      if (hits > best) {
        best = hits;
        category = cat;
      }
    });

    final urgent = _urgentKeywords.any(text.contains);

    return ReportDraft(
      title: _titleFrom(text),
      description: text,
      category: category,
      urgency: urgent ? IncidentUrgency.high : IncidentUrgency.medium,
    );
  }

  /// หัวข้อ = ประโยคแรก (ตัดที่ช่องว่าง/จุด) ไม่เกิน 60 ตัวอักษร
  static String _titleFrom(String text) {
    final first = text.split(RegExp(r'[\n.]|\s{2,}')).first.trim();
    return first.length <= 60 ? first : '${first.substring(0, 60)}…';
  }
}
