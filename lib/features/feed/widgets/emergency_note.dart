import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// แถบเบอร์ฉุกเฉินเล็กๆ สีอ่อน ให้เห็นได้แต่ไม่แย่งความสนใจจากฟีด
class EmergencyNote extends StatelessWidget {
  const EmergencyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.urgencyHighOnContainer,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.urgencyHighContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, size: 14, color: AppColors.urgencyHighOnContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'เหตุฉุกเฉิน: 191 ตำรวจ · 199 ดับเพลิง · 1669 เจ็บป่วย · 1130 ไฟฟ้า · 1555 กทม.',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
