import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/incident_model.dart';

/// สี ป้ายชื่อ และไอคอนของแต่ละระดับความเร่งด่วน ใช้ร่วมกันทั้งฟอร์มแจ้งและฝั่งแอดมิน
class UrgencyStyle {
  final Color color;
  final Color container;
  final Color onContainer;
  final String label;
  final IconData icon;

  const UrgencyStyle._(this.color, this.container, this.onContainer, this.label, this.icon);

  static UrgencyStyle of(IncidentUrgency urgency) => switch (urgency) {
        IncidentUrgency.low => const UrgencyStyle._(
            AppColors.urgencyLow,
            AppColors.urgencyLowContainer,
            AppColors.urgencyLowOnContainer,
            'ปกติ',
            Icons.check_circle_outline_rounded,
          ),
        IncidentUrgency.medium => const UrgencyStyle._(
            AppColors.urgencyMedium,
            AppColors.urgencyMediumContainer,
            AppColors.urgencyMediumOnContainer,
            'ปานกลาง',
            Icons.error_outline_rounded,
          ),
        IncidentUrgency.high => const UrgencyStyle._(
            AppColors.urgencyHigh,
            AppColors.urgencyHighContainer,
            AppColors.urgencyHighOnContainer,
            'เร่งด่วน',
            Icons.warning_amber_rounded,
          ),
      };
}

class IncidentUrgencyBadge extends StatelessWidget {
  final IncidentUrgency urgency;

  const IncidentUrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final style = UrgencyStyle.of(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.onContainer),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: style.onContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// ตัวเลือกความเร่งด่วน 3 ระดับ แต่ละระดับมีสีของตัวเอง
class UrgencySelector extends StatelessWidget {
  final IncidentUrgency value;
  final ValueChanged<IncidentUrgency> onChanged;

  const UrgencySelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final urgency in IncidentUrgency.values) ...[
          if (urgency != IncidentUrgency.values.first) const SizedBox(width: 8),
          Expanded(child: _option(context, urgency)),
        ],
      ],
    );
  }

  Widget _option(BuildContext context, IncidentUrgency urgency) {
    final style = UrgencyStyle.of(urgency);
    final selected = urgency == value;
    return Material(
      color: selected ? style.color : style.container,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onChanged(urgency),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: style.color, width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : style.icon,
                size: 20,
                color: selected ? Colors.white : style.onContainer,
              ),
              const SizedBox(height: 4),
              Text(
                style.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : style.onContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
