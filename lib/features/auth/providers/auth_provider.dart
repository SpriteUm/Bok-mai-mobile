import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true เมื่อ Firebase เริ่มทำงานสำเร็จ (override ใน main) ถ้า false แอปรันด้วยข้อมูลจำลอง
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// สร้าง users/{uid} ให้ผู้ใช้ที่ยังไม่มีโปรไฟล์ (เช่น บัญชีที่สร้างจาก Console)
/// เพื่อให้แสดงในหน้าจัดการสิทธิ์ของ admin
final ensureProfileProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;
  final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  try {
    if ((await doc.get()).exists) return;
    final email = user.email ?? '';
    await doc.set({
      'displayName': (user.displayName?.isNotEmpty ?? false)
          ? user.displayName
          : (email.isNotEmpty ? email.split('@').first : 'ผู้ใช้'),
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (_) {
    // สร้างโปรไฟล์ไม่ได้ ไม่ขวางการใช้งาน
  }
});

/// สิทธิ์ admin: มีเอกสาร admins/{uid} หรือ users/{uid}.role == admin (ตั้งจาก Console)
/// หรือมี Custom Claim `admin` บน ID token
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return checkIsAdmin(user);
});

/// เช็กสิทธิ์ admin ของ [user] ตรงๆ (ใช้ได้นอก widget tree เช่นตอนเช็ก session timeout)
Future<bool> checkIsAdmin(User user) async {
  try {
    final db = FirebaseFirestore.instance;
    if ((await db.collection('admins').doc(user.uid).get()).exists) return true;
    final profile = await db.collection('users').doc(user.uid).get();
    if (profile.data()?['role'] == 'admin') return true;
  } on FirebaseException catch (_) {
    // อ่านไม่ได้ถือว่าไม่ใช่ admin
  }

  final token = await user.getIdTokenResult(true);
  return token.claims?['admin'] == true;
}
