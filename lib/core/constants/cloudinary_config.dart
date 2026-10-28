/// ค่าของ Cloudinary สำหรับอัปโหลดรูปแบบ unsigned (ไม่ใช่ความลับ ห้ามใส่ API Secret ในแอป)
///
/// ตั้งค่าได้ 2 ทาง:
///  1) แก้ค่า defaultValue ด้านล่าง
///  2) ส่งตอนรัน: flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
class CloudinaryConfig {
  static const cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  static const uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  static bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
