import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// รายการใน Timeline (issues/{id}/updates): หมายเหตุ/feedback ของเจ้าหน้าที่ หรือการ Re-open ของผู้แจ้ง
class IncidentUpdate {
  final String id;
  final String actorId;
  final String actorName;
  final IncidentStatus status;
  final String note;
  final DateTime createdAt;
  final DateTime? editedAt;

  const IncidentUpdate({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.status,
    required this.note,
    required this.createdAt,
    this.editedAt,
  });

  factory IncidentUpdate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return IncidentUpdate(
      id: doc.id,
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      status: IncidentStatus.fromCode(data['status'] as String?),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }
}
