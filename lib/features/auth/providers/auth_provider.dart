import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true เมื่อ Firebase เริ่มทำงานสำเร็จ (override ใน main) ถ้า false แอปรันด้วยข้อมูลจำลอง
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// สิทธิ์ admin มาจาก Custom Claim `admin` บน ID token (ตั้งได้จากฝั่งเซิร์ฟเวอร์เท่านั้น)
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  final token = await user.getIdTokenResult(true);
  return token.claims?['admin'] == true;
});
