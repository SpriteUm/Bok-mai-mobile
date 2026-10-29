import 'package:latlong2/latlong.dart';

class MapConfig {
  /// Esri WorldStreetMap (เปิดให้ทุก client ใช้ได้ เสถียรกว่า OSM tile server)
  static const tileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  static const userAgentPackageName = 'com.bokmai.bok_mai_mobile';

  /// พิกัดกลางลาดกระบัง ใช้เมื่อหาตำแหน่งปัจจุบันไม่ได้
  static const defaultCenter = LatLng(13.7299, 100.7782);
}
