import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bok_mai_mobile/core/constants/map_config.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/widgets/incident_urgency_badge.dart';

/// พิกัด (0,0) หมายถึงรายงานที่ไม่มี GPS
bool _hasLocation(IncidentModel incident) => incident.latitude != 0 || incident.longitude != 0;

/// เปิด Google Street View ตรงพิกัด (ดูภาพถนนจริงรอบจุดเกิดเหตุ ฟรี ไม่ต้องใช้ API key)
/// ถ้าจุดนั้นไม่มีภาพ Street View Google จะพาไปภาพที่ใกล้ที่สุด
Uri streetViewUri(IncidentModel i) => Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${i.latitude},${i.longitude}',
    );

/// เปิดตำแหน่งใน Google Maps (ใช้นำทางไปหน้างานได้)
Uri googleMapsUri(IncidentModel i) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${i.latitude},${i.longitude}',
    );

Future<void> _open(BuildContext context, Uri uri) async {
  String? error;
  try {
    // เว็บ: เปิดแท็บใหม่ / มือถือ: เปิดแอป Google Maps หรือเบราว์เซอร์
    final ok = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok) error = 'เปิดลิงก์ไม่สำเร็จ';
  } catch (e) {
    // เช่น MissingPluginException เมื่อเพิ่มปลั๊กอินแล้วแต่ยังไม่ได้ build แอปใหม่
    debugPrint('เปิดลิงก์ไม่สำเร็จ: $e');
    error = 'เปิดลิงก์ไม่สำเร็จ (ถ้าเพิ่งอัปเดตแอป ให้ปิดแล้วรันแอปใหม่ทั้งหมด)';
  }
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// ปุ่มดูหน้างานจริง: Street View และ Google Maps
class _ExternalMapButtons extends StatelessWidget {
  const _ExternalMapButtons({required this.incident});

  final IncidentModel incident;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, streetViewUri(incident)),
            icon: const Icon(Icons.streetview_rounded),
            label: const Text('Street View'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, googleMapsUri(incident)),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Google Maps'),
          ),
        ),
      ],
    );
  }
}

/// แผนที่ย่อสถานที่เกิดเหตุในแผงรายละเอียดของแอดมิน กดเพื่อเปิดเต็มจอ
class IncidentLocationMap extends StatelessWidget {
  final IncidentModel incident;

  const IncidentLocationMap({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation(incident)) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Text('รายงานนี้ไม่มีพิกัด GPS'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                _IncidentMap(incident: incident, interactive: false, zoom: 16),
                // ชั้นโปร่งใสรับการแตะแทนแผนที่ เพื่อไม่ให้แย่งการเลื่อนของแผงรายละเอียด
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: () => openFullScreen(context, incident)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => openFullScreen(context, incident),
          icon: const Icon(Icons.map_rounded),
          label: const Text('เปิดแผนที่สถานที่เกิดเหตุ'),
        ),
        const SizedBox(height: 8),
        _ExternalMapButtons(incident: incident),
      ],
    );
  }

  static void openFullScreen(BuildContext context, IncidentModel incident) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(incident.title, overflow: TextOverflow.ellipsis)),
          body: Stack(
            children: [
              _IncidentMap(incident: incident, interactive: true, zoom: 17),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                            title: Text(
                              incident.locationAddress.isEmpty ? 'ไม่ระบุที่อยู่' : incident.locationAddress,
                            ),
                            subtitle: Text(
                              'GPS: ${incident.latitude.toStringAsFixed(6)}, ${incident.longitude.toStringAsFixed(6)}',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ExternalMapButtons(incident: incident),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentMap extends StatelessWidget {
  final IncidentModel incident;
  final bool interactive;
  final double zoom;

  const _IncidentMap({required this.incident, required this.interactive, required this.zoom});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(incident.latitude, incident.longitude);
    final color = UrgencyStyle.of(incident.urgency).color;
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: MapConfig.userAgentPackageName,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
              child: Icon(Icons.location_on_rounded, size: 44, color: color),
            ),
          ],
        ),
      ],
    );
  }
}
