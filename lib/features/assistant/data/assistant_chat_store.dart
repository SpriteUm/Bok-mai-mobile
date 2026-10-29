import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class StoredChatMessage {
  const StoredChatMessage({
    required this.fromUser,
    required this.text,
    this.reportStory,
  });

  final bool fromUser;
  final String text;
  final String? reportStory;
}

/// เก็บประวัติแชตผู้ช่วย AI ของผู้ใช้แต่ละคนใน `users/{uid}/assistant_messages`
/// อ่าน/ลบได้เฉพาะเจ้าของ (ตาม firestore.rules) เปิดแอปใหม่หรือเปลี่ยนเครื่องก็คุยต่อได้
class AssistantChatStore {
  AssistantChatStore._(this._messages);

  final CollectionReference<Map<String, dynamic>> _messages;

  /// null ถ้า Firebase ไม่พร้อมหรือยังไม่ได้ล็อกอิน (แชตยังใช้ได้ แค่ไม่บันทึก)
  static AssistantChatStore? forCurrentUser() {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return AssistantChatStore._(
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('assistant_messages'),
    );
  }

  /// ข้อความล่าสุด [limit] ข้อความ เรียงจากเก่าไปใหม่
  Future<List<StoredChatMessage>> load({int limit = 100}) async {
    final snap = await _messages
        .orderBy('order', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs.reversed)
        StoredChatMessage(
          fromUser: doc.data()['role'] == 'user',
          text: doc.data()['text'] as String? ?? '',
          reportStory: doc.data()['reportStory'] as String?,
        ),
    ];
  }

  /// บันทึกคำถามและคำตอบคู่กัน ([order] ใช้เรียงลำดับ เพราะ serverTimestamp ใน batch เดียวกันเท่ากัน)
  Future<void> addExchange({
    required String question,
    required String answer,
    String? reportStory,
  }) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return (FirebaseFirestore.instance.batch()
          ..set(_messages.doc(), {
            'role': 'user',
            'text': question,
            'order': now,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(_messages.doc(), {
            'role': 'model',
            'text': answer,
            if (reportStory != null) 'reportStory': reportStory,
            'order': now + 1,
            'createdAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }

  /// ลบประวัติแชตทั้งหมดของผู้ใช้
  Future<void> clear() async {
    while (true) {
      final snap = await _messages.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
