import 'package:flutter_test/flutter_test.dart';
import 'package:bok_mai_mobile/data/services/voice_report_drafter.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// ตัวร่างสำรองที่ใช้เมื่อเรียก Gemini ไม่ได้ ต้องให้ผลที่ใช้งานได้เสมอ
void main() {
  const drafter = KeywordReportDrafter();

  test('เดาหมวดท่อระบายน้ำ และเร่งด่วนเมื่อมีคำว่าอันตราย', () async {
    // หมายเหตุ: "ฝาท่อแตก" ตรงทั้ง ฝาท่อ (drainage) และ ท่อแตก (water) คะแนนเท่ากันจะได้ water
    final d = await drafter.draft('ฝาท่อระบายน้ำชำรุดหน้าซอย อันตรายมาก');
    expect(d.category, IncidentCategory.drainage);
    expect(d.urgency, IncidentUrgency.high);
  });

  test('เดาหมวดไฟฟ้า ความเร่งด่วนปกติเป็น medium', () async {
    final d = await drafter.draft('ไฟถนนดับทั้งซอย');
    expect(d.category, IncidentCategory.electricity);
    expect(d.urgency, IncidentUrgency.medium);
  });

  test('ไม่ตรงคำไหนเลยเป็นหมวดอื่นๆ และเก็บข้อความเดิมไว้ในรายละเอียด', () async {
    const text = 'มีแมวติดอยู่บนต้นไม้';
    final d = await drafter.draft(text);
    expect(d.category, IncidentCategory.other);
    expect(d.description, text);
    expect(d.title, isNotEmpty);
  });

  test('หัวข้อยาวไม่เกิน 60 ตัวอักษร (+ …)', () async {
    final d = await drafter.draft('ถนน' * 50);
    expect(d.title.length, lessThanOrEqualTo(61));
    expect(d.title.endsWith('…'), isTrue);
  });
}
