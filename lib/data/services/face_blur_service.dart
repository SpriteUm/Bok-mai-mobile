import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class FaceBlurResult {
  const FaceBlurResult(this.bytes, this.faceCount);

  /// รูป JPEG ที่เบลอแล้ว (หมุนตั้งตรงและตัด metadata เช่นพิกัด GPS ในรูปออกแล้ว)
  final Uint8List bytes;
  final int faceCount;
}

/// เบลอใบหน้าคนในรูปก่อนอัปโหลด (PDPA)
///
/// ตรวจจับใบหน้าด้วย ML Kit บนเครื่อง (ไม่ส่งรูปออกไปไหน) ใช้ได้เฉพาะ Android/iOS
class FaceBlurService {
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<FaceBlurResult> blurFaces(XFile file) async {
    if (!isSupported) {
      throw UnsupportedError('เบลอใบหน้าอัตโนมัติใช้ได้เฉพาะแอปมือถือ');
    }
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        // ค่าเริ่มต้น 0.1 จะพลาดใบหน้าเล็กๆ ที่พบบ่อยในรูปถนน
        minFaceSize: 0.03,
      ),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(file.path));
      final bytes = await file.readAsBytes();
      final boxes = [for (final f in faces) f.boundingBox];
      return FaceBlurResult(blurRegions(bytes, boxes), faces.length);
    } finally {
      await detector.close();
    }
  }
}

/// ทำให้บริเวณ [regions] จำไม่ได้ (pixelate แล้วเบลอซ้ำ) แล้วคืนเป็น JPEG
///
/// ขยายกรอบออก [padding] รอบด้านให้คลุมผมและคาง พิกัดอิงรูปที่หมุนตั้งตรงแล้ว
/// (ML Kit คืนกรอบตามรูปตั้งตรง จึงต้อง bakeOrientation ก่อนให้ตรงกัน)
Uint8List blurRegions(Uint8List bytes, List<Rect> regions, {double padding = 0.3}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('อ่านไฟล์รูปไม่ได้');
  final image = img.bakeOrientation(decoded);

  for (final r in regions) {
    final padX = r.width * padding;
    final padY = r.height * padding;
    final left = math.max(0, (r.left - padX).floor());
    final top = math.max(0, (r.top - padY).floor());
    final right = math.min(image.width, (r.right + padX).ceil());
    final bottom = math.min(image.height, (r.bottom + padY).ceil());
    final w = right - left;
    final h = bottom - top;
    if (w <= 0 || h <= 0) continue;

    var patch = img.copyCrop(image, x: left, y: top, width: w, height: h);
    patch = img.pixelate(patch, size: math.max(8, math.max(w, h) ~/ 6));
    patch = img.gaussianBlur(patch, radius: math.max(4, math.max(w, h) ~/ 12));
    img.compositeImage(image, patch, dstX: left, dstY: top);
  }
  // เข้ารหัสใหม่เสมอ: ตัด EXIF (รวมพิกัด GPS ในรูป) ออกไปด้วย
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}
