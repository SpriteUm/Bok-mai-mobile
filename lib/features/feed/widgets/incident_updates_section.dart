import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_update_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';

String statusLabelTh(IncidentStatus s) => switch (s) {
      IncidentStatus.pending => 'รอดำเนินการ',
      IncidentStatus.inProgress => 'กำลังดำเนินการ',
      IncidentStatus.resolved => 'แก้ไขแล้ว',
    };

/// รายการหมายเหตุ/feedback จากเจ้าหน้าที่ พร้อมชื่อผู้ลงนาม และภาพหลังแก้ไข (After)
/// [editable] = true (ฝั่ง admin) จะแสดงปุ่มแก้ไขเฉพาะรายการที่ตัวเองเขียน
/// ถ้าอ่านไม่ได้ (เช่น ไม่ใช่เจ้าของเรื่อง) และไม่มีภาพ จะไม่แสดงอะไร
class IncidentUpdatesSection extends ConsumerWidget {
  const IncidentUpdatesSection({
    super.key,
    required this.incidentId,
    this.resolutionImageUrls = const [],
    this.editable = false,
  });

  final String incidentId;
  final List<String> resolutionImageUrls;
  final bool editable;

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolutionCard(BuildContext context) {
    return Card(
      color: AppColors.statusResolvedContainer.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt_rounded, size: 16, color: AppColors.statusResolved),
                SizedBox(width: 6),
                Text('ภาพยืนยันผลงานหลังแก้ไข', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final url in resolutionImageUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _viewImage(context, url),
                        borderRadius: BorderRadius.circular(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 140,
                            height: 105,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 140,
                              height: 105,
                              child: Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, IncidentUpdate u) async {
    final controller = TextEditingController(text: u.note);
    final messenger = ScaffoldMessenger.of(context);
    final newNote = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขข้อความ'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 1000,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newNote == null || newNote == u.note) return;
    try {
      await ref
          .read(incidentRepositoryProvider)
          .adminEditUpdate(issueId: incidentId, updateId: u.id, note: newNote);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updates = ref.watch(incidentUpdatesProvider(incidentId)).valueOrNull ?? const [];
    // ข้อความที่ว่างเปล่า (เปลี่ยนสถานะเฉยๆ) ไม่ต้องแสดง
    final items = updates.where((u) => u.note.isNotEmpty).toList();
    if (items.isEmpty && resolutionImageUrls.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = DateFormat('d MMM yyyy, HH:mm น.', 'th');
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ข้อความจากเจ้าหน้าที่', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (resolutionImageUrls.isNotEmpty) _resolutionCard(context),
        for (final u in items)
          Card(
            color: AppColors.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          u.actorName.isEmpty ? 'เจ้าหน้าที่' : u.actorName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (editable && u.actorId == myUid)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'แก้ไขข้อความ',
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => _edit(context, ref, u),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(u.note),
                  const SizedBox(height: 6),
                  Text(
                    '${fmt.format(u.createdAt)} · สถานะ: ${statusLabelTh(u.status)}'
                    '${u.editedAt != null ? ' · แก้ไขแล้ว' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
