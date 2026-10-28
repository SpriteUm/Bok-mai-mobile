import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUser {
  const AppUser({required this.uid, required this.displayName, required this.email});

  final String uid;
  final String displayName;
  final String email;
}

/// ผู้ใช้ทั้งหมด (users/{uid}) — admin อ่านได้ตาม firestore.rules
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => [
            for (final d in s.docs)
              AppUser(
                uid: d.id,
                displayName: d.data()['displayName'] as String? ?? '',
                email: d.data()['email'] as String? ?? '',
              ),
          ]);
});

/// uid ของ admin ทั้งหมด (เอกสารใน admins/{uid})
final adminIdsProvider = StreamProvider<Set<String>>((ref) {
  return FirebaseFirestore.instance
      .collection('admins')
      .snapshots()
      .map((s) => {for (final d in s.docs) d.id});
});

/// เพิ่ม/ถอนสิทธิ์ admin (เขียนได้เฉพาะ admin ตาม rules)
Future<void> setAdminRole(String uid, {required bool isAdmin}) {
  final ref = FirebaseFirestore.instance.collection('admins').doc(uid);
  return isAdmin ? ref.set({'role': 'admin'}) : ref.delete();
}
