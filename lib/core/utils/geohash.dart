const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// geohash ความยาว [precision] ตัวอักษร (9 ตัว ~ 5 เมตร) ไว้ใช้ค้นปัญหาแบบรัศมี
String encodeGeohash(double latitude, double longitude, {int precision = 9}) {
  var latMin = -90.0, latMax = 90.0;
  var lonMin = -180.0, lonMax = 180.0;
  final out = StringBuffer();
  var isLon = true;
  var bit = 0;
  var ch = 0;

  while (out.length < precision) {
    if (isLon) {
      final mid = (lonMin + lonMax) / 2;
      if (longitude >= mid) {
        ch = (ch << 1) | 1;
        lonMin = mid;
      } else {
        ch = ch << 1;
        lonMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        ch = (ch << 1) | 1;
        latMin = mid;
      } else {
        ch = ch << 1;
        latMax = mid;
      }
    }
    isLon = !isLon;
    if (++bit == 5) {
      out.write(_base32[ch]);
      bit = 0;
      ch = 0;
    }
  }
  return out.toString();
}
