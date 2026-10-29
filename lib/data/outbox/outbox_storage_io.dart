import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'outbox_item.dart';
import 'outbox_storage.dart';

OutboxStorage createOutboxStorage() => FileOutboxStorage();

/// เก็บเป็นไฟล์ในเครื่อง: `outbox/{id}/item.json` + `img_0.jpg`, `img_1.jpg` ...
class FileOutboxStorage implements OutboxStorage {
  @override
  bool get persistent => true;

  Future<Directory> _root() async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/outbox',
    );
    return dir.create(recursive: true);
  }

  @override
  Future<List<OutboxItem>> loadAll() async {
    final items = <OutboxItem>[];
    await for (final entry in (await _root()).list()) {
      if (entry is! Directory) continue;
      try {
        final json =
            jsonDecode(await File('${entry.path}/item.json').readAsString())
                as Map<String, dynamic>;
        final count = json['imageCount'] as int? ?? 0;
        final images = <Uint8List>[
          for (var i = 0; i < count; i++)
            await File('${entry.path}/img_$i.jpg').readAsBytes(),
        ];
        items.add(OutboxItem.fromJson(json, images));
      } catch (e) {
        // ไฟล์เสีย (เช่นแอปปิดระหว่างเขียน) ข้ามไป ไม่ให้ทั้งกล่องพัง
        debugPrint('อ่านรายงานรอส่ง ${entry.path} ไม่ได้: $e');
      }
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<void> save(OutboxItem item) async {
    final dir = await Directory(
      '${(await _root()).path}/${item.id}',
    ).create(recursive: true);
    for (var i = 0; i < item.images.length; i++) {
      await File(
        '${dir.path}/img_$i.jpg',
      ).writeAsBytes(item.images[i], flush: true);
    }
    // เขียน json ทีหลังสุด: ถ้าแอปปิดกลางทาง จะไม่มีรายการที่รูปไม่ครบ
    await File(
      '${dir.path}/item.json',
    ).writeAsString(jsonEncode(item.toJson()), flush: true);
  }

  @override
  Future<void> delete(String id) async {
    final dir = Directory('${(await _root()).path}/$id');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
