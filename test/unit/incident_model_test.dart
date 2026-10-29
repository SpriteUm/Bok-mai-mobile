import 'package:flutter_test/flutter_test.dart';
import 'package:bok_mai_mobile/core/utils/geohash.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

void main() {
  group('Unit Tests: Incident Model & Enums', () {
    test('IncidentStatus converts to and from code correctly', () {
      expect(IncidentStatus.pending.code, 'pending');
      expect(IncidentStatus.inProgress.code, 'in_progress');
      expect(IncidentStatus.resolved.code, 'resolved');

      expect(IncidentStatus.fromCode('pending'), IncidentStatus.pending);
      expect(IncidentStatus.fromCode('in_progress'), IncidentStatus.inProgress);
      expect(IncidentStatus.fromCode('resolved'), IncidentStatus.resolved);
      expect(IncidentStatus.fromCode('unknown'), IncidentStatus.pending);
    });

    test('IncidentCategory code mappings are accurate', () {
      expect(IncidentCategory.electricity.code, 'electric');
      expect(IncidentCategory.water.code, 'water');
      expect(IncidentCategory.road.code, 'road');
      expect(IncidentCategory.waste.code, 'waste');
      expect(IncidentCategory.drainage.code, 'drainage');
      expect(IncidentCategory.other.code, 'other');

      expect(IncidentCategory.fromCode('electric'), IncidentCategory.electricity);
      expect(IncidentCategory.fromCode('invalid'), IncidentCategory.other);
    });

    test('IncidentModel copyWith updates fields correctly', () {
      final now = DateTime.now();
      final incident = IncidentModel(
        id: 'inc-1',
        title: 'สายไฟขาด',
        description: 'บริเวณหน้าตึก',
        category: IncidentCategory.electricity,
        status: IncidentStatus.pending,
        locationAddress: 'ลาดกระบัง',
        latitude: 13.7299,
        longitude: 100.7782,
        imageUrls: ['https://example.com/img1.jpg'],
        upvoteCount: 5,
        hasUpvoted: false,
        createdAt: now,
      );

      final updated = incident.copyWith(
        status: IncidentStatus.inProgress,
        upvoteCount: 6,
        hasUpvoted: true,
      );

      expect(updated.id, 'inc-1');
      expect(updated.status, IncidentStatus.inProgress);
      expect(updated.upvoteCount, 6);
      expect(updated.hasUpvoted, true);
      expect(updated.title, 'สายไฟขาด');
      expect(updated.categoryLabel, 'ไฟฟ้า');
    });

    test('categoryNote ใช้เฉพาะหมวดอื่นๆ และถูกล้างเมื่อเปลี่ยนหมวด', () {
      final other = IncidentModel(
        id: 'inc-2',
        title: 'ต้นไม้ล้มขวางทาง',
        description: '',
        category: IncidentCategory.other,
        categoryNote: ' ต้นไม้ล้ม ',
        status: IncidentStatus.pending,
        locationAddress: '',
        latitude: 13.7299,
        longitude: 100.7782,
        imageUrls: const [],
        upvoteCount: 1,
        createdAt: DateTime(2026),
      );

      expect(other.categoryLabel, 'อื่นๆ: ต้นไม้ล้ม');
      expect(other.toFeedMap(geohash: 'w4rq')['categoryNote'], 'ต้นไม้ล้ม');

      // ยังไม่มีลำดับจากเจ้าหน้าที่ ใช้ผลคัดกรองไปก่อน กำหนดแล้วใช้ของเจ้าหน้าที่
      expect(other.copyWith(urgency: IncidentUrgency.high).effectivePriority, IncidentUrgency.high);
      expect(
        other.copyWith(urgency: IncidentUrgency.high, priority: IncidentUrgency.low).effectivePriority,
        IncidentUrgency.low,
      );

      final road = other.copyWith(category: IncidentCategory.road);
      expect(road.categoryLabel, 'ถนน / ทางเท้า');
      expect(road.effectiveCategoryNote, isEmpty);
    });
  });

  group('Unit Tests: Geohash Utilities', () {
    test('encodeGeohash produces valid geohash for coordinates', () {
      final hash = encodeGeohash(13.7299, 100.7782, precision: 7);
      expect(hash, isNotEmpty);
      expect(hash.length, 7);
    });
  });
}
