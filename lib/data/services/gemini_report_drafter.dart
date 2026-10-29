import 'package:cloud_functions/cloud_functions.dart';
import 'package:bok_mai_mobile/core/firebase/firebase_bootstrap.dart';
import 'package:bok_mai_mobile/data/services/voice_report_drafter.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// ร่างฟอร์มด้วย Gemini ผ่าน Cloud Function `draftReport` (key อยู่ใน functions/.env ฝั่งเซิร์ฟเวอร์)
/// ถ้าเรียกไม่สำเร็จ (ออฟไลน์/ไม่ได้เปิด emulator/ยังไม่ล็อกอิน) ใช้ [fallback] แทน
class GeminiReportDrafter implements VoiceReportDrafter {
  const GeminiReportDrafter({this.fallback = const KeywordReportDrafter()});

  final VoiceReportDrafter fallback;

  @override
  Future<ReportDraft> draft(String transcript) async {
    try {
      final result = await FirebaseFunctions.instanceFor(region: functionsRegion)
          .httpsCallable('draftReport', options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
          .call<Map<Object?, Object?>>({'transcript': transcript});
      final data = result.data;
      return ReportDraft(
        title: data['title'] as String,
        description: data['description'] as String,
        category: IncidentCategory.fromCode(data['category'] as String?),
        urgency: IncidentUrgency.fromCode(data['urgency'] as String?),
      );
    } catch (_) {
      return fallback.draft(transcript);
    }
  }
}
