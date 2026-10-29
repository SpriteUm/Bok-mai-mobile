import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bok_mai_mobile/core/utils/geohash.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_update_model.dart';

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

  /// id ใหม่สำหรับเรื่องที่จะสร้าง (สร้างในเครื่อง ไม่ต้องต่อเน็ต) ใช้กับกล่องรอส่ง
  String newIssueId() => _issues.doc().id;

  /// มีเรื่องนี้ในระบบแล้วหรือยัง (ใช้ตอนส่งซ้ำจากกล่องรอส่ง กันส่งเบิ้ล)
  Future<bool> issueExists(String id) async =>
      (await _issues.doc(id).get(const GetOptions(source: Source.server))).exists;

  /// สร้างเรื่องใหม่ คืน id ของเรื่อง ([id] กำหนดเองได้ เพื่อให้ส่งซ้ำแล้วไม่เกิดเรื่องซ้ำ)
  Future<String> createIssue(IncidentModel draft, {String? id}) async {
    final uid = _uid;
    final ref = _issues.doc(id);
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

  /// แก้ไขเนื้อหารายงานของตัวเอง (issues + issues_feed) rules อนุญาตเฉพาะเรื่องที่ยัง pending และไม่มีคนกด +1 ร่วม
  Future<void> updateIssue(IncidentModel edited) {
    final patch = <String, dynamic>{
      'categoryCode': edited.category.code,
      'categoryNote': edited.effectiveCategoryNote,
      'title': edited.title,
      'description': edited.description,
      'urgency': edited.urgency.code,
      'addressText': edited.locationAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _db.batch()
      ..update(_issues.doc(edited.id), patch)
      ..update(_feed.doc(edited.id), patch);
    return batch.commit();
  }

  /// ลบเรื่องของตัวเอง (ทั้ง issues และสำเนาใน issues_feed) rules อนุญาตเฉพาะเรื่องที่ไม่มีคนกด +1 ร่วม
  Future<void> deleteIssues(Iterable<String> issueIds) async {
    // 1 เรื่อง = 2 การลบ, batch จำกัด 500 รายการ
    final ids = issueIds.toList();
    for (var i = 0; i < ids.length; i += 200) {
      final chunk = ids.skip(i).take(200).toList();
      // ตัวนับ +1 อยู่ที่สำเนาใน issues_feed จึงต้องเช็กจากที่นั่น (issues.reportCount ไม่ถูกเพิ่ม)
      final feedDocs = await Future.wait(chunk.map((id) => _feed.doc(id).get()));
      final inFeed = <String>{};
      for (final doc in feedDocs) {
        if (!doc.exists) continue; // รายงานเก่าที่ไม่มีสำเนา: ลบเฉพาะเรื่องหลัก
        if (((doc.data()?['reportCount'] as num?)?.toInt() ?? 1) > 1) {
          throw StateError('ลบไม่ได้ เพราะมีคนกด +1 ร่วมกับเรื่อง "${doc.data()?['title'] ?? ''}" แล้ว');
        }
        inFeed.add(doc.id);
      }

      final batch = _db.batch();
      for (final id in chunk) {
        batch.delete(_issues.doc(id));
        if (inFeed.contains(id)) batch.delete(_feed.doc(id));
      }
      await batch.commit();
    }
  }

  /// admin เปลี่ยนสถานะ + หมายเหตุลง Timeline (ต้องมี Custom Claim admin)
  Future<void> adminUpdateStatus({
    required String issueId,
    required IncidentStatus status,
    String note = '',
    List<String> resolutionImageUrls = const [],
  }) async {
    final actorName = await _actorName();
    final patch = <String, dynamic>{
      'status': status.code,
      'updatedAt': FieldValue.serverTimestamp(),
      // รูปหลังแก้ไข (After) เก็บเป็นลิงก์ ต่อท้ายรูปเดิม
      if (resolutionImageUrls.isNotEmpty)
        'images': FieldValue.arrayUnion([
          for (final url in resolutionImageUrls) {'url': url, 'kind': 'resolution'},
        ]),
    };
    final batch = _db.batch()
      ..update(_issues.doc(issueId), patch)
      ..update(_feed.doc(issueId), patch)
      ..set(_issues.doc(issueId).collection('updates').doc(), {
        'actorId': _uid,
        'actorName': actorName,
        'status': status.code,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }

  /// admin กำหนดลำดับความสำคัญของงาน (ผู้แจ้งเขียนฟิลด์นี้ไม่ได้ตาม rules)
  Future<void> adminSetPriority({
    required String issueId,
    required IncidentUrgency priority,
  }) {
    final patch = <String, dynamic>{
      'priority': priority.code,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _db.batch()
      ..update(_issues.doc(issueId), patch)
      ..update(_feed.doc(issueId), patch);
    return batch.commit();
  }

  /// ชื่อที่ใช้ลงนาม: ชื่อที่ผู้ใช้กรอกตอนสมัคร (users/{uid}.displayName) ของ uid ที่ล็อกอินอยู่
  /// ไม่ใช้อีเมล ถ้าไม่มีชื่อเลยใช้ "เจ้าหน้าที่"
  Future<String> _actorName() async {
    final uid = _uid;
    try {
      final profile = await _db.collection('users').doc(uid).get();
      final name = (profile.data()?['displayName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } on FirebaseException catch (_) {
      // อ่านโปรไฟล์ไม่ได้ ใช้ชื่อจากบัญชีแทน
    }
    final name = _auth.currentUser?.displayName?.trim();
    return (name != null && name.isNotEmpty) ? name : 'เจ้าหน้าที่';
  }

  /// Timeline ของเรื่อง (ผู้แจ้งและ admin อ่านได้)
  Stream<List<IncidentUpdate>> watchUpdates(String issueId) {
    return _issues
        .doc(issueId)
        .collection('updates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(IncidentUpdate.fromFirestore).toList());
  }

  /// admin ส่ง feedback ถึงผู้แจ้งโดยไม่เปลี่ยนสถานะ (ลงชื่อผู้ส่ง)
  Future<void> adminSendFeedback({
    required String issueId,
    required IncidentStatus status,
    required String note,
  }) async {
    await _issues.doc(issueId).collection('updates').add({
      'actorId': _uid,
      'actorName': await _actorName(),
      'status': status.code,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// admin แก้ข้อความที่ตัวเองเคยเขียน (แก้ได้แม้งานเสร็จแล้ว)
  Future<void> adminEditUpdate({
    required String issueId,
    required String updateId,
    required String note,
  }) {
    return _issues.doc(issueId).collection('updates').doc(updateId).update({
      'note': note,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }
}
