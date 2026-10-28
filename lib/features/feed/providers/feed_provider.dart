import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class IncidentFeedNotifier extends StateNotifier<List<IncidentModel>> {
  IncidentFeedNotifier() : super(mockIncidentsData);

  void toggleUpvote(String incidentId) {
    state = [
      for (final inc in state)
        if (inc.id == incidentId)
          inc.copyWith(
            hasUpvoted: !inc.hasUpvoted,
            upvoteCount: inc.hasUpvoted ? inc.upvoteCount - 1 : inc.upvoteCount + 1,
          )
        else
          inc,
    ];
  }
}

final incidentFeedProvider =
    StateNotifierProvider<IncidentFeedNotifier, List<IncidentModel>>((ref) {
  return IncidentFeedNotifier();
});

final selectedCategoryFilterProvider = StateProvider<IncidentCategory?>((ref) => null);

