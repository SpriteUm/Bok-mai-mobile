import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true เมื่อ Firebase เริ่มทำงานสำเร็จ (override ใน main) ถ้า false แอปรันด้วยข้อมูลจำลอง
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// สิทธิ์ admin: มีเอกสาร admins/{uid} ใน Firestore (เพิ่ม/ถอนได้จาก Console)
/// หรือมี Custom Claim `admin` บน ID token
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;

  try {
    final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    if (doc.exists) return true;
  } on FirebaseException catch (_) {
    // อ่านไม่ได้ถือว่าไม่ใช่ admin
  }

  final token = await user.getIdTokenResult(true);
  return token.claims?['admin'] == true;
});
