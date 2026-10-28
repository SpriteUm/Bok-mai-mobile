import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bok_mai_mobile/core/constants/cloudinary_config.dart';

class ImageUploadException implements Exception {
  ImageUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// อัปโหลดรูปไป Cloudinary (unsigned upload) แล้วคืนลิงก์ https สำหรับเก็บใน Firestore
class ImageUploadService {
  Future<String> upload(XFile file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw ImageUploadException('ยังไม่ได้ตั้งค่า Cloudinary (cloud name / upload preset)');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: file.name,
        ),
      );

    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 60)),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final message = (body['error'] as Map?)?['message'] ?? 'HTTP ${response.statusCode}';
      throw ImageUploadException('อัปโหลดรูปไม่สำเร็จ: $message');
    }
    return body['secure_url'] as String;
  }

  Future<List<String>> uploadAll(Iterable<XFile> files) =>
      Future.wait(files.map(upload));
}
