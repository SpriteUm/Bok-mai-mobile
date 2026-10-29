import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';

import 'outbox_item.dart';
import 'outbox_storage.dart';

/// ช่องทางส่งจริง (แยกออกมาเพื่อทดสอบด้วยของปลอมได้)
class OutboxSender {
  const OutboxSender({
    required this.upload,
    required this.create,
    required this.exists,
  });

  /// อัปโหลดรูป คืนลิงก์
  final Future<String> Function(Uint8List bytes, String name) upload;

  /// สร้างเรื่องใน Firestore ด้วย id ที่กำหนด
  final Future<void> Function(IncidentModel draft, String id) create;

  /// มีเรื่อง id นี้ในระบบแล้วหรือยัง
  final Future<bool> Function(String id) exists;
}

/// กล่องรอส่ง: รายงานที่ส่งไม่ได้ตอนออฟไลน์ เก็บไว้แล้วส่งเองเมื่อมีเน็ต
///
/// ส่งซ้ำได้ปลอดภัย: id ของเรื่องกำหนดไว้ตั้งแต่เข้ากล่อง, รูปที่อัปโหลดแล้วจำลิงก์ไว้,
/// และถ้าเรื่องถูกสร้างไปแล้วแต่ไม่ได้รับการยืนยัน (เน็ตหลุดกลางทาง) จะนับว่าส่งสำเร็จ
class OutboxNotifier extends StateNotifier<List<OutboxItem>> {
  OutboxNotifier(
    this._storage, {
    required this.sender,
    required this.currentUid,
  }) : super(const []) {
    _loaded = _load();
  }

  Future<void> _load() async {
    try {
      final items = await _storage.loadAll();
      if (mounted) state = items;
    } catch (e) {
      debugPrint('โหลดกล่องรอส่งไม่สำเร็จ: $e');
    }
  }

  final OutboxStorage _storage;
  final OutboxSender sender;
  final String? Function() currentUid;
  late final Future<void> _loaded;
  Future<int>? _flushing;

  /// ข้อผิดพลาดล่าสุดตอนส่ง (แสดงในหน้าประวัติ)
  Object? lastError;

  /// true = ปิดแอปแล้วรายงานรอส่งยังอยู่ (มือถือ), false = ปิดแท็บแล้วหาย (เว็บ)
  bool get persistent => _storage.persistent;

  Future<void> enqueue(OutboxItem item) async {
    await _loaded;
    await _storage.save(item);
    state = [...state, item];
  }

  /// ลบรายงานรอส่งทิ้ง (ผู้ใช้ไม่ต้องการส่งแล้ว)
  Future<void> remove(String id) async {
    await _storage.delete(id);
    state = [
      for (final i in state)
        if (i.id != id) i,
    ];
  }

  /// ส่งรายงานรอส่งของผู้ใช้ที่ล็อกอินอยู่ คืนจำนวนที่ส่งสำเร็จ
  /// เรียกซ้อนกันได้ (ตอนเน็ตกลับมา/เปิดแอป/กดปุ่ม) จะรอรอบเดิมแทนการส่งซ้ำ
  Future<int> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<int> _flush() async {
    await _loaded;
    final uid = currentUid();
    if (uid == null) return 0;
    var sent = 0;
    for (final item in List.of(state)) {
      if (item.uid != uid) continue; // ของบัญชีอื่น รอให้เจ้าของล็อกอิน
      try {
        await _send(item);
      } catch (e) {
        // ส่วนใหญ่คือยังไม่มีเน็ต หยุดรอบนี้ไว้ก่อน เก็บรายการไว้ลองใหม่
        debugPrint('ส่งรายงานรอส่ง ${item.id} ไม่สำเร็จ: $e');
        lastError = e;
        break;
      }
      await _storage.delete(item.id);
      sent++;
      if (mounted)
        state = [
          for (final i in state)
            if (i.id != item.id) i,
        ];
    }
    if (sent > 0 && state.every((i) => i.uid != uid)) lastError = null;
    return sent;
  }

  Future<void> _send(OutboxItem item) async {
    for (var i = item.uploadedUrls.length; i < item.images.length; i++) {
      item.uploadedUrls.add(
        await sender.upload(item.images[i], 'report_${item.id}_$i.jpg'),
      );
      await _storage.save(item); // จำลิงก์ไว้ ส่งซ้ำจะไม่อัปโหลดรูปเดิมอีก
    }
    final draft = item.report.copyWith(imageUrls: List.of(item.uploadedUrls));
    try {
      await sender.create(draft, item.id);
    } on FirebaseException catch (e) {
      // rules ห้ามเขียนทับเรื่องที่มีอยู่แล้ว: ถ้ารอบก่อนสร้างสำเร็จแต่ไม่ได้รับการยืนยัน ถือว่าส่งแล้ว
      if (e.code == 'permission-denied' && await sender.exists(item.id)) return;
      rethrow;
    }
  }
}
