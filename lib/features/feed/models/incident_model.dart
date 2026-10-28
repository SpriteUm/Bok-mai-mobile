enum IncidentStatus {
  pending,
  inProgress,
  resolved,
}

enum IncidentCategory {
  electricity, // ไฟฟ้า
  water, // น้ำประปา
  road, // ถนน / ทางเท้า
  waste, // ขยะ / สิ่งปฏิกูล
  drainage, // ท่อระบายน้ำ
  other, // อื่นๆ
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
  final List<String> imageUrls;
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
      upvoteCount: upvoteCount ?? this.upvoteCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      createdAt: createdAt ?? this.createdAt,
    );
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

