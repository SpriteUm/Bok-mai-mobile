import 'package:flutter_test/flutter_test.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

void main() {
  group('IncidentModel.splitImages', () {
    test('แยกรูปผู้แจ้งกับรูปหลังแก้ไขตาม kind', () {
      final (report, resolution) = IncidentModel.splitImages([
        {'url': 'a.jpg', 'kind': 'report'},
        {'url': 'after.jpg', 'kind': 'resolution'},
        {'url': 'b.jpg', 'kind': 'report'},
      ]);
      expect(report, ['a.jpg', 'b.jpg']);
      expect(resolution, ['after.jpg']);
    });

    test('รูปที่ไม่มี kind นับเป็นรูปผู้แจ้ง', () {
      final (report, resolution) = IncidentModel.splitImages([
        {'url': 'old.jpg'},
      ]);
      expect(report, ['old.jpg']);
      expect(resolution, isEmpty);
    });

    test('ข้ามรายการที่ไม่มี url หรือไม่ใช่ Map และรับ null ได้', () {
      final (report, resolution) = IncidentModel.splitImages([
        {'kind': 'report'},
        'not-a-map',
        {'url': 42},
      ]);
      expect(report, isEmpty);
      expect(resolution, isEmpty);
      final (nullReport, nullResolution) = IncidentModel.splitImages(null);
      expect(nullReport, isEmpty);
      expect(nullResolution, isEmpty);
    });

    test('มีแต่รูปหลังแก้ไข รูปปกต้องว่าง (ไม่ใช้รูปของแอดมินเป็นปก)', () {
      final (report, resolution) = IncidentModel.splitImages([
        {'url': 'after.jpg', 'kind': 'resolution'},
      ]);
      expect(report, isEmpty);
      expect(resolution, ['after.jpg']);
    });
  });

  group('enum codes ตรงกับ Firestore', () {
    test('status แปลงไป-กลับได้ และค่าที่ไม่รู้จักเป็น pending', () {
      for (final s in IncidentStatus.values) {
        expect(IncidentStatus.fromCode(s.code), s);
      }
      expect(IncidentStatus.inProgress.code, 'in_progress');
      expect(IncidentStatus.fromCode('???'), IncidentStatus.pending);
    });

    test('category ใช้รหัสตาม seed/categories.json', () {
      expect(IncidentCategory.electricity.code, 'electric');
      for (final c in IncidentCategory.values) {
        expect(IncidentCategory.fromCode(c.code), c);
      }
      expect(IncidentCategory.fromCode(null), IncidentCategory.other);
    });

    test('urgency ค่าเริ่มต้นเป็น medium', () {
      expect(IncidentUrgency.fromCode('high'), IncidentUrgency.high);
      expect(IncidentUrgency.fromCode(null), IncidentUrgency.medium);
    });
  });

  test('copyWith คงค่าเดิมและเปลี่ยนเฉพาะที่ส่งมา', () {
    final base = IncidentModel(
      id: '1',
      title: 'ฝาท่อแตก',
      description: 'd',
      category: IncidentCategory.drainage,
      status: IncidentStatus.pending,
      locationAddress: 'a',
      latitude: 13.7,
      longitude: 100.7,
      imageUrls: const ['a.jpg'],
      resolutionImageUrls: const ['after.jpg'],
      upvoteCount: 1,
      createdAt: DateTime(2026),
    );
    final edited = base.copyWith(title: 'แก้แล้ว', urgency: IncidentUrgency.high);
    expect(edited.title, 'แก้แล้ว');
    expect(edited.urgency, IncidentUrgency.high);
    expect(edited.imageUrls, ['a.jpg']);
    expect(edited.resolutionImageUrls, ['after.jpg']);
    expect(edited.category, IncidentCategory.drainage);
  });
}
