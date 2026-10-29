import 'outbox_item.dart';
import 'outbox_storage.dart';

OutboxStorage createOutboxStorage() => MemoryOutboxStorage();

/// เก็บในหน่วยความจำ (เว็บ และใช้ใน test)
class MemoryOutboxStorage implements OutboxStorage {
  final _items = <String, OutboxItem>{};

  @override
  bool get persistent => false;

  @override
  Future<List<OutboxItem>> loadAll() async => _items.values.toList();

  @override
  Future<void> save(OutboxItem item) async => _items[item.id] = item;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}
