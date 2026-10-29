import 'package:firebase_auth/firebase_auth.dart';
import 'package:bok_mai_mobile/features/navigation/screens/main_navigation_shell.dart';
import 'package:bok_mai_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bok_mai_mobile/core/constants/cloudinary_config.dart';
import 'package:bok_mai_mobile/data/services/image_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_status_badge.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_updates_section.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_urgency_badge.dart';
import 'package:bok_mai_mobile/features/admin/widgets/incident_location_map.dart';

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

  /// ส่งข้อความ (และภาพหลังแก้ไขถ้ามี) ถึงผู้แจ้งโดยไม่เปลี่ยนสถานะ (ลงชื่อแอดมินที่ส่ง)
  void _showFeedbackDialog(IncidentModel incident) {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    XFile? photo;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('ส่ง Feedback ถึงผู้แจ้ง'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 1000,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ข้อความถึงผู้แจ้ง จะลงชื่อของคุณกำกับ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        imageQuality: 85,
                      );
                      if (picked != null) setDialogState(() => photo = picked);
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')));
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(
                    photo == null
                        ? 'แนบภาพผลงานหลังแก้ไข (ไม่บังคับ)'
                        : 'เลือกแล้ว: ${photo!.name} (กดเพื่อเปลี่ยน)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                final note = controller.text.trim();
                if (note.isEmpty && photo == null) return;
                if (!ref.read(firebaseReadyProvider)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('ส่งได้เมื่อเชื่อมต่อ Firebase แล้วเท่านั้น')),
                  );
                  return;
                }
                // ปิดทันทีแล้วส่งเบื้องหลัง กันกดซ้ำ
                Navigator.pop(ctx);
                _submitFeedback(incident, note, photo);
              },
              child: const Text('ส่ง'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _showUpdateStatusDialog(IncidentModel incident) {
    IncidentStatus newStatus = incident.status;
    XFile? afterImage;
    _noteController.text = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            scrollable: true,
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
                    isExpanded: true,
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
                    onPressed: () async {
                      try {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1600,
                          imageQuality: 85,
                        );
                        if (picked != null) setDialogState(() => afterImage = picked);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      afterImage == null
                          ? 'แนบภาพถ่ายผลงานหลังแก้ไข (After)'
                          : 'เลือกแล้ว: ${afterImage!.name} (กดเพื่อเปลี่ยน)',
                      overflow: TextOverflow.ellipsis,
                    ),
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
                onPressed: () {
                  // ปิดหน้าต่างทันทีแล้วส่งเบื้องหลัง กันกดซ้ำ (เคยส่งเบิ้ลและจอแดงเพราะใช้ context ของ dialog ที่ปิดไปแล้ว)
                  final note = _noteController.text.trim();
                  final photo = afterImage;
                  Navigator.pop(ctx);
                  _submitStatusUpdate(incident, newStatus, note, photo);
                },
                child: const Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ส่งงานเบื้องหลังหลังปิดหน้าต่าง: แจ้ง "กำลังส่ง" ทันที แล้วแจ้งผลเมื่อเสร็จ
  Future<void> _runInBackground({
    required String progress,
    required String success,
    required String failure,
    required Future<void> Function() task,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(progress)),
          ],
        ),
        duration: const Duration(minutes: 2),
      ));
    try {
      await task();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(success), backgroundColor: AppColors.statusResolved));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$failure: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<String> _uploadAfterPhoto(XFile photo) {
    if (!CloudinaryConfig.isConfigured) {
      throw ImageUploadException('ยังไม่ได้ตั้งค่า Cloudinary จึงแนบรูปไม่ได้');
    }
    return ImageUploadService().upload(photo);
  }

  void _submitStatusUpdate(IncidentModel incident, IncidentStatus newStatus, String note, XFile? photo) {
    if (!ref.read(firebaseReadyProvider)) {
      // โหมดข้อมูลจำลอง
      ref.read(incidentFeedProvider.notifier).state = [
        for (final inc in ref.read(incidentFeedProvider))
          if (inc.id == incident.id) inc.copyWith(status: newStatus) else inc,
      ];
      return;
    }
    _runInBackground(
      progress: photo == null ? 'กำลังบันทึก...' : 'กำลังอัปโหลดรูปและบันทึก...',
      success: 'อัปเดตสถานะเป็น "${statusLabelTh(newStatus)}" แล้ว',
      failure: 'อัปเดตสถานะไม่สำเร็จ',
      task: () async {
        final afterUrls = photo == null ? <String>[] : [await _uploadAfterPhoto(photo)];
        await ref.read(incidentRepositoryProvider).adminUpdateStatus(
              issueId: incident.id,
              status: newStatus,
              note: note,
              resolutionImageUrls: afterUrls,
            );
      },
    );
  }

  void _submitFeedback(IncidentModel incident, String note, XFile? photo) {
    _runInBackground(
      progress: photo == null ? 'กำลังส่ง Feedback...' : 'กำลังอัปโหลดรูปและส่ง Feedback...',
      success: 'ส่ง Feedback แล้ว',
      failure: 'ส่ง Feedback ไม่สำเร็จ',
      task: () async {
        final repo = ref.read(incidentRepositoryProvider);
        if (photo != null) {
          // สถานะเดิม + ต่อท้ายรูป After + ข้อความลงชื่อ ใน batch เดียว
          await repo.adminUpdateStatus(
            issueId: incident.id,
            status: incident.status,
            note: note,
            resolutionImageUrls: [await _uploadAfterPhoto(photo)],
          );
        } else {
          await repo.adminSendFeedback(issueId: incident.id, status: incident.status, note: note);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents = ref.watch(incidentFeedProvider);
    // ให้แผงรายละเอียดใช้ข้อมูลล่าสุดจาก stream (เช่น รูป After ที่เพิ่งส่ง)
    final selectedId = _selectedIncidentForManage?.id;
    if (selectedId != null) {
      for (final i in allIncidents) {
        if (i.id == selectedId) _selectedIncidentForManage = i;
      }
    }
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
    }).toList()
      ..sort(_byPriority);

    // Stats
    final totalCount = allIncidents.length;
    final pendingCount = allIncidents.where((i) => i.status == IncidentStatus.pending).length;
    final inProgressCount = allIncidents.where((i) => i.status == IncidentStatus.inProgress).length;
    final resolvedCount = allIncidents.where((i) => i.status == IncidentStatus.resolved).length;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWide
                        ? 'Bok Mai Admin Portal (ศูนย์บริหารจัดการเรื่องร้องทุกข์)'
                        : 'Bok Mai Admin',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isWide ? 'สำหรับเจ้าหน้าที่เทศบาลและผู้ดูแลระบบ' : 'ศูนย์จัดการเรื่องร้องทุกข์',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_iphone_rounded),
            tooltip: 'สลับไปมุมมองผู้ใช้',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            ),
          ),
          if (ref.watch(firebaseReadyProvider)) ...[
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'ออกจากระบบ',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
          if (isWide) ...[
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
          ],
          SizedBox(width: isWide ? 16 : 4),
        ],
      ),
      body: !isWide
          ? _mobileBody(filtered, [totalCount, pendingCount, inProgressCount, resolvedCount])
          : _responsiveBody(Row(
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
                      DataColumn(label: Text('ความสำคัญ')),
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
                              child: incident.imageUrls.isEmpty
                                  ? const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Icon(Icons.image_not_supported_rounded, size: 28),
                                    )
                                  : Image.network(
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IncidentUrgencyBadge(urgency: incident.effectivePriority),
                                if (incident.priority == null)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Tooltip(
                                      message: 'ยังไม่ได้กำหนด (ใช้ผลคัดกรองของ AI)',
                                      child: Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.outline),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                  ..._detailChildren(context, _selectedIncidentForManage!),
                ],
              ),
            ),
        ],
      )),
    );
  }

  static int _byPriority(IncidentModel a, IncidentModel b) {
    final p = b.effectivePriority.index.compareTo(a.effectivePriority.index);
    if (p != 0) return p;
    final votes = b.upvoteCount.compareTo(a.upvoteCount);
    if (votes != 0) return votes;
    return a.createdAt.compareTo(b.createdAt);
  }

  static String _waitingFor(DateTime createdAt) {
    final d = DateTime.now().difference(createdAt);
    if (d.inDays >= 1) return '${d.inDays} วัน';
    if (d.inHours >= 1) return '${d.inHours} ชั่วโมง';
    return '${d.inMinutes} นาที';
  }

  Future<void> _setPriority(IncidentModel incident, IncidentUrgency priority) async {
    try {
      await ref.read(incidentRepositoryProvider).adminSetPriority(
            issueId: incident.id,
            priority: priority,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กำหนดลำดับความสำคัญเป็น "${UrgencyStyle.of(priority).label}" แล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกลำดับความสำคัญไม่สำเร็จ: $e')),
      );
    }
  }

  /// ส่วนให้เจ้าหน้าที่ตัดสินลำดับความสำคัญ พร้อมข้อมูลประกอบ
  Widget _prioritySection(BuildContext context, IncidentModel incident) {
    final theme = Theme.of(context);
    final confirmed = incident.priority != null;
    final aiLabel = UrgencyStyle.of(incident.urgency).label;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ลำดับความสำคัญ (เจ้าหน้าที่ตัดสิน)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            confirmed
                ? 'กำหนดแล้ว ใช้ค่านี้จัดลำดับงาน'
                : 'ยังไม่ได้กำหนด ตอนนี้ใช้ผลคัดกรองของ AI ไปก่อน',
            style: theme.textTheme.bodySmall?.copyWith(
              color: confirmed ? AppColors.statusResolved : AppColors.statusPending,
            ),
          ),
          const SizedBox(height: 10),
          UrgencySelector(
            value: incident.effectivePriority,
            onChanged: (p) => _setPriority(incident, p),
          ),
          const SizedBox(height: 12),
          Text('ข้อมูลประกอบการตัดสิน', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text('• AI คัดกรองเบื้องต้น: $aiLabel', style: theme.textTheme.bodySmall),
          Text('• ผู้ร่วมแจ้ง (+1): ${incident.upvoteCount} คน', style: theme.textTheme.bodySmall),
          Text('• รอมาแล้ว: ${_waitingFor(incident.createdAt)}', style: theme.textTheme.bodySmall),
          Text('• หน้างานจริง: ตรวจจากรูปและแผนที่ด้านล่าง', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// เนื้อหารายละเอียดงาน ใช้ทั้งแผงด้านขวา (จอกว้าง) และ bottom sheet (มือถือ)
  List<Widget> _detailChildren(BuildContext context, IncidentModel incident) {
    final theme = Theme.of(context);
    return [
      if (incident.imageUrls.isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            incident.imageUrls.first,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 180,
              child: Center(child: Icon(Icons.broken_image_rounded, size: 48)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      Text(
        incident.title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          IncidentStatusBadge(status: incident.status),
          IncidentUrgencyBadge(urgency: incident.effectivePriority),
        ],
      ),
      const SizedBox(height: 16),
      _prioritySection(context, incident),
      const SizedBox(height: 16),
      const Text('รายละเอียดที่ประชาชนแจ้ง:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(incident.description),
      const SizedBox(height: 16),
      const Text('พิกัดสถานที่:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(incident.locationAddress),
      const SizedBox(height: 8),
      Text('GPS: ${incident.latitude}, ${incident.longitude}', style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      IncidentLocationMap(incident: incident),
      const SizedBox(height: 16),
      IncidentUpdatesSection(
        incidentId: incident.id,
        resolutionImageUrls: incident.resolutionImageUrls,
        editable: true,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => _showFeedbackDialog(incident),
        icon: const Icon(Icons.forum_rounded),
        label: const Text('ส่ง Feedback ถึงผู้แจ้ง'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => _showUpdateStatusDialog(incident),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('เปลี่ยนสถานะ & บันทึกงาน'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ];
  }

  /// มือถือ: รายละเอียดงานแบบ bottom sheet ที่อัปเดตตาม stream
  void _openMobileDetail(IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (sheetContext, scrollController) => Consumer(
          builder: (sheetContext, ref, _) {
            final latest = ref
                .watch(incidentFeedProvider)
                .where((i) => i.id == incident.id)
                .firstOrNull ?? incident;
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: _detailChildren(sheetContext, latest),
            );
          },
        ),
      ),
    );
  }

  /// มือถือ: สถิติ 2×2, ค้นหา/ตัวกรองซ้อนกัน, รายการเป็นการ์ดแทนตาราง
  Widget _mobileBody(List<IncidentModel> filtered, List<int> counts) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _statTile('ทั้งหมด', '${counts[0]}', Icons.folder_open_rounded, AppColors.primary, AppColors.primaryContainer, compact: true),
            _statTile('รอดำเนินการ', '${counts[1]}', Icons.hourglass_top_rounded, AppColors.statusPending, AppColors.statusPendingContainer, compact: true),
            _statTile('กำลังซ่อม', '${counts[2]}', Icons.engineering_rounded, AppColors.statusInProgress, AppColors.statusInProgressContainer, compact: true),
            _statTile('แก้ไขแล้ว', '${counts[3]}', Icons.check_circle_rounded, AppColors.statusResolved, AppColors.statusResolvedContainer, compact: true),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          decoration: InputDecoration(
            hintText: 'ค้นหาหัวข้อ, รายละเอียด, สถานที่...',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<IncidentStatus?>(
                value: _selectedStatusFilter,
                isExpanded: true,
                hint: const Text('ทุกสถานะ'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('สถานะทั้งหมด')),
                  DropdownMenuItem(value: IncidentStatus.pending, child: Text('⏳ รอดำเนินการ')),
                  DropdownMenuItem(value: IncidentStatus.inProgress, child: Text('⚙️ กำลังทำ')),
                  DropdownMenuItem(value: IncidentStatus.resolved, child: Text('✅ แก้ไขแล้ว')),
                ],
                onChanged: (val) => setState(() => _selectedStatusFilter = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<IncidentCategory?>(
                value: _selectedCategoryFilter,
                isExpanded: true,
                hint: const Text('ทุกหมวดหมู่'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ทุกหมวดหมู่')),
                  ...IncidentCategory.values.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCategoryFilter = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('ไม่พบรายการ', style: theme.textTheme.titleMedium)),
          ),
        for (final incident in filtered)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openMobileDetail(incident),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: incident.imageUrls.isEmpty
                            ? const ColoredBox(
                                color: AppColors.surfaceContainerHigh,
                                child: Icon(Icons.image_not_supported_rounded, color: AppColors.outline),
                              )
                            : Image.network(
                                incident.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${incident.categoryLabel} · ${incident.locationAddress}',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IncidentStatusBadge(status: incident.status),
                              const SizedBox(width: 6),
                              IncidentUrgencyBadge(urgency: incident.effectivePriority),
                              const Spacer(),
                              Text('+${incident.upvoteCount} คน', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Dashboard ออกแบบสำหรับจอกว้าง: ถ้าจอแคบกว่า 1100px ให้เลื่อนแนวนอนแทนการล้น
  Widget _responsiveBody(Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 1100.0;
        if (constraints.maxWidth >= minWidth) return content;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: content),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color containerColor) {
    return Expanded(child: _statTile(title, count, icon, color, containerColor));
  }

  Widget _statTile(String title, String count, IconData icon, Color color, Color containerColor,
      {bool compact = false}) {
    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: containerColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 8 : 12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: Colors.white, size: compact ? 20 : 28),
            ),
            SizedBox(width: compact ? 10 : 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: TextStyle(fontSize: compact ? 20 : 26, fontWeight: FontWeight.bold)),
                  Text(
                    title,
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: compact ? 12 : 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

