import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_status_badge.dart';

class AdminWebDashboardScreen extends ConsumerStatefulWidget {
  const AdminWebDashboardScreen({super.key});

  @override
  ConsumerState<AdminWebDashboardScreen> createState() =>
      _AdminWebDashboardScreenState();
}

class _AdminWebDashboardScreenState extends ConsumerState<AdminWebDashboardScreen> {
  IncidentStatus? _selectedStatusFilter;
  IncidentCategory? _selectedCategoryFilter;
  String _searchQuery = '';
  IncidentModel? _selectedIncidentForManage;

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showUpdateStatusDialog(IncidentModel incident) {
    IncidentStatus newStatus = incident.status;
    _noteController.text = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'จัดการสถานะงาน: ${incident.title}',
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เปลี่ยนสถานะการดำเนินงาน:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<IncidentStatus>(
                    value: newStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: IncidentStatus.pending,
                        child: Text('⏳ รอดำเนินการ (Pending)'),
                      ),
                      DropdownMenuItem(
                        value: IncidentStatus.inProgress,
                        child: Text('⚙️ กำลังดำเนินการ / มอบหมายช่าง (In Progress)'),
                      ),
                      DropdownMenuItem(
                        value: IncidentStatus.resolved,
                        child: Text('✅ ดำเนินการแก้ไขแล้วเสร็จ (Resolved)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          newStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('บันทึกหมายเหตุการปฏิบัติงาน (ผู้แจ้งเห็นได้):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เช่น ส่งทีมช่างเข้าซ่อมแซมเรียบร้อยแล้ว...',
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เปิดฟังก์ชันแนบภาพหลักฐานหลังแก้ไข (รูป After)')),
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('แนบภาพถ่ายผลงานหลังแก้ไข (Before / After)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (ref.read(firebaseReadyProvider)) {
                    // เขียนลง Firestore (ต้องเป็น admin ตาม Custom Claim) Feed อัปเดตเองผ่าน stream
                    try {
                      await ref.read(incidentRepositoryProvider).adminUpdateStatus(
                            issueId: incident.id,
                            status: newStatus,
                            note: _noteController.text.trim(),
                          );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('อัปเดตสถานะไม่สำเร็จ: $e')),
                      );
                      return;
                    }
                  } else {
                    ref.read(incidentFeedProvider.notifier).state = [
                      for (final inc in ref.read(incidentFeedProvider))
                        if (inc.id == incident.id)
                          inc.copyWith(status: newStatus)
                        else
                          inc,
                    ];
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  setState(() {
                    if (_selectedIncidentForManage?.id == incident.id) {
                      _selectedIncidentForManage = incident.copyWith(status: newStatus);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('อัปเดตสถานะปัญหาเป็น "${newStatus.name}" เรียบร้อย (Realtime)'),
                      backgroundColor: AppColors.statusResolved,
                    ),
                  );
                },
                child: const Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents = ref.watch(incidentFeedProvider);
    final theme = Theme.of(context);
    final timeFormat = DateFormat('d MMM yyyy, HH:mm น.', 'th');

    // Filter logic
    final filtered = allIncidents.where((item) {
      if (_selectedStatusFilter != null && item.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedCategoryFilter != null && item.category != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.locationAddress.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Stats
    final totalCount = allIncidents.length;
    final pendingCount = allIncidents.where((i) => i.status == IncidentStatus.pending).length;
    final inProgressCount = allIncidents.where((i) => i.status == IncidentStatus.inProgress).length;
    final resolvedCount = allIncidents.where((i) => i.status == IncidentStatus.resolved).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_icon.png',
              height: 32,
              width: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bok Mai Admin Portal (ศูนย์บริหารจัดการเรื่องร้องทุกข์)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'สำหรับเจ้าหน้าที่เทศบาลและผู้ดูแลระบบ',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'แจ้งเตือนเคสเร่งด่วน (AI Sentiment Alert)',
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Content (Stats + Filter + Table)
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 4 Metric Stats Cards
                Row(
                  children: [
                    _buildStatCard('ปัญหาทั้งหมด', '$totalCount', Icons.folder_open_rounded, AppColors.primary, AppColors.primaryContainer),
                    const SizedBox(width: 16),
                    _buildStatCard('รอดำเนินการ', '$pendingCount', Icons.hourglass_top_rounded, AppColors.statusPending, AppColors.statusPendingContainer),
                    const SizedBox(width: 16),
                    _buildStatCard('กำลังซ่อม/ลงพื้นที่', '$inProgressCount', Icons.engineering_rounded, AppColors.statusInProgress, AppColors.statusInProgressContainer),
                    const SizedBox(width: 16),
                    _buildStatCard('แก้ไขแล้วเสร็จ', '$resolvedCount', Icons.check_circle_rounded, AppColors.statusResolved, AppColors.statusResolvedContainer),
                  ],
                ),
                const SizedBox(height: 24),

                // Search & Filter Toolbar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'ค้นหาหัวข้อ, รายละเอียด, หรือพิกัดสถานที่...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status Filter Dropdown
                        DropdownButton<IncidentStatus?>(
                          value: _selectedStatusFilter,
                          hint: const Text('ทุกสถานะ'),
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('สถานะทั้งหมด')),
                            DropdownMenuItem(value: IncidentStatus.pending, child: Text('⏳ รอดำเนินการ')),
                            DropdownMenuItem(value: IncidentStatus.inProgress, child: Text('⚙️ กำลังทำ')),
                            DropdownMenuItem(value: IncidentStatus.resolved, child: Text('✅ แก้ไขแล้ว')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedStatusFilter = val;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        // Category Filter Dropdown
                        DropdownButton<IncidentCategory?>(
                          value: _selectedCategoryFilter,
                          hint: const Text('ทุกหมวดหมู่'),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('ทุกหมวดหมู่')),
                            ...IncidentCategory.values.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryFilter = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Table of Tickets
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerHigh),
                    columns: const [
                      DataColumn(label: Text('ภาพ')),
                      DataColumn(label: Text('หัวข้อปัญหา')),
                      DataColumn(label: Text('หมวดหมู่')),
                      DataColumn(label: Text('สถานะ')),
                      DataColumn(label: Text('สถานที่')),
                      DataColumn(label: Text('ผู้ร่วมแจ้ง')),
                      DataColumn(label: Text('จัดการ')),
                    ],
                    rows: filtered.map((incident) {
                      final isSelected = _selectedIncidentForManage?.id == incident.id;
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (_) {
                          setState(() {
                            _selectedIncidentForManage = incident;
                          });
                        },
                        cells: [
                          DataCell(
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                incident.imageUrls.first,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 28),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                incident.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(incident.categoryLabel)),
                          DataCell(IncidentStatusBadge(status: incident.status)),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(incident.locationAddress, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text('+${incident.upvoteCount} คน')),
                          DataCell(
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 36),
                              ),
                              onPressed: () => _showUpdateStatusDialog(incident),
                              child: const Text('อัปเดตงาน'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Right Detail Panel (เมื่อกดเลือกแถวในตาราง)
          if (_selectedIncidentForManage != null)
            Container(
              width: 380,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(left: BorderSide(color: AppColors.surfaceContainerHighest)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('รายละเอียดงาน', style: theme.textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _selectedIncidentForManage = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(
                      _selectedIncidentForManage!.imageUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedIncidentForManage!.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  IncidentStatusBadge(status: _selectedIncidentForManage!.status),
                  const SizedBox(height: 16),
                  const Text('รายละเอียดที่ประชาชนแจ้ง:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_selectedIncidentForManage!.description),
                  const SizedBox(height: 16),
                  const Text('พิกัดสถานที่:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_selectedIncidentForManage!.locationAddress),
                  const SizedBox(height: 8),
                  Text('GPS: ${_selectedIncidentForManage!.latitude}, ${_selectedIncidentForManage!.longitude}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showUpdateStatusDialog(_selectedIncidentForManage!),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('เปลี่ยนสถานะ & บันทึกงาน'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color containerColor) {
    return Expanded(
      child: Card(
        color: containerColor.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(title, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

