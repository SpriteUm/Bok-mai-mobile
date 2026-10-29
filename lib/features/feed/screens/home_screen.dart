import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/screens/incident_detail_screen.dart';
import '../models/incident_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/emergency_note.dart';
import '../widgets/incident_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIncidents = ref.watch(incidentFeedProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    // เรื่องที่ตัวเองแจ้ง: กด +1 เองไม่ได้ (นับเป็น 1 คนอยู่แล้ว)
    final myIds = {
      for (final i
          in ref.watch(myIncidentsProvider).valueOrNull ??
              const <IncidentModel>[])
        i.id,
    };

    final filteredIncidents = selectedCategory == null
        ? allIncidents
        : allIncidents.where((i) => i.category == selectedCategory).toList();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = screenWidth >= 640;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_icon.png',
              height: 38,
              width: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บอกไหม (Bok Mai)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'ฟีดปัญหาสาธารณะเพื่อชุมชน',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'การแจ้งเตือน',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EmergencyNote(),
            ),
          ),

          // Category Quick Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('ทั้งหมด'),
                    selected: selectedCategory == null,
                    onSelected: (_) {
                      ref.read(selectedCategoryFilterProvider.notifier).state =
                          null;
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...IncidentCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    String label;
                    switch (cat) {
                      case IncidentCategory.electricity:
                        label = '⚡ ไฟฟ้า';
                        break;
                      case IncidentCategory.water:
                        label = '💧 น้ำประปา';
                        break;
                      case IncidentCategory.road:
                        label = '🛣️ ถนน/ทางเท้า';
                        break;
                      case IncidentCategory.waste:
                        label = '🗑️ ขยะ';
                        break;
                      case IncidentCategory.drainage:
                        label = '🌊 ท่อระบายน้ำ';
                        break;
                      case IncidentCategory.other:
                        label = '📌 อื่นๆ';
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = selected
                              ? cat
                              : null;
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Incident Cards Feed
          if (filteredIncidents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppColors.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ไม่มีรายการปัญหาในหมวดหมู่นี้',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else if (isTabletOrDesktop)
            // iPad / Tablet: 2 Columns Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 520,
                  mainAxisExtent: 440,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final incident = filteredIncidents[index];
                  return IncidentCard(
                    incident: incident,
                    isMine: myIds.contains(incident.id),
                    onUpvote: () {
                      ref
                          .read(incidentFeedProvider.notifier)
                          .toggleUpvote(incident.id);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              IncidentDetailScreen(incident: incident),
                        ),
                      );
                    },
                  );
                }, childCount: filteredIncidents.length),
              ),
            )
          else
            // Phone: Single Column List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final incident = filteredIncidents[index];
                return IncidentCard(
                  incident: incident,
                  isMine: myIds.contains(incident.id),
                  onUpvote: () {
                    ref
                        .read(incidentFeedProvider.notifier)
                        .toggleUpvote(incident.id);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            IncidentDetailScreen(incident: incident),
                      ),
                    );
                  },
                );
              }, childCount: filteredIncidents.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
