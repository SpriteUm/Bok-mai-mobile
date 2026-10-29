import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_item.dart';
import 'package:bok_mai_mobile/data/outbox/outbox_provider.dart';

/// รายงานที่รอส่ง (บันทึกไว้ตอนไม่มีเน็ต) แสดงบนหน้าประวัติ พร้อมปุ่มส่งตอนนี้
class OutboxPanel extends ConsumerStatefulWidget {
  const OutboxPanel({super.key});

  @override
  ConsumerState<OutboxPanel> createState() => _OutboxPanelState();
}

class _OutboxPanelState extends ConsumerState<OutboxPanel> {
  bool _sending = false;

  Future<void> _sendNow() async {
    setState(() => _sending = true);
    final sent = await ref.read(outboxProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent > 0
              ? 'ส่งรายงานแล้ว $sent เรื่อง'
              : 'ยังส่งไม่ได้ โปรดตรวจการเชื่อมต่ออินเทอร์เน็ต',
        ),
      ),
    );
  }

  Future<void> _remove(OutboxItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายงานที่รอส่ง?'),
        content: Text('"${item.report.title}" จะไม่ถูกส่ง'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(outboxProvider.notifier).remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(outboxProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final time = DateFormat('d MMM HH:mm น.', 'th');
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppColors.statusPendingContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.statusPendingOnContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'รอส่ง ${items.length} เรื่อง (จะส่งเองเมื่อมีอินเทอร์เน็ต)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.statusPendingOnContainer,
                    ),
                  ),
                ),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: _sendNow,
                        child: const Text('ส่งตอนนี้'),
                      ),
              ],
            ),
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32),
                title: Text(
                  item.report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'บันทึกเมื่อ ${time.format(item.createdAt)}'
                  '${item.images.isEmpty ? '' : ' · รูป ${item.images.length} รูป'}',
                ),
                trailing: IconButton(
                  tooltip: 'ลบ ไม่ส่งเรื่องนี้',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _remove(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
