import 'dart:typed_data';

import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// รายงานที่รอส่ง (ส่งไม่ได้ตอนไม่มีเน็ต) เก็บครบทั้งเรื่องและรูป แล้วส่งเองเมื่อมีเน็ต
class OutboxItem {
  OutboxItem({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.report,
    required this.images,
    List<String>? uploadedUrls,
  }) : uploadedUrls = uploadedUrls ?? [];

  /// id ของเรื่องใน Firestore (สร้างไว้ตั้งแต่เข้ากล่อง ส่งซ้ำกี่ครั้งก็ได้เรื่องเดียว)
  final String id;

  /// ผู้แจ้ง: ส่งได้เฉพาะตอนผู้ใช้คนนี้ล็อกอินอยู่
  final String uid;
  final DateTime createdAt;

  /// ข้อมูลรายงาน (ยังไม่มีลิงก์รูป)
  final IncidentModel report;

  /// รูปที่จะอัปโหลด (เป็นรูปที่เบลอใบหน้าแล้ว ถ้าเปิดเบลอไว้)
  final List<Uint8List> images;

  /// ลิงก์รูปที่อัปโหลดสำเร็จแล้ว (ส่งซ้ำจะไม่อัปโหลดรูปเดิมอีก)
  final List<String> uploadedUrls;

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'createdAt': createdAt.toIso8601String(),
    'imageCount': images.length,
    'uploadedUrls': uploadedUrls,
    'title': report.title,
    'description': report.description,
    'category': report.category.code,
    'categoryNote': report.categoryNote,
    'urgency': report.urgency.code,
    'address': report.locationAddress,
    'lat': report.latitude,
    'lng': report.longitude,
  };

  static OutboxItem fromJson(Map<String, dynamic> j, List<Uint8List> images) {
    final createdAt = DateTime.parse(j['createdAt'] as String);
    return OutboxItem(
      id: j['id'] as String,
      uid: j['uid'] as String,
      createdAt: createdAt,
      images: images,
      uploadedUrls: (j['uploadedUrls'] as List?)?.cast<String>().toList(),
      report: IncidentModel(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        category: IncidentCategory.fromCode(j['category'] as String?),
        categoryNote: j['categoryNote'] as String? ?? '',
        status: IncidentStatus.pending,
        urgency: IncidentUrgency.fromCode(j['urgency'] as String?),
        locationAddress: j['address'] as String? ?? '',
        latitude: (j['lat'] as num).toDouble(),
        longitude: (j['lng'] as num).toDouble(),
        imageUrls: const [],
        upvoteCount: 1,
        createdAt: createdAt,
      ),
    );
  }
}
