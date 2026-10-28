import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const functionsRegion = 'asia-southeast1';

/// เริ่ม Firebase คืนค่า false ถ้ายังไม่ได้รัน `flutterfire configure`
/// (แอปยังรันด้วยข้อมูลจำลองได้)
///
/// ต่อ emulator ด้วย `flutter run --dart-define=EMULATOR_HOST=10.0.2.2`
/// (iOS Simulator / Web / Desktop ใช้ localhost)
Future<bool> initFirebase() async {
  try {
    // หลังรัน `flutterfire configure` ให้ส่ง options: DefaultFirebaseOptions.currentPlatform
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase ยังไม่ได้ตั้งค่า (รัน `flutterfire configure`): $e');
    return false;
  }

  const host = String.fromEnvironment('EMULATOR_HOST');
  if (kDebugMode && host.isNotEmpty) {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(host, 5001);
  }
  return true;
}
