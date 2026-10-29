import 'package:flutter/material.dart';
import 'package:bok_mai_mobile/features/history/widgets/outbox_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/feed/screens/incident_detail_screen.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_card.dart';
import 'package:bok_mai_mobile/features/report/screens/report_form_screen.dart';

class MyHistoryScreen extends ConsumerStatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  ConsumerState<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends ConsumerState<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// id ที่เลือกไว้ (ไม่ว่าง = อยู่ในโหมดเลือกเพื่อลบ)
  final Set<String> _selected = {};
  bool _deleting = false;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // เปลี่ยนแท็บแล้วต้องคำนวณปุ่ม "เลือกทั้งหมด" ใหม่
    _tabController.addListener(() {
      if (_selecting && !_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// เรื่องที่ลบได้: ไม่มีคนกด +1 ร่วม (ตรงกับเงื่อนไขใน firestore.rules)
  bool _deletable(IncidentModel i) => i.upvoteCount <= 1;

  List<IncidentModel> _tabItems(List<IncidentModel> all, int tab) =>
      switch (tab) {
        1 => all.where((i) => i.status == IncidentStatus.pending).toList(),
        2 => all.where((i) => i.status == IncidentStatus.inProgress).toList(),
        3 => all.where((i) => i.status == IncidentStatus.resolved).toList(),
        _ => all,
      };

  void _toggle(IncidentModel incident) {
    if (!_deletable(incident)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบไม่ได้ เพราะมีคนกด +1 ร่วมกับเรื่องนี้แล้ว'),
        ),
      );
      return;
    }
    setState(() {
      if (!_selected.remove(incident.id)) _selected.add(incident.id);
    });
  }

  /// แก้ไขได้เฉพาะเรื่องที่ยังรอดำเนินการและไม่มีคนกด +1 ร่วม (ตรงกับ firestore.rules)
  bool _editable(IncidentModel i) =>
      i.status == IncidentStatus.pending && i.upvoteCount <= 1;

  Future<void> _edit(IncidentModel incident) async {
    final live =
        ref.read(firebaseReadyProvider) &&
        ref.read(authStateProvider).valueOrNull != null;
    if (!live) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'แก้ไขได้เมื่อเชื่อมต่อ Firebase และเข้าสู่ระบบแล้วเท่านั้น',
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportFormScreen(editing: incident)),
    );
  }

  Future<void> _deleteSelected() => _deleteIds(_selected.toList());

  Future<void> _deleteIds(List<String> ids) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ลบ ${ids.length} รายการ?'),
        content: const Text(
          'รายงานจะถูกลบออกจากประวัติและหน้าข่าวสารถาวร ย้อนกลับไม่ได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final live =
        ref.read(firebaseReadyProvider) &&
        ref.read(authStateProvider).valueOrNull != null;
    if (!live) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ลบได้เมื่อเชื่อมต่อ Firebase และเข้าสู่ระบบแล้วเท่านั้น',
          ),
        ),
      );
      return;
    }

    setState(() => _deleting = true);
    try {
      await ref.read(incidentRepositoryProvider).deleteIssues(ids);
      if (!mounted) return;
      setState(() => _selected.removeAll(ids));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบ ${ids.length} รายการแล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  TabBar _tabBar() => TabBar(
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
  );

  AppBar _selectionAppBar(List<IncidentModel> all) {
    final tabIds = _tabItems(
      all,
      _tabController.index,
    ).where(_deletable).map((i) => i.id).toList();
    final allSelected = tabIds.isNotEmpty && tabIds.every(_selected.contains);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'ยกเลิกการเลือก',
        onPressed: _deleting ? null : () => setState(_selected.clear),
      ),
      title: Text('เลือกแล้ว ${_selected.length}'),
      actions: [
        IconButton(
          icon: Icon(
            allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
          ),
          tooltip: allSelected ? 'ไม่เลือกทั้งหมด' : 'เลือกทั้งหมดในแท็บนี้',
          onPressed: _deleting
              ? null
              : () => setState(() {
                  allSelected
                      ? _selected.removeAll(tabIds)
                      : _selected.addAll(tabIds);
                }),
        ),
        IconButton(
          icon: _deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_rounded, color: AppColors.error),
          tooltip: 'ลบที่เลือก',
          onPressed: _deleting ? null : _deleteSelected,
        ),
      ],
      bottom: _tabBar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents =
        ref.watch(myIncidentsProvider).valueOrNull ?? const <IncidentModel>[];

    return Scaffold(
      appBar: _selecting
          ? _selectionAppBar(allIncidents)
          : AppBar(
              title: const Text('ประวัติและติดตามสถานะ'),
              bottom: _tabBar(),
            ),
      body: Column(
        children: [
          // รายงานที่บันทึกไว้ตอนออฟไลน์ รอส่ง
          const OutboxPanel(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (var tab = 0; tab < 4; tab++)
                  _buildIncidentList(_tabItems(allIncidents, tab)),
              ],
            ),
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
            const Icon(Icons.inbox_rounded, size: 64, color: AppColors.outline),
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
        final selected = _selected.contains(incident.id);
        return GestureDetector(
          onLongPress: _selecting ? null : () => _toggle(incident),
          child: Stack(
            children: [
              IncidentCard(
                isMine: true,
                incident: incident,
                onUpvote: () {
                  ref
                      .read(incidentFeedProvider.notifier)
                      .toggleUpvote(incident.id);
                },
                onTap: () {
                  if (_selecting) {
                    _toggle(incident);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IncidentDetailScreen(incident: incident),
                    ),
                  );
                },
              ),
              if (!_selecting && (_editable(incident) || _deletable(incident)))
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'แก้ไข / ลบ',
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                      onSelected: (v) => v == 'edit'
                          ? _edit(incident)
                          : _deleteIds([incident.id]),
                      itemBuilder: (_) => [
                        if (_editable(incident))
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_rounded),
                              title: Text('แก้ไข'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (_deletable(incident))
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_rounded,
                                color: AppColors.error,
                              ),
                              title: Text('ลบ'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
