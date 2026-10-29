import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_status_badge.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_updates_section.dart';

class IncidentDetailScreen extends StatefulWidget {
  final IncidentModel incident;

  const IncidentDetailScreen({super.key, required this.incident});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  int _userRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('ประเมินความพึงพอใจการแก้ไข'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ให้คะแนนผลงานของเจ้าหน้าที่เทศบาล'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= _userRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _userRating = starIndex;
                        });
                        setState(() {});
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ข้อเสนอแนะเพิ่มเติม (AI ช่วยวิเคราะห์ Sentiment)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('บันทึกผลการประเมินเรียบร้อย ขอบคุณครับ'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.statusResolved,
                    ),
                  );
                },
                child: const Text('ส่งคะแนน'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reopenTicket() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ขอเปิดเรื่องแจ้งซ้ำ (Re-open)'),
        content: const Text(
          'คุณตรวจสอบแล้วพบว่าปัญหายังไม่ได้รับการแก้ไขจริงใช่หรือไม่? ระบบจะส่งเรื่องกลับไปยังสถานะกำลังดำเนินการพร้อมแจ้งเตือนหัวหน้าช่าง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ส่งคำร้อง Re-open สำเร็จ กำลังส่งทีมตรวจสอบซ้ำ'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('ยืนยันส่งเรื่องซ้ำ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incident = widget.incident;
    final timeFormat = DateFormat('d MMMM yyyy, HH:mm น.', 'th');

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดปัญหา'),
      ),
      body: ListView(
        children: [
          // Large Hero Image
          Container(
            height: 240,
            width: double.infinity,
            color: AppColors.surfaceContainerHigh,
            child: incident.imageUrls.isNotEmpty
                ? Image.network(
                    incident.imageUrls.first,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported_rounded, size: 64),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(incident.categoryLabel),
                      backgroundColor: AppColors.primaryContainer,
                      labelStyle: const TextStyle(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IncidentStatusBadge(status: incident.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  incident.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Time & Reporter info
                Text(
                  'แจ้งเมื่อ: ${timeFormat.format(incident.createdAt)} (ไม่ระบุตัวตนตาม PDPA)',
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 24),

                // Description
                Text('รายละเอียดปัญหา', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  incident.description,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),

                // Location info
                Card(
                  color: AppColors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                    title: const Text('พิกัดจุดเกิดเหตุ'),
                    subtitle: Text(incident.locationAddress),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('ดูบนแผนที่'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // หมายเหตุ/feedback จากเจ้าหน้าที่ (เห็นเฉพาะเจ้าของเรื่อง)
                IncidentUpdatesSection(
                  incidentId: incident.id,
                  resolutionImageUrls: incident.resolutionImageUrls,
                ),
                const SizedBox(height: 8),

                // Lifecycle Timeline (State Machine)
                Text('ไทม์ไลน์ความคืบหน้า (Status Lifecycle)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                _buildTimelineStep(
                  title: '1. ประชาชนแจ้งปัญหาเข้าระบบ',
                  time: timeFormat.format(incident.createdAt),
                  subtitle: 'ระบบ AI ตรวจสอบพิกัดและบันทึกข้อมูลเรียบร้อย',
                  isCompleted: true,
                  isCurrent: incident.status == IncidentStatus.pending,
                ),
                _buildTimelineStep(
                  title: '2. เทศบาลรับเรื่อง & มอบหมายทีมช่าง',
                  time: incident.status != IncidentStatus.pending
                      ? 'เจ้าหน้าที่ฝ่ายช่างกำลังลงพื้นที่'
                      : 'รอดำเนินการจัดสรรเจ้าหน้าที่',
                  subtitle: 'เจ้าหน้าที่ผู้รับผิดชอบ: หน่วยบำรุงรักษาเทศบาล',
                  isCompleted: incident.status == IncidentStatus.inProgress ||
                      incident.status == IncidentStatus.resolved,
                  isCurrent: incident.status == IncidentStatus.inProgress,
                ),
                _buildTimelineStep(
                  title: '3. ดำเนินการแก้ไขแล้วเสร็จ',
                  time: incident.status == IncidentStatus.resolved
                      ? 'แก้ไขเสร็จสิ้น พร้อมภาพถ่ายยืนยัน'
                      : 'รอทีมช่างส่งมอบงาน',
                  subtitle: incident.status == IncidentStatus.resolved
                      ? 'ได้รับการตรวจรับงานจากหัวหน้าส่วนแล้ว'
                      : null,
                  isCompleted: incident.status == IncidentStatus.resolved,
                  isCurrent: incident.status == IncidentStatus.resolved,
                  isLast: true,
                ),

                const SizedBox(height: 24),

                // Post-resolution action buttons
                if (incident.status == IncidentStatus.resolved) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reopenTicket,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('ยังไม่เสร็จจริง (Re-open)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showFeedbackDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.star_rounded),
                          label: const Text('ให้คะแนน'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    String? subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isCurrent ? AppColors.primary : AppColors.statusResolved)
                      : AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.circle,
                  size: 14,
                  color: isCompleted ? Colors.white : AppColors.outline,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? AppColors.statusResolved
                        : AppColors.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isCompleted ? AppColors.onSurface : AppColors.outline,
                    ),
                  ),
                  Text(time, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

