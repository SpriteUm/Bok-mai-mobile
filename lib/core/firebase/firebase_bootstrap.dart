import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

const functionsRegion = 'asia-southeast1';

Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('เริ่ม Firebase ไม่สำเร็จ: $e');
    return false;
  }

  // ออฟไลน์: เก็บข้อมูล Firestore ไว้ในเครื่อง เปิดแอปตอนไม่มีเน็ตยังเห็นฟีดล่าสุด
  // (มือถือเปิดอยู่แล้วโดยค่าเริ่มต้น เว็บต้องเปิดเอง และต้องตั้งก่อนใช้ Firestore ครั้งแรก)
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
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
