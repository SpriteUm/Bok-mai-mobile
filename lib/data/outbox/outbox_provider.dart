import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bok_mai_mobile/data/services/image_upload_service.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';

import 'outbox_item.dart';
import 'outbox_service.dart';
import 'outbox_storage.dart';

/// มีเครือข่ายหรือไม่ (บอกแค่ว่ามี Wi-Fi/มือถือเชื่อมอยู่ ไม่รับประกันว่าเข้าเน็ตได้จริง
/// ตัวตัดสินจริงคือการส่ง: ส่งไม่ผ่านก็เก็บเข้ากล่องรอส่ง)
Future<bool> hasNetwork() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    return true; // เช็กไม่ได้ ให้ลองส่งไปเลย
  }
}

/// สร้างเรื่องใน Firestore: ถ้าไม่มีการยืนยันภายในเวลา ถือว่า Firestore เก็บคิวไว้ในเครื่องแล้ว
/// (เปิด persistence ไว้ จะซิงก์เองเมื่อมีเน็ต) รูปอัปโหลดไปแล้วจึงไม่ต้องรอ
const _createTimeout = Duration(seconds: 20);

final outboxProvider = StateNotifierProvider<OutboxNotifier, List<OutboxItem>>((
  ref,
) {
  return OutboxNotifier(
    OutboxStorage(),
    currentUid: () => ref.read(firebaseReadyProvider)
        ? FirebaseAuth.instance.currentUser?.uid
        : null,
    sender: OutboxSender(
      upload: (bytes, name) => ImageUploadService().upload(
        XFile.fromData(bytes, name: name, mimeType: 'image/jpeg'),
      ),
      create: (draft, id) => ref
          .read(incidentRepositoryProvider)
          .createIssue(draft, id: id)
          .timeout(_createTimeout, onTimeout: () => id),
      exists: (id) => ref.read(incidentRepositoryProvider).issueExists(id),
    ),
  );
});

/// ส่งรายงานรอส่งอัตโนมัติ: ตอนเปิดแอป/ล็อกอิน, ตอนเน็ตกลับมา และตอนกลับเข้าแอป
class OutboxSync extends ConsumerStatefulWidget {
  const OutboxSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OutboxSync> createState() => _OutboxSyncState();
}

class _OutboxSyncState extends ConsumerState<OutboxSync>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  @override
  void initState() {
    super.initState();
    if (!ref.read(firebaseReadyProvider)) return;
    WidgetsBinding.instance.addObserver(this);
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) _flush();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _flush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivity?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _flush();
  }

  Future<void> _flush() async {
    final sent = await ref.read(outboxProvider.notifier).flush();
    if (sent > 0 && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('ส่งรายงานที่รอไว้แล้ว $sent เรื่อง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ล็อกอินแล้ว (หรือสลับบัญชี) ส่งของผู้ใช้คนนั้น
    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull != null &&
          prev?.valueOrNull?.uid != next.valueOrNull?.uid)
        _flush();
    });
    return widget.child;
  }
}
