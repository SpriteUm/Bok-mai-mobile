import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentStatus {
  pending,
  inProgress,
  resolved;

  /// ค่าที่เก็บใน Firestore
  String get code => switch (this) {
        pending => 'pending',
        inProgress => 'in_progress',
        resolved => 'resolved',
      };

  static IncidentStatus fromCode(String? code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => pending,
      );
}

enum IncidentUrgency {
  low,
  medium,
  high;

  String get code => name;

  static IncidentUrgency fromCode(String? code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => medium,
      );
}

enum IncidentCategory {
  electricity, // ไฟฟ้า
  water, // น้ำประปา
  road, // ถนน / ทางเท้า
  waste, // ขยะ / สิ่งปฏิกูล
  drainage, // ท่อระบายน้ำ
  other; // อื่นๆ

  /// ค่าที่เก็บใน Firestore (ตรงกับ seed/categories.json)
  String get code => switch (this) {
        electricity => 'electric',
        water => 'water',
        road => 'road',
        waste => 'waste',
        drainage => 'drainage',
        other => 'other',
      };

  static IncidentCategory fromCode(String? code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => other,
      );
}

class IncidentModel {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;
  final String locationAddress;
  final double latitude;
  final double longitude;
  /// รูปที่ผู้แจ้งแนบ (ใช้เป็นรูปปก)
  final List<String> imageUrls;

  /// รูปหลังแก้ไข (After) ที่เจ้าหน้าที่ส่งกลับมา แสดงแยกเป็น feedback
  final List<String> resolutionImageUrls;
  final IncidentUrgency urgency;
  final int upvoteCount;
  final bool hasUpvoted;
  final DateTime createdAt;

  const IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    this.resolutionImageUrls = const [],
    this.urgency = IncidentUrgency.medium,
    required this.upvoteCount,
    this.hasUpvoted = false,
    required this.createdAt,
  });

  IncidentModel copyWith({
    String? id,
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentStatus? status,
    String? locationAddress,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    List<String>? resolutionImageUrls,
    IncidentUrgency? urgency,
    int? upvoteCount,
    bool? hasUpvoted,
    DateTime? createdAt,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      resolutionImageUrls: resolutionImageUrls ?? this.resolutionImageUrls,
      urgency: urgency ?? this.urgency,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// สร้างจากเอกสารใน `issues_feed` (หรือ `issues`)
  /// รูปเก็บเป็นลิงก์ใน `images: [{url, kind}]` แยกรูปผู้แจ้ง (report) กับรูปหลังแก้ไข (resolution)
  factory IncidentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool hasUpvoted = false,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    final location = data['location'] as GeoPoint?;
    final (imageUrls, resolutionImageUrls) = splitImages(data['images'] as List?);
    return IncidentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: IncidentCategory.fromCode(data['categoryCode'] as String?),
      status: IncidentStatus.fromCode(data['status'] as String?),
      urgency: IncidentUrgency.fromCode(data['urgency'] as String?),
      locationAddress: data['addressText'] as String? ?? '',
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
      imageUrls: imageUrls,
      resolutionImageUrls: resolutionImageUrls,
      upvoteCount: (data['reportCount'] as num?)?.toInt() ?? 1,
      hasUpvoted: hasUpvoted,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// แยก `images: [{url, kind}]` เป็น (รูปผู้แจ้ง, รูปหลังแก้ไข) ข้ามรายการที่ไม่มี url
  static (List<String>, List<String>) splitImages(List? images) {
    final report = <String>[];
    final resolution = <String>[];
    for (final e in images ?? const []) {
      if (e is! Map || e['url'] is! String) continue;
      (e['kind'] == 'resolution' ? resolution : report).add(e['url'] as String);
    }
    return (report, resolution);
  }

  /// ข้อมูลสำหรับสร้างเรื่องใหม่ใน `issues` ให้ตรงกับ firestore.rules
  /// [geohash] คำนวณจากพิกัดโดยผู้เรียก, [imageUrls] เป็นลิงก์รูปที่อัปโหลดไว้แล้ว
  Map<String, dynamic> toNewIssueMap({
    required String reporterId,
    required String geohash,
  }) {
    return {
      'reporterId': reporterId,
      ...toFeedMap(geohash: geohash),
    };
  }

  /// สำเนาสาธารณะสำหรับ `issues_feed` (ไม่มี reporterId)
  Map<String, dynamic> toFeedMap({required String geohash}) {
    return {
      'categoryCode': category.code,
      'title': title,
      'description': description,
      'urgency': urgency.code,
      'status': IncidentStatus.pending.code,
      'location': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'addressText': locationAddress,
      'reportCount': 1,
      'images': [
        for (final url in imageUrls) {'url': url, 'kind': 'report'},
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get categoryLabel {
    switch (category) {
      case IncidentCategory.electricity:
        return 'ไฟฟ้า';
      case IncidentCategory.water:
        return 'น้ำประปา';
      case IncidentCategory.road:
        return 'ถนน / ทางเท้า';
      case IncidentCategory.waste:
        return 'ขยะมูลฝอย';
      case IncidentCategory.drainage:
        return 'ท่อระบายน้ำ';
      case IncidentCategory.other:
        return 'อื่นๆ';
    }
  }
}

