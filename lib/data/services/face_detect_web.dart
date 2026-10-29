import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' show Rect;

/// กำหนดใน web/index.html (MediaPipe Face Detector ในเบราว์เซอร์)
@JS('bokMaiDetectFaces')
external JSPromise<JSString> _detectFaces(JSUint8Array bytes);

/// ตรวจจับใบหน้าบนเว็บ คืนกรอบตามรูปที่หมุนตั้งตรงแล้ว
Future<List<Rect>> detectFacesWeb(Uint8List bytes) async {
  final json = (await _detectFaces(bytes.toJS).toDart).toDart;
  return [
    for (final b in (jsonDecode(json) as List).cast<List>())
      Rect.fromLTWH(
        (b[0] as num).toDouble(),
        (b[1] as num).toDouble(),
        (b[2] as num).toDouble(),
        (b[3] as num).toDouble(),
      ),
  ];
}
