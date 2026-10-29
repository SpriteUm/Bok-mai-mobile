import 'dart:async';
import 'dart:typed_data';

import 'package:bok_mai_mobile/data/outbox/outbox_item.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_service.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_storage_memory.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

OutboxItem _item(String id, {String uid = 'me', int images = 1}) => OutboxItem(
  id: id,
  uid: uid,
  createdAt: DateTime(2026, 10, 30),
  images: [
    for (var i = 0; i < images; i++) Uint8List.fromList([i]),
  ],
  report: IncidentModel(
    id: id,
    title: 'เรื่อง $id',
    description: '',
    category: IncidentCategory.road,
    status: IncidentStatus.pending,
    locationAddress: '',
    latitude: 13.7,
    longitude: 100.7,
    imageUrls: const [],
    upvoteCount: 1,
    createdAt: DateTime(2026, 10, 30),
  ),
);

/// ระบบส่งปลอม: นับการเรียก และจำลองเน็ตล่ม/สร้างแล้วแต่ไม่ได้รับยืนยัน
class _FakeBackend {
  bool online = true;
  final uploads = <String>[];
  final created = <String, IncidentModel>{};
  final existing = <String>{};
  Completer<void>? createGate;
  bool failCreate = false;

  OutboxSender get sender => OutboxSender(
    upload: (bytes, name) async {
      if (!online) throw Exception('offline');
      uploads.add(name);
      return 'https://img/$name';
    },
    create: (draft, id) async {
      if (!online) throw Exception('offline');
      await createGate?.future;
      if (failCreate) throw Exception('offline');
      if (existing.contains(id)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      }
      created[id] = draft;
    },
    exists: (id) async => existing.contains(id) || created.containsKey(id),
  );
}

void main() {
  late _FakeBackend backend;
  late OutboxNotifier outbox;
  String? uid;

  setUp(() {
    backend = _FakeBackend();
    uid = 'me';
    outbox = OutboxNotifier(
      MemoryOutboxStorage(),
      sender: backend.sender,
      currentUid: () => uid,
    );
  });

  test(
    'ออฟไลน์: เก็บไว้ไม่หาย, ออนไลน์: ส่งพร้อมลิงก์รูปแล้วลบออกจากกล่อง',
    () async {
      backend.online = false;
      await outbox.enqueue(_item('a', images: 2));
      expect(await outbox.flush(), 0);
      expect(outbox.state.map((i) => i.id), ['a']);

      backend.online = true;
      expect(await outbox.flush(), 1);
      expect(outbox.state, isEmpty);
      expect(backend.created['a']!.imageUrls, hasLength(2));
    },
  );

  test('รูปที่อัปโหลดแล้วไม่อัปโหลดซ้ำเมื่อส่งรอบใหม่', () async {
    await outbox.enqueue(_item('a', images: 2));
    // อัปโหลดรูปได้ แต่สร้างเรื่องไม่ได้ (เน็ตหลุดหลังอัปโหลด)
    backend.failCreate = true;
    expect(await outbox.flush(), 0);
    expect(backend.uploads, hasLength(2));

    backend.failCreate = false;
    expect(await outbox.flush(), 1);
    expect(backend.uploads, hasLength(2), reason: 'ไม่ควรอัปโหลดรูปเดิมอีก');
  });

  test(
    'สร้างเรื่องไปแล้วแต่ไม่ได้รับยืนยัน: ส่งซ้ำถูกปฏิเสธ แต่นับว่าสำเร็จ ไม่ค้างในกล่อง',
    () async {
      await outbox.enqueue(_item('a'));
      backend.existing.add('a');
      expect(await outbox.flush(), 1);
      expect(outbox.state, isEmpty);
    },
  );

  test('กดส่งซ้อนกันหลายครั้ง ส่งเรื่องเดียวแค่ครั้งเดียว', () async {
    await outbox.enqueue(_item('a'));
    backend.createGate = Completer();
    final first = outbox.flush();
    final second = outbox.flush();
    backend.createGate!.complete();
    expect(await Future.wait([first, second]), [1, 1]);
    expect(backend.uploads, hasLength(1));
  });

  test('รายงานของบัญชีอื่นไม่ถูกส่งในชื่อผู้ใช้ปัจจุบัน', () async {
    await outbox.enqueue(_item('mine'));
    await outbox.enqueue(_item('theirs', uid: 'someone-else'));
    expect(await outbox.flush(), 1);
    expect(backend.created.keys, ['mine']);
    expect(outbox.state.map((i) => i.id), ['theirs']);
  });

  test('ยังไม่ล็อกอิน ไม่ส่งอะไรเลย', () async {
    uid = null;
    await outbox.enqueue(_item('a'));
    expect(await outbox.flush(), 0);
    expect(backend.created, isEmpty);
  });
}
