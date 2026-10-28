import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/incident_model.dart';
import 'incident_status_badge.dart';

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onUpvote;
  final VoidCallback onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Photo Preview with Category and Status Badges
            Stack(
              children: [
                Container(
                  height: 190,
                  width: double.infinity,
                  color: AppColors.surfaceContainerHigh,
                  child: incident.imageUrls.isNotEmpty
                      ? Image.network(
                          incident.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: AppColors.outline,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: AppColors.outline,
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      incident.categoryLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IncidentStatusBadge(status: incident.status),
                ),
              ],
            ),

            // Card Body (Title, Description, Location)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    incident.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Location Pin Row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.locationAddress,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Action Row: +1 Follow ticket & People Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: AppColors.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ผู้ร่วมแจ้ง ${incident.upvoteCount} คน',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onUpvote,
                        style: FilledButton.styleFrom(
                          backgroundColor: incident.hasUpvoted
                              ? AppColors.primary
                              : AppColors.primaryContainer,
                          foregroundColor: incident.hasUpvoted
                              ? AppColors.onPrimary
                              : AppColors.onPrimaryContainer,
                          minimumSize: const Size(48, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        icon: Icon(
                          incident.hasUpvoted
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 16,
                        ),
                        label: Text(
                          incident.hasUpvoted ? 'ติดตามแล้ว' : '+1 ติดตาม',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

