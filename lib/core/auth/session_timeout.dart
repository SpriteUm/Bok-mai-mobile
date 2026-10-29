import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';

/// แอดมินพับแอปไว้นานเกินนี้ กลับมาต้องล็อกอินใหม่ (ผู้ใช้ทั่วไปไม่หมดเวลา)
const sessionTimeout = Duration(minutes: 15);

/// true เมื่อเพิ่งออกจากระบบเพราะหมดเวลา (หน้าเข้าสู่ระบบใช้แสดงข้อความ)
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

/// จดเวลาที่แอปถูกพับ แล้วเช็กตอนกลับมา (และตอนเปิดแอปใหม่ เผื่อระบบปิดแอปทิ้งระหว่างพับ)
/// เวลาที่พับเก็บเป็นไฟล์ในเครื่อง บนเว็บเก็บในหน่วยความจำอย่างเดียว
class SessionTimeout extends ConsumerStatefulWidget {
  const SessionTimeout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends ConsumerState<SessionTimeout> with WidgetsBindingObserver {
  DateTime? _backgroundAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExpired();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // เก็บครั้งแรกที่พับ (paused/hidden มาติดกันได้)
      if (_backgroundAt == null) {
        _backgroundAt = DateTime.now();
        _writeStamp(_backgroundAt!);
      }
    } else if (state == AppLifecycleState.resumed) {
      _checkExpired();
    }
  }

  Future<void> _checkExpired() async {
    if (!ref.read(firebaseReadyProvider)) return;
    final since = _backgroundAt ?? await _readStamp();
    _backgroundAt = null;
    await _clearStamp();
    if (since == null || DateTime.now().difference(since) < sessionTimeout) return;
    // ตอนเปิดแอปใหม่ Firebase อาจยังโหลดผู้ใช้ที่จำไว้ไม่เสร็จ รอให้ได้ค่าแรกก่อน
    final user = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) return;
    // หมดเวลาเฉพาะแอดมิน (เข้าถึงข้อมูลผู้แจ้งได้) ประชาชนล็อกอินครั้งเดียวจำไว้เหมือนแอปทั่วไป
    if (!await checkIsAdmin(user)) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) ref.read(sessionExpiredProvider.notifier).state = true;
  }

  Future<File?> _stampFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/session_background_at');
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeStamp(DateTime t) async {
    try {
      await (await _stampFile())?.writeAsString(t.toIso8601String());
    } catch (_) {
      // เขียนไม่ได้ก็ยังเช็กจากเวลาในหน่วยความจำได้
    }
  }

  Future<DateTime?> _readStamp() async {
    try {
      final f = await _stampFile();
      if (f == null || !await f.exists()) return null;
      return DateTime.tryParse(await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearStamp() async {
    try {
      final f = await _stampFile();
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // ล็อกอินกลับมาแล้ว ไม่ต้องแสดงข้อความหมดเวลาอีก (เช่น ตอนออกจากระบบเองครั้งถัดไป)
    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null) ref.read(sessionExpiredProvider.notifier).state = false;
    });
    return widget.child;
  }
}
