import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/feed/screens/incident_detail_screen.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_card.dart';

class MyHistoryScreen extends ConsumerStatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  ConsumerState<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends ConsumerState<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents = ref.watch(incidentFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติและติดตามสถานะ'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: '⏳ รอดำเนินการ'),
            Tab(text: '⚙️ กำลังดำเนินการ'),
            Tab(text: '✅ แก้ไขแล้ว'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncidentList(allIncidents),
          _buildIncidentList(
            allIncidents.where((i) => i.status == IncidentStatus.pending).toList(),
          ),
          _buildIncidentList(
            allIncidents.where((i) => i.status == IncidentStatus.inProgress).toList(),
          ),
          _buildIncidentList(
            allIncidents.where((i) => i.status == IncidentStatus.resolved).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentList(List<IncidentModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_rounded,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'ไม่มีประวัติการแจ้งในสถานะนี้',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final incident = list[index];
        return IncidentCard(
          incident: incident,
          onUpvote: () {
            ref.read(incidentFeedProvider.notifier).toggleUpvote(incident.id);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncidentDetailScreen(incident: incident),
              ),
            );
          },
        );
      },
    );
  }
}

