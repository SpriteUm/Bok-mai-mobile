import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:bok_mai_mobile/data/services/face_blur_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// รูปลายตารางหมากรุก (ช่องละ 4px) เบลอแล้วลายจะหายไปชัดเจน
Uint8List _checkerboard(int w, int h) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final on = ((x ~/ 4) + (y ~/ 4)).isEven;
      image.setPixelRgb(x, y, on ? 255 : 0, on ? 255 : 0, on ? 255 : 0);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// ความต่างของความสว่างระหว่างพิกเซลติดกันในกรอบ (ลายคม = ค่าสูง, เบลอแล้ว = ค่าต่ำ)
double _contrast(img.Image image, int x0, int y0, int w, int h) {
  var sum = 0.0;
  for (var y = y0; y < y0 + h; y++) {
    for (var x = x0; x < x0 + w - 1; x++) {
      sum += (image.getPixel(x, y).r - image.getPixel(x + 1, y).r).abs();
    }
  }
  return sum / (w * h);
}

void main() {
  test('blurRegions ทำให้บริเวณใบหน้าจำไม่ได้ แต่ไม่แตะส่วนอื่นของรูป', () {
    final input = _checkerboard(200, 200);
    final original = img.decodeImage(input)!;

    final out = img.decodeJpg(blurRegions(input, [const Rect.fromLTWH(60, 60, 40, 40)]))!;

    expect(out.width, 200);
    expect(out.height, 200);
    // ในกรอบ (รวม padding) ลายหมากรุกต้องหายไปเกือบหมด
    expect(_contrast(out, 65, 65, 30, 30), lessThan(_contrast(original, 65, 65, 30, 30) * 0.2));
    // มุมรูปที่อยู่นอกกรอบยังคมเหมือนเดิม (JPEG มีเพี้ยนเล็กน้อย)
    expect(_contrast(out, 160, 160, 30, 30), greaterThan(_contrast(original, 160, 160, 30, 30) * 0.6));
  });

  test('ไม่มีใบหน้าก็ยังเข้ารหัสใหม่เป็น JPEG (ตัด metadata ทิ้ง)', () {
    final out = blurRegions(_checkerboard(50, 40), const []);
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 50);
    expect(decoded.height, 40);
  });

  test('กรอบที่ล้นขอบรูปไม่ทำให้พัง', () {
    final out = blurRegions(_checkerboard(80, 80), [const Rect.fromLTWH(60, 60, 50, 50)]);
    expect(img.decodeJpg(out)!.width, 80);
  });
}
