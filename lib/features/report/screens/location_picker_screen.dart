import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bok_mai_mobile/core/constants/map_config.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/data/services/place_search_service.dart';

/// เลือกพิกัดเอง: เลื่อนแผนที่ให้หมุดกลางจอตรงจุดเกิดเหตุ หรือแตะบนแผนที่ แล้วกดยืนยัน
/// คืนค่า [LatLng] ที่เลือก (หรือ null ถ้ายกเลิก)
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initial, this.onLocateMe});

  final LatLng initial;

  /// ดึงพิกัดปัจจุบันจาก GPS (null = ไม่แสดงปุ่ม)
  final Future<LatLng?> Function()? onLocateMe;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _placeSearch = PlaceSearchService();
  late LatLng _center = widget.initial;
  bool _locating = false;
  bool _searching = false;
  List<PlaceResult>? _results;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final results = await _placeSearch.search(query, near: _center);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ค้นหาสถานที่ไม่สำเร็จ โปรดตรวจสอบอินเทอร์เน็ตแล้วลองใหม่')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goTo(PlaceResult place) {
    setState(() => _results = null);
    _mapController.move(place.point, 17);
  }

  Widget _searchPanel(BuildContext context) {
    final results = _results;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'ค้นหาสถานที่ เช่น สจล., ถนนฉลองกรุง, ลาดกระบัง',
              prefixIcon: const Icon(Icons.search_rounded),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      tooltip: 'ค้นหา',
                      onPressed: _search,
                    ),
            ),
          ),
          if (results != null) ...[
            const Divider(height: 1),
            if (results.isEmpty)
              const ListTile(title: Text('ไม่พบสถานที่ ลองใช้คำอื่นหรือเลื่อนแผนที่หาเอง'))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(results[i].name),
                    subtitle: Text(results[i].address, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _goTo(results[i]),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final point = await widget.onLocateMe!();
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('หาตำแหน่งปัจจุบันไม่ได้ โปรดเปิด GPS และอนุญาตสิทธิ์ตำแหน่ง')),
      );
      return;
    }
    _mapController.move(point, 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตำแหน่งที่เกิดเหตุ')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: 17,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) => setState(() => _center = camera.center),
              onTap: (_, point) => _mapController.move(point, _mapController.camera.zoom),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
              ),
            ],
          ),
          // หมุดกลางจอ (ปลายหมุดชี้ที่จุดกึ่งกลางพอดี)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.location_on_rounded, size: 48, color: AppColors.error),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: widget.onLocateMe != null ? 72 : 16,
            top: 12,
            child: _searchPanel(context),
          ),
          if (widget.onLocateMe != null)
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: 'ไปยังตำแหน่งปัจจุบัน',
                onPressed: _locating ? null : _locateMe,
                child: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('เลื่อนแผนที่หรือแตะเพื่อวางหมุดตรงจุดเกิดเหตุ'),
                      const SizedBox(height: 4),
                      Text(
                        'GPS: ${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, _center),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('ใช้ตำแหน่งนี้'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
