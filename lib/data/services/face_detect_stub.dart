import 'dart:typed_data';
import 'dart:ui' show Rect;

/// นอกเว็บไม่ใช้ (มือถือใช้ ML Kit ใน FaceBlurService)
Future<List<Rect>> detectFacesWeb(Uint8List bytes) =>
    throw UnsupportedError('detectFacesWeb ใช้ได้บนเว็บเท่านั้น');
