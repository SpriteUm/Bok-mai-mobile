import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/incident_model.dart';

class IncidentStatusBadge extends StatelessWidget {
  final IncidentStatus status;

  const IncidentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case IncidentStatus.pending:
        bg = AppColors.statusPendingContainer;
        fg = AppColors.statusPendingOnContainer;
        label = 'รอดำเนินการ';
        icon = Icons.hourglass_top_rounded;
        break;
      case IncidentStatus.inProgress:
        bg = AppColors.statusInProgressContainer;
        fg = AppColors.statusInProgressOnContainer;
        label = 'กำลังดำเนินการ';
        icon = Icons.engineering_rounded;
        break;
      case IncidentStatus.resolved:
        bg = AppColors.statusResolvedContainer;
        fg = AppColors.statusResolvedOnContainer;
        label = 'แก้ไขแล้ว';
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

