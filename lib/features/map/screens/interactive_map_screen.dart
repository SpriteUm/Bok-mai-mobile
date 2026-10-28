import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_status_badge.dart';

class InteractiveMapScreen extends ConsumerStatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  final MapController _mapController = MapController();
  IncidentModel? _selectedIncident;

  // Initial Center: KMITL Ladkrabang area
  static const LatLng _initialCenter = LatLng(13.7299, 100.7782);

  Color _getStatusMarkerColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return AppColors.statusPending;
      case IncidentStatus.inProgress:
        return AppColors.statusInProgress;
      case IncidentStatus.resolved:
        return AppColors.statusResolved;
    }
  }

  IconData _getCategoryIcon(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.electricity:
        return Icons.bolt_rounded;
      case IncidentCategory.water:
        return Icons.water_drop_rounded;
      case IncidentCategory.road:
        return Icons.add_road_rounded;
      case IncidentCategory.waste:
        return Icons.delete_outline_rounded;
      case IncidentCategory.drainage:
        return Icons.waves_rounded;
      case IncidentCategory.other:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่รวมจุดเกิดเหตุ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'กลับไปจุดเริ่มต้น',
            onPressed: () {
              _mapController.move(_initialCenter, 15.0);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Public Tile Server (Esri WorldStreetMap - Highly reliable & open for all clients)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (_, __) {
                if (_selectedIncident != null) {
                  setState(() {
                    _selectedIncident = null;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.bokmai.bok_mai_mobile',
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Tile error at zoom ${tile.coordinates.z}: $error');
                },
              ),
              MarkerLayer(
                markers: incidents.map((incident) {
                  final markerColor = _getStatusMarkerColor(incident.status);
                  final isSelected = _selectedIncident?.id == incident.id;

                  return Marker(
                    point: LatLng(incident.latitude, incident.longitude),
                    width: isSelected ? 54 : 44,
                    height: isSelected ? 54 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIncident = incident;
                        });
                        _mapController.move(
                          LatLng(incident.latitude, incident.longitude),
                          _mapController.camera.zoom,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3.5 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(incident.category),
                          color: Colors.white,
                          size: isSelected ? 28 : 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Map Legend / Indicator at Top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: Colors.white.withValues(alpha: 0.95),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('รอดำเนินการ', AppColors.statusPending),
                    _buildLegendItem('กำลังทำ', AppColors.statusInProgress),
                    _buildLegendItem('แก้ไขแล้ว', AppColors.statusResolved),
                  ],
                ),
              ),
            ),
          ),

          // Selected Incident Summary Card at Bottom
          if (_selectedIncident != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedIncident!.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedIncident = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedIncident!.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IncidentStatusBadge(status: _selectedIncident!.status),
                          Text(
                            'ผู้ร่วมแจ้ง ${_selectedIncident!.upvoteCount} คน',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
