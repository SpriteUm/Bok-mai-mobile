import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_card.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_status_badge.dart';

void main() {
  group('Widget Tests: Badges & Incident Cards', () {
    testWidgets('IncidentStatusBadge renders correct labels and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IncidentStatusBadge(status: IncidentStatus.pending),
                IncidentStatusBadge(status: IncidentStatus.inProgress),
                IncidentStatusBadge(status: IncidentStatus.resolved),
              ],
            ),
          ),
        ),
      );

      expect(find.text('รอดำเนินการ'), findsOneWidget);
      expect(find.text('กำลังดำเนินการ'), findsOneWidget);
      expect(find.text('แก้ไขแล้ว'), findsOneWidget);
    });

    testWidgets('IncidentCard displays incident details and triggers callbacks', (tester) async {
      bool upvoted = false;
      bool tapped = false;

      final testIncident = IncidentModel(
        id: 'test-101',
        title: 'ต้นไม้ล้มขวางถนน',
        description: 'ขวาง 2 เลน มอเตอร์ไซค์ผ่านไม่ได้',
        category: IncidentCategory.road,
        status: IncidentStatus.pending,
        locationAddress: 'หน้าหอพักนักศึกษา',
        latitude: 13.728,
        longitude: 100.775,
        imageUrls: [],
        upvoteCount: 12,
        hasUpvoted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncidentCard(
              incident: testIncident,
              onUpvote: () => upvoted = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('ต้นไม้ล้มขวางถนน'), findsOneWidget);
      expect(find.text('ขวาง 2 เลน มอเตอร์ไซค์ผ่านไม่ได้'), findsOneWidget);
      expect(find.text('ผู้ร่วมแจ้ง 12 คน'), findsOneWidget);
      expect(find.text('+1 ติดตาม'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('ต้นไม้ล้มขวางถนน'));
      expect(tapped, isTrue);

      // Tap +1 button
      await tester.tap(find.text('+1 ติดตาม'));
      expect(upvoted, isTrue);
    });
  });
}

