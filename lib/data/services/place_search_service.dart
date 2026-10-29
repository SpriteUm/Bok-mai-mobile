import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:bok_mai_mobile/core/constants/map_config.dart';

class PlaceResult {
  const PlaceResult({required this.name, required this.address, required this.point});

  final String name;
  final String address;
  final LatLng point;
}

/// ค้นหาสถานที่ด้วย Nominatim (OpenStreetMap) ฟรี ไม่ต้องใช้ API key
/// ตามนโยบายการใช้งาน: ค้นหาเมื่อผู้ใช้กดค้นหาเท่านั้น (ห้ามยิงทุกตัวอักษรแบบ autocomplete)
class PlaceSearchService {
  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// แปลงพิกัดเป็นที่อยู่ภาษาไทย เช่น "บ้านพฤกษา 70 แขวงลำปลาทิว เขตลาดกระบัง กรุงเทพมหานคร"
  /// คืน null ถ้าหาไม่เจอหรือเรียกไม่สำเร็จ
  Future<String?> reverse(LatLng point) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${point.latitude}',
      'lon': '${point.longitude}',
      'format': 'jsonv2',
      'zoom': '18',
      'accept-language': 'th',
    });
    try {
      final headers = kIsWeb ? null : {'User-Agent': MapConfig.userAgentPackageName};
      final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final name = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['display_name'] as String?;
      if (name == null) return null;
      // ตัดรหัสไปรษณีย์และชื่อประเทศท้ายที่อยู่ออก
      final parts = name
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty && p != 'ประเทศไทย' && int.tryParse(p) == null);
      return parts.join(' ');
    } catch (_) {
      return null;
    }
  }

  /// [near] ใช้จัดลำดับให้ผลลัพธ์ใกล้จุดนี้ขึ้นก่อน (ไม่ตัดผลที่อยู่ไกลทิ้ง)
  Future<List<PlaceResult>> search(String query, {LatLng? near}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final params = {
      'q': q,
      'format': 'jsonv2',
      'limit': '8',
      'countrycodes': 'th',
      'accept-language': 'th',
      if (near != null)
        'viewbox': [
          near.longitude - 0.3,
          near.latitude + 0.3,
          near.longitude + 0.3,
          near.latitude - 0.3,
        ].join(','),
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    // เบราว์เซอร์ไม่ให้ตั้ง User-Agent เอง จึงตั้งเฉพาะบนมือถือ
    final headers = kIsWeb ? null : {'User-Agent': MapConfig.userAgentPackageName};

    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('ค้นหาสถานที่ไม่สำเร็จ (${res.statusCode})');
    }

    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return [
      for (final e in list.cast<Map<String, dynamic>>())
        PlaceResult(
          name: (e['name'] as String?)?.isNotEmpty == true
              ? e['name'] as String
              : (e['display_name'] as String).split(',').first,
          address: e['display_name'] as String? ?? '',
          point: LatLng(double.parse(e['lat'] as String), double.parse(e['lon'] as String)),
        ),
    ];
  }
}
