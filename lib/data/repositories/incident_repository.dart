import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bok_mai_mobile/core/utils/geohash.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

/// อ่าน/เขียน Firestore (โหมดไม่ใช้ Cloud Functions: เขียน issues + issues_feed พร้อมกันใน batch)
/// ความถูกต้องของข้อมูลบังคับที่ firestore.rules
class IncidentRepository {
  IncidentRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _issues => _db.collection('issues');
  CollectionReference<Map<String, dynamic>> get _feed => _db.collection('issues_feed');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('ต้องเข้าสู่ระบบก่อน');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _follower(String issueId) =>
      _feed.doc(issueId).collection('followers').doc(_uid);

  /// Feed / แผนที่ (สำเนาสาธารณะ ไม่มี reporterId)
  Stream<List<IncidentModel>> watchFeed({int limit = 100}) {
    return _feed
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(IncidentModel.fromFirestore).toList());
  }

  /// ประวัติของฉัน (ข้อมูลเต็มจาก issues)
  Stream<List<IncidentModel>> watchMine({int limit = 100}) {
    return _issues
        .where('reporterId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(IncidentModel.fromFirestore).toList());
  }

  Future<bool> isFollowing(String issueId) async =>
      (await _follower(issueId).get()).exists;

  /// สร้างเรื่องใหม่ คืน id ของเรื่อง
  Future<String> createIssue(IncidentModel draft) async {
    final uid = _uid;
    final ref = _issues.doc();
    final geohash = encodeGeohash(draft.latitude, draft.longitude);

    final batch = _db.batch()
      ..set(ref, draft.toNewIssueMap(reporterId: uid, geohash: geohash))
      ..set(_feed.doc(ref.id), draft.toFeedMap(geohash: geohash));
    await batch.commit();
    return ref.id;
  }

  /// กด +1 (เจ้าของเรื่องกดเองไม่ได้ ตาม rules)
  Future<void> follow(String issueId) {
    final batch = _db.batch()
      ..update(_feed.doc(issueId), {
        'reportCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_follower(issueId), {'createdAt': FieldValue.serverTimestamp()});
    return batch.commit();
  }

  Future<void> unfollow(String issueId) {
    final batch = _db.batch()
      ..update(_feed.doc(issueId), {
        'reportCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..delete(_follower(issueId));
    return batch.commit();
  }

  /// admin เปลี่ยนสถานะ + หมายเหตุลง Timeline (ต้องมี Custom Claim admin)
  Future<void> adminUpdateStatus({
    required String issueId,
    required IncidentStatus status,
    String note = '',
  }) {
    final patch = {
      'status': status.code,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _db.batch()
      ..update(_issues.doc(issueId), patch)
      ..update(_feed.doc(issueId), patch)
      ..set(_issues.doc(issueId).collection('updates').doc(), {
        'actorId': _uid,
        'status': status.code,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }
}
