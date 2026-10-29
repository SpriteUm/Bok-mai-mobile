import 'outbox_item.dart';
import 'outbox_storage_memory.dart'
    if (dart.library.io) 'outbox_storage_io.dart'
    as impl;

/// ที่เก็บกล่องรอส่ง: มือถือเก็บเป็นไฟล์ในเครื่อง (ปิดแอปแล้วยังอยู่)
/// เว็บเก็บในหน่วยความจำ (ปิดแท็บแล้วหาย)
abstract class OutboxStorage {
  /// true = ปิดแอปแล้วยังอยู่
  bool get persistent;

  Future<List<OutboxItem>> loadAll();
  Future<void> save(OutboxItem item);
  Future<void> delete(String id);

  factory OutboxStorage() => impl.createOutboxStorage();
}
