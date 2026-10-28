import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/data/repositories/incident_repository.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import '../models/incident_model.dart';

final mockIncidentsData = [
  IncidentModel(
    id: 'inc-001',
    title: 'ฝาท่อระบายน้ำชำรุด แตกหักเสี่ยงเกิดอุบัติเหตุ',
    description:
        'ฝาท่อคอนกรีตแตกเป็นรูกว้าง บริเวณหน้าปากซอยมอเตอร์ไซค์และคนเดินเท้าอาจตกลงไปได้ โปรดส่งเจ้าหน้าที่ตรวจสอบด่วนครับ',
    category: IncidentCategory.drainage,
    status: IncidentStatus.pending,
    locationAddress: 'ซอยฉลองกรุง 1 แยก 3 แขวงลาดกระบัง',
    latitude: 13.7299,
    longitude: 100.7782,
    imageUrls: [
      'https://images.unsplash.com/photo-1541888946425-d0fbb186f5f7?auto=format&fit=crop&w=800&q=80',
    ],
    upvoteCount: 14,
    hasUpvoted: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  IncidentModel(
    id: 'inc-002',
    title: 'ไฟส่องสว่างริมทางดับ มืดและอันตรายยามค่ำคืน',
    description:
        'เสาไฟส่องสว่างดับติดต่อกัน 3 ต้น ทางเดินมืดมาก นักศึกษาและคนทำงานเดินผ่านตอนกลางคืนค่อนข้างกังวลเรื่องความปลอดภัย',
    category: IncidentCategory.electricity,
    status: IncidentStatus.inProgress,
    locationAddress: 'ถนนฉลองกรุง ฝั่งตรงข้ามคณะวิศวกรรมศาสตร์',
    latitude: 13.7285,
    longitude: 100.7760,
    imageUrls: [
      'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=800&q=80',
    ],
    upvoteCount: 29,
    hasUpvoted: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  IncidentModel(
    id: 'inc-003',
    title: 'ขยะล้นถังส่งกลิ่นเหม็นกีดขวางทางสัญจร',
    description:
        'เทศบาลจัดเก็บเรียบร้อยแล้วพร้อมฉีดล้างทำความสะอาดบริเวณโดยรอบ ขอบคุณเจ้าหน้าที่ทุกท่านครับ',
    category: IncidentCategory.waste,
    status: IncidentStatus.resolved,
    locationAddress: 'หน้าตลาดนัดสุวรรณภูมิ ซอย 2',
    latitude: 13.7250,
    longitude: 100.7800,
    imageUrls: [
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80',
    ],
    upvoteCount: 42,
    hasUpvoted: false,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

/// Feed: อ่านสดจาก Firestore (issues_feed) เมื่อ Firebase พร้อม ไม่งั้นใช้ข้อมูลจำลอง
class IncidentFeedNotifier extends StateNotifier<List<IncidentModel>> {
  IncidentFeedNotifier(this._repo)
      : super(_repo == null ? mockIncidentsData : const []) {
    _sub = _repo?.watchFeed().listen(_onFeed, onError: _onError);
  }

  StreamSubscription<List<IncidentModel>>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  final IncidentRepository? _repo;

  /// id ของเรื่องที่ผู้ใช้กด +1 ไว้แล้ว (null = ยังไม่ได้เช็ก)
  final Map<String, bool> _followed = {};

  void _onFeed(List<IncidentModel> items) {
    state = [
      for (final i in items) i.copyWith(hasUpvoted: _followed[i.id] ?? false),
    ];
    _loadFollowStatus(items);
  }

  void _onError(Object e) => debugPrint('อ่าน Feed ไม่สำเร็จ: $e');

  Future<void> _loadFollowStatus(List<IncidentModel> items) async {
    final unknown = items.where((i) => !_followed.containsKey(i.id)).toList();
    if (unknown.isEmpty) return;
    final results = await Future.wait(
      unknown.map((i) => _repo!.isFollowing(i.id).catchError((_) => false)),
    );
    for (var k = 0; k < unknown.length; k++) {
      _followed[unknown[k].id] = results[k];
    }
    if (!mounted) return;
    state = [
      for (final i in state) i.copyWith(hasUpvoted: _followed[i.id] ?? i.hasUpvoted),
    ];
  }

  Future<void> toggleUpvote(String incidentId) async {
    final current = state.firstWhere((i) => i.id == incidentId);
    final nowUpvoted = !current.hasUpvoted;

    void apply(bool upvoted, int delta) {
      state = [
        for (final inc in state)
          if (inc.id == incidentId)
            inc.copyWith(hasUpvoted: upvoted, upvoteCount: inc.upvoteCount + delta)
          else
            inc,
      ];
    }

    apply(nowUpvoted, nowUpvoted ? 1 : -1);

    final repo = _repo;
    if (repo == null) return;
    try {
      if (nowUpvoted) {
        await repo.follow(incidentId);
      } else {
        await repo.unfollow(incidentId);
      }
      _followed[incidentId] = nowUpvoted;
    } catch (e) {
      // เช่น เจ้าของเรื่องกด +1 เรื่องตัวเอง หรือไม่มีสิทธิ์: ย้อนค่ากลับ
      debugPrint('กด +1 ไม่สำเร็จ: $e');
      if (mounted) apply(!nowUpvoted, nowUpvoted ? -1 : 1);
    }
  }

  /// ใช้เฉพาะโหมดข้อมูลจำลอง (Firebase ไม่พร้อม)
  void addLocal(IncidentModel incident) => state = [incident, ...state];
}

final incidentFeedProvider =
    StateNotifierProvider<IncidentFeedNotifier, List<IncidentModel>>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  final signedIn = ref.watch(authStateProvider).valueOrNull != null;
  final repo = (ready && signedIn) ? ref.watch(incidentRepositoryProvider) : null;
  return IncidentFeedNotifier(repo);
});

final selectedCategoryFilterProvider = StateProvider<IncidentCategory?>((ref) => null);


/// ประวัติของฉัน: เรื่องที่ตัวเองแจ้ง (issues ที่ reporterId == uid) ไม่งั้นใช้ข้อมูลจำลอง
final myIncidentsProvider = StreamProvider<List<IncidentModel>>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  final signedIn = ref.watch(authStateProvider).valueOrNull != null;
  if (!ready || !signedIn) return Stream.value(mockIncidentsData);
  return ref.watch(incidentRepositoryProvider).watchMine();
});
